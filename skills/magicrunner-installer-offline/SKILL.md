---
name: magicrunner-installer-offline
description: "用于处理 `blocks/installer` 的离线安装、路径配置和应用包检查；完整应用运行生命周期、schema、compose、启停卸载链路优先使用 magicrunner-application-runtime-lifecycle。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.3
  author: "rangh-codespace"
---
# magicrunner-installer-offline

用于处理 `blocks/installer` 的离线安装、路径配置和应用包检查。

如果任务跨越 panel schema、installer、compose runtime artifact、启动停止或卸载清理，优先使用 `magicrunner-application-runtime-lifecycle`。

## 适用场景

- 调整 `magicInstaller` 行为
- 排查 `app.json` / `cas.json` / `entity` / `data` 加载问题
- 处理安装器路径、临时目录和密钥加载

## 重点文件

- [design-startup.md](magicRunner/docs/design-startup.md)
- [design-modules.md](magicRunner/docs/design-modules.md)
- [module.go](magicRunner/internal/modules/blocks/installer/module.go)
- [offline.go](magicRunner/internal/modules/blocks/installer/biz/offline.go)
- [config.go](magicRunner/internal/modules/blocks/installer/config/config.go)

## 工作方式

1. 先确认 `action` 和 `appPath`
2. 配置与路径错误优先降级返回，不要常规路径 panic
3. 安装链路按 `应用 -> cas -> entity -> data -> start` 顺序检查
4. 变更后至少跑 installer 相关测试和全仓测试

## 验证

```bash
GOCACHE=/tmp/magicrunner-gocache go test ./internal/modules/blocks/installer/... -count 1
GOCACHE=/tmp/magicrunner-gocache go test ./... -count 1
```
