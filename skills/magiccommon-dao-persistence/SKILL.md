---
name: magiccommon-dao-persistence
description: 用于基于 magicCommon foundation/dao 处理业务数据库接入、驱动选择、连接获取、查询执行、事务和数据库相关测试。编写或排查 MySQL、PostgreSQL 持久化逻辑时使用。
version: 1.0.0
---

# magicCommon DAO Persistence

这个 skill 用于业务持久化接入，不处理 ORM 或更高层仓储抽象。

## 1. 先读这些文件

- `foundation/dao/common.go`
- `foundation/dao/dao_mysql.go`
- `foundation/dao/dao_postgres.go`
- `foundation/dao/VALIDATION_SUMMARY.md`

## 2. 典型任务

- 选择 MySQL 还是 PostgreSQL driver
- 获取 DAO 连接
- 执行查询、写入、事务
- 排查数据库连接、执行、环境依赖问题

## 3. 处理规则

- 环境敏感测试要允许数据库不可用时干净跳过，不要把环境问题放大成 panic。
- 先确认是连接问题、SQL 问题，还是测试环境问题。
- 对业务代码，优先把驱动配置和连接参数集中管理。

## 4. 测试建议

- 本地先跑针对性包测试，不要每次都直接全量。
- 如果问题只涉及连接层，优先跑 `foundation/dao`。

## 5. 推荐验证

```bash
GOCACHE=/tmp/magiccommon-gocache GOFLAGS=-mod=vendor \
go test ./foundation/dao -count 1
```
