---
name: magicrunner-vmi-install-recovery
description: 用于处理 magicRunner 中离线安装 VMI 的恢复链，包括 installer、database block、schema 回滚、账号密码同步、定义更新和应用启动。涉及 install/offline、CreateSchema、DownloadApplication、UpdateEntity 时使用。
version: 1.0.0
---

# magicRunner VMI Install Recovery

这个 skill 只关注 `magicRunner` 的离线安装恢复链。

## 先读这些文件

- `internal/modules/blocks/installer/biz/`
- `internal/modules/blocks/database/biz/`
- `internal/modules/kernel/panel/biz/application.go`
- `docs/design-startup.md`
- `docs/release-note-2026-03-hardening.md`
- `../docs/vmi-definition-regression-playbook.md`
- `../docs/service-reset-recovery-playbook.md`

## 当前稳定规则

- 离线安装链按：
  - 下载文件
  - 创建 schema / 数据库
  - 更新实体定义
  - 创建 application
  - 启动应用
- 失败时要回滚 schema 和数据库
- 数据库账号存在时要同步密码
- 更新实体定义时要按新对象覆盖旧定义

## 推荐验证

```bash
GOCACHE=/tmp/magicrunner-gocache \
go test ./internal/modules/blocks/installer/... ./internal/modules/blocks/database/biz ./internal/modules/kernel/panel/biz -count 1
```
