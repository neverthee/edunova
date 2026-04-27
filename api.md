# 统一到阿里云百炼的低成本多模态 API 方案

## Summary
- 供应商选型固定为 **阿里云百炼（DashScope，中国内地北京地域）**，原因是它能用 **一家厂商** 覆盖现有项目所需的 `LLM + Embedding + ASR + OCR + 可选VLM`，且现有代码已经大量使用 OpenAI 兼容接口，迁移成本最低。
- v1 只启用 **4 个模型能力**：
  - 文本生成：`qwen3.5-flash`，固定 `enable_thinking=false`
  - 向量化：`text-embedding-v4`，固定 `dimensions=1024`
  - 语音转写：`fun-asr-realtime`
  - OCR：`qwen-vl-ocr`
- **v1 不启用视频语义理解 VLM**。视频关键帧采用“本地抽帧 + transcript 驱动选帧 + OCR”的方案，避免再加一个远程能力。只有 v2 才允许补 `qwen3-vl-flash`。
- 成本默认按中国内地官方计费估算：
  - `qwen3.5-flash`：输入约 `0.2元/M token`，输出约 `2元/M token`
  - `text-embedding-v4`：约 `0.5元/M token`
  - `qwen-vl-ocr`：输入约 `0.3元/M token`，输出约 `0.5元/M token`
  - `fun-asr-realtime`：约 `0.00033元/秒`
- 5 分钟视频的 v1 目标成本：
  - ASR：约 `0.099元`
  - 摘要/分段：约 `0.002-0.02元`
  - 5 张关键帧 OCR：约 `0.01-0.03元`
  - 合计目标：**约 0.11-0.15 元 / 5 分钟视频**

## Public API / Internal API Changes
- 保留现有 `POST /api/rag/knowledge/upload-temp`，但扩展支持：
  - `.ppt/.pptx`
  - `.jpg/.jpeg/.png/.webp`
  - `.mp4/.mov/.avi/.mkv/.webm`
- 新增 `POST /api/rag/transcribe-audio`
  - 用途：浏览器录音后的“上传即转写”
  - 输入：`multipart/form-data`
    - `file`
    - `source_kind`: `mic | video`
    - `language_hints`: 可选，默认 `["zh","en"]`
  - 输出：
    - `text`
    - `segments[]`: `{start_ms,end_ms,text}`
    - `duration_ms`
    - `provider`: 固定 `dashscope`
    - `model`: 固定 `fun-asr-realtime`
- 新增 `POST /api/rag/process-temp-sources`
  - 用途：统一处理上传后的参考资料，不再拆 PDF/Word/PPT/图片/视频多个端点
  - 输入：
    - `file_paths[]`
    - `source_mappings[]`: `{file_path,usage,knowledge_point,is_required}`
  - 输出：
    - `sources[]`
    - 每个 source 固定返回：
      - `kind`: `document | ppt | image | video`
      - `mapping`
      - `raw_text`
      - `chunks[]`
      - `summary`
      - `assets`
    - `assets` 规则：
      - PPT：`slides[]`
      - 图片：`ocr_text`
      - 视频：`transcript`、`segments[]`、`keyframes[]`
- 新增 `POST /api/rag/generate-lesson-spec`
  - 用途：把“教师需求 + 对话摘要 + 参考资料片段 + 本地知识库召回”统一生成结构化课件指令
  - 输入：
    - 现有 LessonPlanner 表单字段
    - `clarified_requirement`
    - `processed_sources`
    - `useKnowledgeBase`
    - `revision_request`: 可选，若有则在旧 spec 基础上改写
    - `previous_spec`: 可选
  - 输出：
    - `lesson_spec`
  - `lesson_spec` 固定结构：
    - `requirement_summary`
    - `knowledge_points[]`
    - `teaching_flow[]`
    - `ppt_outline`
    - `docx_outline`
    - `game_plan`
    - `source_citations[]`
- 新增 `POST /api/rag/export-lesson-assets`
  - 用途：从同一个 `lesson_spec` 导出产物，避免 PPT/DOCX 分成多个端点
  - 输入：
    - `lesson_spec`
    - `targets[]`: `pptx | docx | game_html`
  - 输出：
    - `assets[]`: `{type,material_id,file_path,download_url}`

## Implementation Changes
### 1. 供应商迁移与模型适配
- 把现有 `LLM_API_BASE` 统一切到 `https://dashscope.aliyuncs.com/compatible-mode/v1`，文本生成和 embeddings 继续沿用 OpenAI SDK 调用方式。
- 不重命名现有配置读取逻辑，直接兼容：
  - `LLM_API_KEY` 填百炼 Key
  - `LLM_API_BASE` 填 DashScope compatible-mode URL
  - `LLM_MODEL` 固定为 `qwen3.5-flash`
- 新增独立 ASR/OCR 适配层：
  - ASR 使用 DashScope Python SDK，不走 OpenAI SDK
  - OCR 继续走 OpenAI-compatible chat completions
- Embedding 明确切换到 `text-embedding-v4`，维度固定 1024，保证与现有向量库代码最接近。

### 2. 语音输入实现
- 前端不做浏览器 `SpeechRecognition` 正式接入，只做“录音 -> 上传 -> 转写 -> 回填”。
- 录音模式固定为“停止录音后一次性上传”，不做实时流式字幕。
- 后端 `/transcribe-audio` 实现：
  - 校验格式
  - 用 ffmpeg 统一转为 `wav/16kHz/mono`
  - 调用 `fun-asr-realtime`
  - 返回整段文本和时间片段
