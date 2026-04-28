# EduNova Deployment Notes

Target architecture:

- Frontend: Vercel, built from `frontend/`
- Backend: Hong Kong Ubuntu VPS, running Flask through Gunicorn + Nginx
- DNS/CDN/TLS: Cloudflare
- Domain registrar: Aliyun

## Required Production Variables

Vercel project variable:

```text
VITE_API_BASE_URL=https://api.example.com
```

Backend server file:

```text
/opt/edunova/backend/.env
```

Use `deploy/backend.production.env.example` as the template. Do not commit the real server `.env`.

## Backend Service

Copy `deploy/systemd/edunova.service` to:

```text
/etc/systemd/system/edunova.service
```

Then run:

```bash
sudo systemctl daemon-reload
sudo systemctl enable edunova
sudo systemctl start edunova
sudo systemctl status edunova
```

## Nginx

Copy `deploy/nginx/edunova-api.conf` to:

```text
/etc/nginx/sites-available/edunova-api
```

Create a Cloudflare Origin Certificate first, save it to `/etc/ssl/cloudflare/edunova-origin.pem` and `/etc/ssl/cloudflare/edunova-origin.key`, replace `api.example.com`, enable the config, then reload Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/edunova-api /etc/nginx/sites-enabled/edunova-api
sudo nginx -t
sudo systemctl reload nginx
```
