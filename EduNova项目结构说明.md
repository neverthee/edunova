# EduNova 项目结构说明

本文档只说明当前打包后的目录结构。启动、解释器、LibreOffice、Node/npm 和 API 配置请以根目录 `README.md` 为准。

## 标准启动入口

- `run.bat`：同时启动前端和后端
- `start_backend.bat`：启动 Flask 后端
- `start_frontend.bat`：启动 Vue/Vite 前端

三个脚本都会以脚本所在目录作为项目根目录，正常移动或解压项目后不需要手动修改启动路径。

## 根目录

```text
<项目根目录>
├── backend/                    后端 Flask 服务
├── frontend/                   前端 Vue 3 项目
├── source/                     项目示例素材
├── example/                    示例资料
├── uploads/                    运行时知识库产物目录
├── 环境/                       环境导出与说明
├── 改动日志.assets/            文档图片资源
├── api.md                      API 与模型接入记录
├── DEPENDENCIES.md             依赖说明
├── EduNova 项目简介.md         项目简介
├── README.md                   快速启动说明
├── requirements.txt            Python 依赖
├── run.bat
├── start_backend.bat
└── start_frontend.bat
```

## 后端目录

```text
backend/
├── api/                        Flask 路由
├── config/                     模型与模块配置
├── database/                   SQLite 数据与迁移脚本
├── graph_rag/                  图谱检索逻辑
├── instance/                   Flask instance 数据
├── models/                     SQLAlchemy 数据模型
├── rag/                        RAG、资料解析、课件/文档生成
├── tasks/                      后台任务
├── templates/                  模板与 .env.example
├── uploads/                    后端运行时上传目录
├── utils/                      工具函数
├── docs_config.py              Swagger 配置
├── extensions.py               Flask 扩展初始化
├── init_db.py                  重建数据库脚本
├── main.py                     后端入口
└── run.py                      调试启动入口
```

## 前端目录

```text
frontend/
├── public/                     静态资源
├── src/
│   ├── api/                    前端 API 封装
│   ├── assets/                 静态资源
│   ├── components/             组件
│   ├── config/                 前端配置
│   ├── router/                 路由
│   ├── services/               服务层
│   ├── stores/                 Pinia 状态
│   ├── views/                  页面视图
│   ├── App.vue
│   ├── main.css
│   └── main.ts
├── package.json
├── package-lock.json
├── vite.config.ts
├── tsconfig.json
└── tailwind.config.js
```

## 配置位置

- Python 解释器：`start_backend.bat` 中的 `PYTHON_EXE`
- Node/npm：`start_frontend.bat` 中的 `NODE_EXE` 和 `NPM_CMD`
- LibreOffice：`start_backend.bat` 中的 `SOFFICE_PATH`
- API Key 和模型：`backend/.env`
- 前端 API 代理：`frontend/vite.config.ts`、`frontend/src/config/api.ts`

## 打包说明

当前项目已清理运行生成物，不应再把下面内容放进压缩包：

- `frontend/node_modules`
- `frontend/dist`
- `backend/uploads` 中的真实上传文件和处理缓存
- `uploads` 中的知识库产物
- `__pycache__`
- 写有真实密钥的 `.env`
