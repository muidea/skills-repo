---
name: magicplatform-deploy
description: Guides AI agents through safe magicPlatform deployment, upgrade, offline delivery, dependency self-checks, and read-only preflight/health verification. Use when preparing hosts, validating TLS/image modes, initializing/resetting/updating deployments, packaging offline releases, or diagnosing container and HTTPS health.
metadata:
  version: "1.2.1"
  author: "rangh-codespace"
  tags: "magicplatform,deployment,tls,docker-compose,ops"
compatibility: Compatible with open_code
---

# magicPlatform 部署与运维指南

用于指导在任意干净或已初始化主机上执行 `magicPlatform`（`~/dataspace/magicPlatform`）的依赖核对、预检、初始化、开发更新、离线发布包交付与只读健康巡检。

## 何时使用

- 准备新机器或接管现有部署，需要核对工具依赖、Docker、OEM、域名、TLS 与端口前提。
- 执行 `./initialize.sh`、`./start.sh`、`./stop.sh`、`./update.sh`、`./reset.sh` 或 `./release.sh` + `./load.sh`。
- 需要对本机或远端已部署环境做只读巡检与故障定界。

## 前置依赖与自检

在执行部署或巡检前，先确认宿主机具备必需的只读检查与容器工具：

| 组件 | 要求 | 说明 |
| --- | --- | --- |
| POSIX Shell & 文本工具 | `sh`、`sed`、`grep`、`jq`、`openssl` | 全部部署入口脚本与 TLS 校验证书必备；离线 [foundation-database_test.sh](~/dataspace/magicPlatform/tests/deployment/foundation-database_test.sh) 另需 `bash` |
| Python | `python3 >= 3.9` | 3.11+ 零第三方依赖；3.9/3.10 需安装 `tomli==2.2.1`（见 `scripts/requirements.txt`） |
| HTTP 客户端 | `curl` | `deployment-health.sh` 探活必需，`deployment-preflight.sh` 会在起跑前拦截缺失 |
| 容器运行时 | `docker` + `docker compose`（v2） | 本地部署、更新与本机容器健康检查必需；远端使用 `--skip-docker --base-url` 时可省略 |
| 端口与测试扩展（可选） | `ss`；`go`（`GOFLAGS=-mod=vendor`）+ 同级 `magicRunner`/`magicFile` | 缺 `ss` 时仅跳过 80/443 本地占用探测；仅运行 `platform-manifests_test.sh` 时需要 Go 与上游源码 |

一键只读依赖自检（不修改任何文件）：

```sh
for c in sh python3 jq openssl curl sed grep docker; do
  command -v "$c" >/dev/null 2>&1 || echo "MISSING:$c"
done
docker compose version >/dev/null 2>&1 || echo "MISSING:docker-compose"
PYTHONDONTWRITEBYTECODE=1 python3 -B ~/dataspace/magicPlatform/scripts/deployment_toml.py
```

## 核心规则与安全边界

1. **禁止普通用户与 `sudo` 混跑**：`initialize.sh` 会将 `sudo` 调用退回 `SUDO_USER`；日常推荐以专用普通部署属主执行全套脚本，若目标测试机全程以 `root`（`DEPLOYMENT_UID=0`）直接部署与运维，则保持全程同 UID 一致且不混用其他账号，解压离线包时加 `--no-same-owner`，确保 `services/data`、`services/secret`、`apps/` 属主与 `DEPLOYMENT_UID`/`DEPLOYMENT_GID` 一致。
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

# 发布模式（未初始化 local-ca 环境先省略 --require-tls，待 initialize.sh 生成证书或 files/acme 材料就位后再加 --require-tls）
sh ~/dataspace/magicPlatform/scripts/deployment-preflight.sh --mode release --domain local.vpc --json
sh ~/dataspace/magicPlatform/scripts/deployment-preflight.sh --mode release --require-tls --json
```

`deployment-preflight.sh` 会同时核对 `sh`/`python3`/`jq`/`openssl`/`curl`/`tomli`/Docker 及 OEM/端口。

### 2. 初始化与生命周期管理

```sh
cd ~/dataspace/magicPlatform

