---
name: magicfile-file-service
description: "用于处理 `magicFile` 的文件上传、下载、浏览、元数据管理和清理逻辑。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicfile-file-service

用于处理 `magicFile` 的文件上传、下载、浏览、元数据管理和清理逻辑。

## 适用场景

- 调整 upload/download/view/commit/update/delete/explorer 路径
- 排查文件物理路径和公开路径不一致
- 排查临时文件、过期文件清理问题

## 重点文件

- [design-file-service.md](magicFile/docs/design-file-service.md)
- [biz.go](magicFile/internal/modules/file/biz/biz.go)
- [file.go](magicFile/internal/modules/file/service/file.go)
- [service.go](magicFile/internal/modules/file/service/service.go)
- [manager.go](magicFile/internal/modules/file/service/manager.go)

## 工作方式

1. 先区分是元数据问题、磁盘路径问题还是权限/namespace 问题
2. 保持元数据 `Path` 为可访问路径 `/static/...`
3. 删除和清理时统一通过存储路径解析 helper 定位磁盘文件
4. 对临时文件和普通文件分别使用不同的过期语义

## 验证

```bash
GOCACHE=/tmp/magicfile-gocache go test ./internal/modules/file/... -count 1
```
