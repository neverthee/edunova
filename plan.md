---
name: EduNova上线部署计划
overview: 基于 Codex 已完成的部署适配代码，梳理从购买域名到项目完全上线的全部剩余步骤。代码层面仅需少量收尾，主要工作在购买服务、配置服务和联调。
todos:
  - id: code-cleanup
    content: 本地代码收尾：.gitignore 排除 source/ 大文件、确认 .env 安全、提交最终版本
    status: pending
  - id: buy-domain
    content: 阿里云购买域名并完成实名认证
    status: pending
  - id: setup-cloudflare
    content: 注册 Cloudflare，托管域名 DNS（修改阿里云 Nameserver）
    status: pending
  - id: buy-vps
    content: 购买香港 VPS（2核2G+），配置安全组放行 22/80/443
    status: pending
  - id: push-github
    content: 创建 GitHub 私有仓库并推送代码
    status: pending
  - id: deploy-frontend
    content: Vercel 部署前端：配置构建参数、环境变量、绑定自定义域名
    status: pending
  - id: deploy-backend
    content: VPS 部署后端：安装环境、拉取代码、配置 .env、启动 Gunicorn 服务
    status: pending
  - id: setup-nginx-ssl
    content: 配置 Cloudflare Origin Certificate + Nginx HTTPS 反向代理 + DNS A 记录
    status: pending
  - id: integration-test
    content: 前后端联调验证：健康检查、登录、文件上传、AI 功能
    status: pending
  - id: security-harden
    content: 安全加固：修改默认密码、确认防火墙、开启强制 HTTPS
    status: pending
isProject: false
---

# EduNova 上线部署完整计划

## 现状评估

Codex 已经完成的部署适配（commit `9859c54`）：

- `frontend/vite.config.ts` 已移除硬编码的 `VITE_API_BASE_URL`
- `frontend/src/config/api.ts` 已改为优先读取环境变量，本地开发走 Vite proxy
- `backend/main.py` 已添加 `load_dotenv`、`CORS_ORIGINS` 环境变量支持
- `deploy/` 目录下已有完整的 Nginx、systemd、env 模板和部署文档
- `.gitignore` 已排除 `.env`、`.sqlite`、`uploads/` 等敏感/运行时文件
- `backend/.env` 未被 Git 跟踪（安全）
- 前端所有 `.vue` 文件中已无 `localhost` 硬编码，全部通过 `API_ORIGIN` / `API_BASE_URL` 统一管理

**结论：代码已基本就绪，仅需 2 处小收尾。**

---

## 第一阶段：本地代码收尾（30 分钟）

### 1.1 清理 `source/` 目录中的大文件

当前 `source/` 目录包含视频（`.mp4`，约 20MB）和多个测试文档，这些不应推送到 GitHub（浪费仓库空间、拖慢 clone）。

操作：
- 在 `.gitignore` 中添加 `source/` 目录（或仅排除大文件类型 `*.mp4`）
- 如果这些文件已被 Git 跟踪，需要 `git rm --cached` 移除

### 1.2 确认 `backend/.env` 内容安全

- 检查 `backend/.env` 中的 `LLM_API_KEY` 是否已替换为占位符
- 如果曾经提交过真实 Key（在历史 commit 中），上线前到阿里云控制台轮换 API Key

### 1.3 创建 `.env.production` 前端文件

- 复制 `frontend/.env.production.example` 为 `frontend/.env.production`
- 填入真实的后端 API 地址（等域名确定后填写）
- 此文件不提交到 Git（已被 `.gitignore` 排除）

---

## 第二阶段：购买域名（15 分钟 + 等待 1-2 天实名审核）

### 2.1 在阿里云购买域名

1. 打开 https://wanwang.aliyun.com/domain
2. 搜索想要的域名（建议 `.com` 后缀）
3. 购买并完成实名认证
4. 等待实名审核通过（通常 1-2 天）

### 2.2 规划子域名

```
你的域名.com       -> Vercel 前端
www.你的域名.com   -> Vercel 前端（重定向到主域名）
api.你的域名.com   -> 香港 VPS 后端
```

---

## 第三阶段：接入 Cloudflare（20 分钟）

