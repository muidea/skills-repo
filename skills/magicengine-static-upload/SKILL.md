---
name: magicengine-static-upload
description: 用于处理 magicEngine 的静态资源服务、嵌入静态资源和文件上传路由。新增前端资源托管、上传接口或排查静态文件路径问题时使用。
version: 1.0.0
---

# magicEngine Static Upload

这个 skill 重点面向静态文件服务和上传路由。

## 1. 先看这些文件

- `README.md`
- `docs/design-http.md`
- `http/static.go`
- `http/embed_static.go`
- `http/upload.go`
- `http/env.go`
- `http/errors.go`

## 2. 核心关注点

- `StaticOptions`
- `prepareStaticOptions(...)`
- `serveStaticFile(...)`
- `StaticHandler(...)`
- `CreateUploadRoute(...)`
- `RelativePath` / `FileField` / `FileName` 上下文键

## 3. 处理规则

- 静态资源问题先确认：
  - `RootPath`
  - `PrefixUri`
  - `ExcludeUri`
  - `Fallback`
  - `IndexFile`
- 嵌入静态资源时，先核对 `embed_static.go` 和 `Root`
- 文件上传默认字段名是 `file`
- 上传逻辑需要动态目录或文件名时，优先通过 context 注入 `RelativePath` / `FileName`
- 修改上传逻辑时，注意 `ParseMultipartForm(...)` 的大小限制和回调时机

## 4. 推荐验证

```bash
GOCACHE=/tmp/magicengine-gocache go test ./http -count 1
```