# 本机开发环境初始化 / 重启 / 刷新镜像 / 开启 APM（性能测试用）
MAGIC_DEPLOYMENT_MODE=development DOMAIN=local.vpc ./initialize.sh
MAGIC_DEPLOYMENT_MODE=development ./start.sh
ENABLE_APM=true MAGIC_DEPLOYMENT_MODE=development ./start.sh
MAGIC_DEPLOYMENT_MODE=development ./update.sh

# 离线发布打包（源机）-> 解压、导入、预检、初始化与启用 APM（目标机，严格 release 模式）
./release.sh
# 目标机解压（剥离顶层 release/ 且不继承源机属主）：
tar -xzf platform*.tgz --strip-components=1 --no-same-owner -C <目标目录>
cd <目标目录>
# 若目标机使用 local.vpc 且无本地解析，先确保 /etc/hosts 含 127.0.0.1 panel.local.vpc apm.local.vpc
./load.sh
sh scripts/deployment-preflight.sh --mode release --domain local.vpc --json
./initialize.sh --domain local.vpc
# initialize.sh 不自动启动 APM；如需性能观测则执行：
ENABLE_APM=true ./start.sh
sh scripts/deployment-health.sh --include-apm --json
# 等待约 15s 首轮抓取后确认 5 个 Prometheus 任务（node-exporter/cadvisor/postgres-exporter/magicbase/traefik）均为 up 且宿主机未暴露 8082
```

更多模式与 TLS 参数见 [TLS 与交付矩阵](references/tls-and-delivery-matrix.md)。

### 3. 部署后只读健康巡检

```sh
# 本机全套容器 + HTTPS 公开入口验证
sh ~/dataspace/magicPlatform/scripts/deployment-health.sh --json

# 远端主机只读 HTTPS 校验（走系统 CA）
sh ~/dataspace/magicPlatform/scripts/deployment-health.sh \
  --skip-docker --base-url https://panel.example.com --json

# 远端主机含 APM（Prometheus + Grafana）只读 HTTPS 校验
sh ~/dataspace/magicPlatform/scripts/deployment-health.sh \
  --skip-docker --base-url https://panel.example.com --include-apm --json
```

> **分机性能/高频功能回归提示**：
> - 开启 `ENABLE_APM=true ./start.sh` 后，Traefik 通过内部容器网络 `:8082`（不向宿主机暴露端口）向 Prometheus 提供入口 QPS/延迟/状态码指标，测试机经 `https://apm.<domain>/prometheus/` 只读查询；非内网环境请配合访问控制/BasicAuth，避免裸露 APM 端点。
> - 当独立测试机从单一源 IP 高频登录或压测时，CAS 默认 `[oauth.loginRate]` 为同租户同 IP 60 秒限 30 次登录；若需调整，仅修改测试部署运行配置 `services/runtime/foundation/config/cas/application.toml` 并如实记录，严禁关闭账号锁与鉴权校验。

## 故障定位顺序

1. 先运行 `deployment-preflight.sh --json` 排除依赖工具缺失、OEM、域名、UID、端口 80/443 占用及 `images.lock.json` 问题。
2. 再运行 `deployment-health.sh --json` 定位是基础容器（`postgres`/`magicbase`/`magiccas`/`traefik`）、核心控制面（`magicFile`/`magicPanel`/`magicGateway`/`magicWebPortal`）还是 OIDC Discovery / JWKS 异常。
3. 核对基础服务依赖顺序：`postgres` -> `magicbase` -> `magiccas` -> Bootstrap/Installer -> `magicFile` -> `magicPanel` -> `magicGateway` -> `magicWebPortal`。
4. 修改脚本或静态清单后，执行 `tests/deployment/deployment-checks_test.sh` 与 `tools/check_repository_layout.py`（加 `PYTHONDONTWRITEBYTECODE=1`）。

## Formatter

- `SKILL.md` 及配套文档保持规范 Markdown 排版；Shell 与 Python 脚本遵循仓内 `sh`、`PYTHONDONTWRITEBYTECODE=1` 与只读检查约定，不在 `magicPlatform` 内留下 `.pyc`、`__pycache__` 或临时文件。
