---
name: magicmodulesrepo-totalizator
description: "用于处理 `magicModulesRepo` 的 totalizator 模块，包括事件入口、BaseClient 调用和 namespace 语义。"
compatibility: Compatible with open_code
metadata:
  version: 1.0.2
  author: "rangh-codespace"
---
# magicmodulesrepo-totalizator

用于处理 `magicModulesRepo` 的 totalizator 模块，包括事件入口、BaseClient 调用和 namespace 语义。

## 适用场景

- 调整 `FilterTotalizator` / `CheckTotalizator` / `RefreshTotalizator`
- 统一参数错误和 namespace 错误语义
- 排查 totalizator 注册和刷新链路

## 重点文件

- [design-modules.md](magicModulesRepo/docs/design-modules.md)
- [biz.go](magicModulesRepo/modules/blocks/totalizator/biz/biz.go)
- [module.go](magicModulesRepo/modules/blocks/totalizator/module.go)

## 工作方式

1. 先判断失败发生在参数提取、namespace 准备还是 BaseClient 调用
2. 明显非法输入统一返回 `IllegalParam`
3. 保持 `check` 的“先查后补”语义
4. 修改后补 biz 级 direct test

## 验证

```bash
GOCACHE=/tmp/magicmodulesrepo-gocache go test ./modules/blocks/totalizator/biz -count 1
```
