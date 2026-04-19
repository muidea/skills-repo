---
name: magicorm-testing-db
description: 用于处理 magicOrm 的测试分层、数据库集成测试、本地/远端测试分组、脚本入口和环境问题排查。需要跑 go test、定位 PostgreSQL/MySQL 依赖或整理 test 目录结构时使用。
version: 1.0.0
---

# magicOrm Testing DB

这个 skill 用于测试执行和环境排查。

## 1. 先读这些文档

- `docs/testing-guide.md`
- `test/README.md`

## 2. 现有入口

- `./unit_test.sh`
- `./integration_test.sh`
- `./local_test.sh`
- `./remote_test.sh`

## 3. 测试分层

- 无数据库回归：
  - `provider`
  - `validation`
  - `metrics`
  - `test/consistency`
- 数据库集成测试：
  - `test`
- Remote/VMI 场景：
  - `test/vmi`
  - `provider/remote`
  - `provider/helper`

## 4. 排查顺序

1. 先确认是不是环境问题
2. 再确认是 Local 还是 Remote 路径
3. 再确认是 provider、orm、builder 还是数据库依赖
4. 环境敏感失败要避免 panic 放大

## 5. 推荐命令

```bash
GOCACHE=/tmp/magicorm-gocache GOFLAGS=-mod=mod go test ./... --count 1
```

如果只跑 unit：

```bash
./unit_test.sh
```

如果只跑远端：

```bash
./remote_test.sh
```
