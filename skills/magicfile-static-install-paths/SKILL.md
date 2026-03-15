---
name: magicfile-static-install-paths
description: 用于处理 magicFile 的上传、查看、静态下载、/static 路由、client 路径拼接和安装链文件访问问题。涉及 /static、/api/v1/files/view、双斜杠路径、文件元数据查询时使用。
version: 1.0.0
---

# magicFile Static And Install Paths

这个 skill 处理 `magicFile` 在安装链和静态资源链上的真实路径问题。

## 先读这些文件

- `internal/modules/file/service/service.go`
- `internal/modules/file/dao/dao.go`
- `pkg/client/client.go`
- `docs/design-file-service.md`
- `../docs/service-reset-recovery-playbook.md`

## 当前稳定规则

- `/static/` 上传依赖服务已正常注册路由
- `ViewFile` 等 client 路径必须经过规范化，不能出现双斜杠
- 查询文件时不要把空 slice 字段隐式带进查询条件

## 推荐验证

```bash
GOCACHE=/tmp/magicfile-gocache \
go test ./internal/modules/file/... ./pkg/client -count 1
```
