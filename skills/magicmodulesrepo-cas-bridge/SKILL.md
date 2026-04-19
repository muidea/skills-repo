---
name: magicmodulesrepo-cas-bridge
description: "用于处理 `magicModulesRepo` 里 `cas` 模块的事件桥接和 `magicCas` 客户端调用。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicmodulesrepo-cas-bridge

用于处理 `magicModulesRepo` 里 `cas` 模块的事件桥接和 `magicCas` 客户端调用。

## 适用场景

- 调整 `VerifySession*` / `RegisterPrivilege` / `QueryEntity`
- 排查 namespace、session、entity 查询失败
- 统一事件入口错误语义

## 重点文件

- [design-modules.md](magicModulesRepo/docs/design-modules.md)
- [biz.go](magicModulesRepo/modules/blocks/cas/biz/biz.go)
- [cas.go](magicModulesRepo/modules/blocks/cas/pkg/common/cas.go)

## 工作方式

1. 先区分是事件输入错误还是远端 CAS 调用失败
2. 明显非法输入返回 `IllegalParam`
3. 缺少 namespace 时 fail-closed
4. 变更后补 biz 级 direct test

## 验证

```bash
GOCACHE=/tmp/magicmodulesrepo-gocache go test ./modules/blocks/cas/biz -count 1
```