- LessonPlanner 新增“语音填入教学思路”按钮，点击后把转写结果填入“教学思路自由描述”字段。

### 3. 参考资料解析实现
- 文档类：
  - PDF/Word/TXT/MD 继续用现有加载逻辑
  - PPT/PPTX 使用 `python-pptx` 提取每页 `title + bullets + notes + image refs`
- 图片类：
  - 一律走 `qwen-vl-ocr`
  - Prompt 固定要求输出 JSON：`raw_text`、`layout_blocks[]`、`summary`、`tags[]`
- 视频类：
  - 上传后本地保存视频
  - ffmpeg 抽音频
  - 复用 `/transcribe-audio` 内部逻辑得到 transcript
  - 调用 `qwen3.5-flash` 把 transcript 变成 `segments[]`，每段包含：
    - `start_ms`
    - `end_ms`
    - `summary`
    - `importance_score`
  - 按 `importance_score` 选取前 `3-5` 段，在每段中点用 ffmpeg 截 `1` 张关键帧
  - 对关键帧调用 `qwen-vl-ocr`
  - 最终返回 `transcript + segments + keyframes`
- 明确不做：
  - 全视频逐帧远程理解
  - 全量关键帧 VLM 描述
  - 图片通用视觉理解
- 这样 v1 视频链路只增加两种远程能力：ASR 和 OCR；关键帧选取靠 transcript 与本地抽帧完成。

### 4. 课件生成与导出实现
- `generate-lesson-spec` 是唯一的结构化生成入口。
- `qwen3.5-flash` 只做一件事：输出结构化 `lesson_spec`，不直接输出 Markdown/PPT 文案混合结果。
- `lesson_spec` 用于三类本地渲染：
  - PPT：`python-pptx`
  - DOCX：`python-docx`
  - 小游戏：已有 quiz/game 页面读取 `game_plan`
- 小游戏不新增外部 API：
  - 复用现有 `student_quiz` 生成与评分
  - 只扩展 `gameMode/stages/scoreRule/finalSummary`
  - `game_plan` 由 `qwen3.5-flash` 在同一次 `lesson_spec` 生成中顺带产出

### 5. 课件修改再生
- 不新增独立“再生成模型”，继续使用 `qwen3.5-flash`。
- `generate-lesson-spec` 支持 `previous_spec + revision_request` 作为增量修改输入。
- 修改规则固定：
  - 若传 `previous_spec`，优先在旧 spec 上改写
  - 不重新解析未变化的参考资料
  - 不重新 OCR / ASR，除非源文件变更
- 这样“调整顺序/简化某页/增加案例”只增加一次便宜文本调用，不重复跑多媒体链路。

## Test Plan
1. 语音输入
- 录制 30 秒普通话音频，确认可回填到教学思路文本框
- 录制带英文术语音频，检查 `language_hints` 生效
- 上传不支持格式，返回明确错误

2. 图片 OCR
- 上传文字密集截图，返回 `raw_text + summary + tags`
- 上传纯图片无文字，返回空 `raw_text` 但不报错
- 中文/英文混排图像输出结构稳定

3. 视频处理
- 5 分钟课程视频返回：
  - transcript
  - `3-5` 个关键段
  - 每段至少 1 张关键帧
  - 有文字的关键帧带 OCR 结果
- 同一个视频重复处理时命中缓存，不重复 ASR/OCR
- 失败场景能区分：ffmpeg 失败、ASR 失败、OCR 失败

4. Lesson Spec 与导出
- 用相同输入生成 `lesson_spec`，字段齐全且结构固定
- 带 `revision_request` 时只改相关内容，不丢 `source_citations`
- `export-lesson-assets` 输出的 `.pptx/.docx` 能被 PowerPoint/WPS/Word 正常打开

5. 成本回归
- 统计 1 次图片 OCR、1 次 1 分钟语音、1 次 5 分钟视频的平均成本
- 确认视频处理总成本控制在 `0.15元/5分钟` 以内
- 确认没有额外引入 VLM 主链路调用

## Assumptions
- 单一厂商要求已经锁定，因此不保留 SiliconFlow 作为正式运行时供应商；若需要兼容旧环境，只允许保留旧配置映射，不保留双写逻辑。
- 语音输入默认是“上传后转写”，不是实时流式识别。
- 视频关键帧策略固定为“transcript 驱动选帧”，不是“全视频视觉理解”。
- v1 不上 `qwen3-vl-flash`；只有在后续验收确认 transcript+OCR 不够时，才允许作为 v2 可选能力加入。
- 官方参考：
  - 阿里云百炼 OCR 价格与模型：[qwen-vl-ocr 价格](https://help.aliyun.com/zh/model-studio/billing-for-text-rerank)
  - 阿里云百炼文本生成价格：[qwen3.5-flash 价格](https://help.aliyun.com/zh/model-studio/billing-for-text-rerank)
  - 阿里云百炼 Embedding 兼容接口：[text-embedding-v4](https://help.aliyun.com/zh/model-studio/developer-reference/embedding-interfaces-compatible-with-openai)
  - 阿里云百炼 ASR 价格与 Python SDK：[fun-asr-realtime Python SDK](https://help.aliyun.com/zh/model-studio/fun-asr-realtime-python-sdk)
  - 阿里云百炼视觉/视频兼容接口：[图像与视频理解](https://help.aliyun.com/zh/model-studio/vision)