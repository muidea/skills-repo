---
name: magicfile-client-integration
description: "用于处理 `magicFile/pkg/client` 的调用约定、URL 构造和上下文参数传递。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicfile-client-integration

用于处理 `magicFile/pkg/client` 的调用约定、URL 构造和上下文参数传递。

## 适用场景

- 调整上传、下载、查询、更新、提交接口
- 排查 namespace/source/scope 透传问题
- 补 client 级 direct test

## 重点文件

- [pkg/client/client.go](magicFile/pkg/client/client.go)
- [design-file-service.md](magicFile/docs/design-file-service.md)
- [testing-guide.md](magicFile/docs/testing-guide.md)

## 工作方式

1. 先确认目标接口是否带 API version
2. 保持 `namespace` 通过 context values 透传
3. `fileSource` / `fileScope` 只在需要的接口上附加
4. 修改后至少跑 `pkg/client` 测试

## 验证

```bash
GOCACHE=/tmp/magicfile-gocache go test ./pkg/client -count 1
```