1. 注册 Cloudflare（https://dash.cloudflare.com/sign-up）
2. Add a site -> 输入你的域名 -> 选 Free 计划
3. 记下 Cloudflare 给的两个 Nameserver 地址
4. 回到阿里云域名控制台 -> DNS 修改 -> 改成 Cloudflare 的 Nameserver
5. 回到 Cloudflare 点 Check nameservers
6. 等状态变为 Active（通常 10 分钟 - 数小时）

---

## 第四阶段：购买香港 VPS（10 分钟）

推荐配置：2 核 2GB+ 内存、40GB 磁盘、Ubuntu 22.04、香港地区

购买后立即做：
- 安全组/防火墙放行 22、80、443 端口
- 不要放行 5001 端口
- SSH 测试连接：`ssh root@服务器IP`

---

## 第五阶段：推送代码到 GitHub（10 分钟）

1. GitHub 创建私有仓库
2. 本地执行：

```bash
git remote add origin https://github.com/你的用户名/edunova.git
git branch -M main
git push -u origin main
```

3. 确认 `backend/.env` 和 `.sqlite` 文件没有被推送上去

---

## 第六阶段：部署前端到 Vercel（20 分钟）

1. 用 GitHub 账号登录 Vercel
2. Add New Project -> 选择 edunova 仓库
3. 配置：
   - Framework Preset: `Vue.js`
   - Root Directory: `frontend`
   - Build Command: `npm run build-only`
   - Output Directory: `dist`
4. 环境变量：`VITE_API_BASE_URL` = `https://api.你的域名.com`
5. Deploy
6. Settings -> Domains -> 添加 `你的域名.com` 和 `www.你的域名.com`
7. 按 Vercel 提示在 Cloudflare DNS 中添加对应记录

---

## 第七阶段：初始化 VPS 并部署后端（1 小时）

### 7.1 安装环境

```bash
apt update && apt upgrade -y
apt install -y python3 python3-venv python3-pip git nginx curl
apt install -y libreoffice fonts-noto-cjk fonts-wqy-zenhei
apt install -y libmagic1
```

### 7.2 拉取代码并安装依赖

```bash
cd /opt
git clone https://github.com/你的用户名/edunova.git
cd /opt/edunova
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip wheel setuptools
pip install -r requirements.txt
```

### 7.3 配置后端 `.env`

```bash
cp deploy/backend.production.env.example backend/.env
nano backend/.env
```

需要填写：`SECRET_KEY`、`JWT_SECRET_KEY`、`CORS_ORIGINS`、`LLM_API_KEY`

### 7.4 创建目录并授权

```bash
mkdir -p /opt/edunova/backend/uploads/avatars
mkdir -p /opt/edunova/uploads
mkdir -p /opt/edunova/backend/database
chown -R www-data:www-data /opt/edunova
```

### 7.5 启动 Gunicorn 服务

```bash
cp deploy/systemd/edunova.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable edunova && systemctl start edunova
curl http://127.0.0.1:5001/api/health   # 应返回 {"status":"ok"...}
```

### 7.6 配置 Cloudflare Origin Certificate + Nginx

1. Cloudflare -> SSL/TLS -> Origin Server -> Create Certificate
2. 保存证书到服务器 `/etc/ssl/cloudflare/`
3. 复制并编辑 Nginx 配置：

```bash
cp deploy/nginx/edunova-api.conf /etc/nginx/sites-available/edunova-api
# 编辑文件，把 api.example.com 替换为 api.你的域名.com
ln -s /etc/nginx/sites-available/edunova-api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

### 7.7 Cloudflare DNS 添加后端记录

- Type: `A`, Name: `api`, Value: 服务器 IP, Proxy: Proxied
- SSL/TLS 模式设为 `Full (strict)`

---

## 第八阶段：联调验证（30 分钟）

1. 访问 `https://api.你的域名.com/api/health` 确认后端可达
2. 访问 `https://你的域名.com` 确认前端页面加载
3. 打开浏览器 DevTools -> Network，确认 API 请求指向 `https://api.你的域名.com`
4. 用默认账号 `admin/admin123` 登录测试
5. 测试文件上传、AI 聊天、课件生成等核心功能

---

## 第九阶段：安全加固（上线后立即做）

- 修改默认账号密码（admin/teacher/student）
- 确认服务器防火墙只开放 22/80/443
- Cloudflare 开启 "Always Use HTTPS"
- Cloudflare Cache Rules 给 `api` 子域名设置 Bypass cache