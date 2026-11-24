---
name: magicplatform-deploy
description: Guides AI agents through safe magicPlatform deployment, upgrade, offline delivery, and read-only preflight/health verification. Use when preparing hosts, validating TLS/image modes, initializing/resetting/updating deployments, packaging offline releases, or diagnosing container and HTTPS health.
metadata:
  version: "1.0.0"
  author: "rangh-codespace"
  tags: "magicplatform,deployment,tls,docker-compose,ops"
compatibility: Compatible with open_code
---

# magicPlatform 部署与运维指南

用于指导在任意干净或已初始化主机上执行 `magicPlatform`（`~/dataspace/magicPlatform`）的预检、初始化、开发更新、离线发布包交付与只读健康巡检。

## 何时使用

- 准备新机器或接管现有部署，需要核对 Docker、OEM、域名、TLS 与端口前提。
- 执行 `./initialize.sh`、`./start.sh`、`./stop.sh`、`./update.sh`、`./reset.sh` 或 `./release.sh` + `./load.sh`。
- 需要对本机或远端已部署环境做只读巡检与故障定界。

## 核心规则与安全边界

1. **禁止使用 `sudo` 直接创建运行时文件**：以部署属主普通用户执行脚本，确保 `DEPLOYMENT_UID`/`DEPLOYMENT_GID` 与 `services/data`、`services/secret`、`apps/` 属主一致。
2. **明确区分部署模式**：
   - 开发模式必须显式传递 `MAGIC_DEPLOYMENT_MODE=development`；使用本机 Docker daemon 中已标记 `:master` 的镜像（`initialize.sh` / `start.sh` / `reset.sh` 不自动拉取远端镜像）。
   - `update.sh` 仅允许在开发模式下运行，用于拉取最新镜像并按序重建服务。
   - 默认（无变量或 `release`）走严格发布模式：依赖 `services/images.lock.json` 与 `./load.sh` 导入的不可变镜像摘要。
3. **禁止手工修改运行态机密或数据库**：所有底座 Schema、私钥与认证引导均由 `initialize.sh` 和对应 owner 管理。
4. **远端健康检查不得误用本机证书**：检查公网或远端站点时，使用 `--skip-docker --base-url https://panel.<domain>`（或 `--system-ca`），避免加载本机 `services/secret/tls/`。

## 标准工作流

### 1. 部署前只读预检

```sh
# 源码开发模式预检（不会写文件或拉取镜像）
sh ~/dataspace/magicPlatform/scripts/deployment-preflight.sh --mode development --json

# 发布模式（校验 services/images.lock.json、本地镜像及 TLS）
sh ~/dataspace/magicPlatform/scripts/deployment-preflight.sh --mode release --require-tls --json
```

### 2. 初始化与生命周期管理

```sh
cd ~/dataspace/magicPlatform

# 本机开发环境初始化 / 重启 / 刷新镜像
MAGIC_DEPLOYMENT_MODE=development DOMAIN=local.vpc ./initialize.sh
MAGIC_DEPLOYMENT_MODE=development ./start.sh
MAGIC_DEPLOYMENT_MODE=development ./update.sh

# 离线发布打包（源机）-> 导入与初始化（目标机）
./release.sh
# 解压到目标机后：
./load.sh
./initialize.sh
```

更多模式与 TLS 参数见 [TLS 与交付矩阵](references/tls-and-delivery-matrix.md)。

### 3. 部署后只读健康巡检

```sh
# 本机全套容器 + HTTPS 公开入口验证
sh ~/dataspace/magicPlatform/scripts/deployment-health.sh --json

# 远端主机只读 HTTPS 校验（走系统 CA）
sh ~/dataspace/magicPlatform/scripts/deployment-health.sh \
  --skip-docker --base-url https://panel.example.com --json
```

## 故障定位顺序

1. 先运行 `deployment-preflight.sh --json` 排除 OEM、域名、UID、端口 80/443 占用及 `images.lock.json` 问题。
2. 再运行 `deployment-health.sh --json` 定位是基础容器（`postgres`/`magicbase`/`magiccas`/`traefik`）、核心控制面（`magicFile`/`magicPanel`/`magicGateway`/`magicWebPortal`）还是 OIDC Discovery / JWKS 异常。
3. 核对基础服务依赖顺序：`postgres` -> `magicbase` -> `magiccas` -> Bootstrap/Installer -> `magicFile` -> `magicPanel` -> `magicGateway` -> `magicWebPortal`。
4. 修改脚本或静态清单后，执行 `tests/deployment/deployment-checks_test.sh` 与 `tools/check_repository_layout.py`（加 `PYTHONDONTWRITEBYTECODE=1`）。

## Formatter

- `SKILL.md` 及配套文档保持规范 Markdown 排版；Shell 与 Python 脚本遵循仓内 `sh`、`PYTHONDONTWRITEBYTECODE=1` 与只读检查约定，不在 `magicPlatform` 内留下 `.pyc`、`__pycache__` 或临时文件。
