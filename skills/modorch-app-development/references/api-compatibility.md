> Generated snapshot; source: docs/reference/compatibility.md; source sha256: aa206168617c10853572060a75ef16b1ed745e596f43196ad4a26eea1abe1acd; revision 1.0.2. Do not edit.

# API、Feature 与 Skill 兼容

版本与 Feature 唯一维护表（源码定位：`../compatibility.md`；从匹配框架源码查询）定义 0.1.0 / MSRV 1.85 / Edition 2024。公开入口为 Facade；开发期 0.x 不假定跨 minor 兼容。

Skill revision 1.0.2 只兼容 Bundle 清单列出的实际框架指纹。执行前读取 Cargo metadata --locked --offline，核对解析后的版本、源码、Feature；Git 依赖固定 commit。即使版本仍是 0.1.0，修改过的源码也须重新验证与刷新快照。

外部应用添加 Cargo 依赖不会安装 Skill。Bundle 安装器只放到明确目标的 .agents/skills；自动发现是否生效由宿主决定。安装验证、哈希算法、离线行为见 分发说明（源码定位：`../../tools/skill-packaging/README.md`；从匹配框架源码查询）。

[COMPAT-001 / COMPAT-002](contracts/compatibility-contract.md)是规范性要求；迁移记录（源码定位：`../migration/0.1-development.md`；从匹配框架源码查询）记录本轮 API 与旧草案差异。匹配失败必须 Blocked，不能改写清单来绕过验证。
