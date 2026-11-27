# magicWebPortal 8 大页面群布局与按钮收口对照清单

本文档配合 [SKILL.md](../SKILL.md) 使用，记录 Portal 与 Panel 全部 24 个路由页面的已定稿交互基线与测试锚点，新增或重构页面时直接按所属页面群对照自检。

## 1. Portal 首页与服务中心

- 覆盖页面：`/portal/`、`/portal/services/`、`/portal/feedbacks/`、`/portal/notifications/`、`/portal/applications/`。
- 主动作唯一：首页卡片仅 `进入应用` 使用 T1 实心主蓝；`PortalEntryButton` 在 `resource="service"` 时使用 T2 淡蓝描边按钮（`#f0f6ff` / `#91caff` / `#1677ff`），保持“进入服务”可访问文本。
- 行内收敛：`ServiceManagement` 每行保留 `查看`（`type="text"` T3）+ `进入服务` / `申请` + `更多` `Dropdown`（收纳 `API Key` 与 danger `取消订阅` + `Modal.confirm`）。
- 同类入口合并：移除独立 `提交反馈` / `提交需求` 双按钮，合并为 `+ 提交工单`，在 `FeedbackModal` 内通过 `Radio.Group` 选择 `FEEDBACK`（问题反馈）或 `DEMAND`（功能需求）。
- 通知弱化：`全部已读` 使用 `type="text"` + `.softActionBtn`，避免与 `查看全部 (N)` 抢夺焦点。
- 390px 栈式排列：`.serviceListItem`、`.sideListItem` 在 `<= 767px` 改为 `flex-direction: column; align-items: stretch;`，覆盖 `.ant-list-item-action { margin-inline-start: 0 !important; width: 100%; }`，杜绝描述列被挤压成单字换行。

## 2. Panel 管理概览

- 覆盖组件：`src/pages/panel/components/dashboard/TopOverview.tsx`、`TodoList.tsx`、`QuickActions.tsx`、`src/pages/panel/index.module.less`。
- 指标卡平衡：`TopOverview` `.overviewGrid` 使用 `repeat(auto-fill, minmax(220px, 1fr))`（1440px 呈均衡 `5 + 5` 排版）；所有指标关键字均配图标与独立浅色圆角底块（含 `反馈` / `工单` → `MessageOutlined`）。
- 待办块收口：`TodoList` 标题增加 `<FileDoneOutlined />` 与 `<Badge>`；右上角保留 `查看全部 (N) <RightOutlined />`，移除底部重复的 `查看全部待办 >`；行内 `去处理` 改为 `type="link"` + `aria-hidden="true"` 图标（维持 `aria-label="去处理"` 精确匹配）。

## 3. 应用定义与编排

- 覆盖页面：`src/pages/panel/application/definition-publish/definition/`、`src/pages/panel/application/orchestration/`。
- 去掉冗余占位：`ApplicationCardView` 空态使用 `<Empty>` 提示点击右上角 `新建应用定义`，不再在卡片网格末尾追加巨大的 `+ 新建应用定义` 虚线卡。
- 按钮降级与链接：`模型包管理`、`原生包管理` 降级为 T3 `type="link"`；`<Link to="..."><Button>模型包管理</Button></Link>` 结构需保留以兼容源码契约测试。
- 行操作收口：列表行展示 `查看` + `编辑` + `更多` `Dropdown`（收纳 `发布`、`发布记录` 及带确认弹窗的 danger `删除`）。

## 4. 应用部署、审批与任务

- 覆盖页面：`src/pages/panel/application/deployment/`、`src/pages/panel/operations/deployment-approval/`、`src/pages/panel/operations/deployment-tasks/`。
- 去嵌套 Card：`deployment/index.tsx` 去掉 `<Tabs>` 内 `当前应用部署` 的嵌套 `<Card>` 框，共享 `刷新` 上提至 `Tabs` `tabBarExtraContent`；`ArtifactDeploymentPanels`、`PackagedUninstallReviews`、`RuntimePlacementTasks` 使用 `bordered={false}`；`deployment-approval` 与 `deployment-tasks` 页用统一无边框白底 `<Card>` + `<Tabs>` 整合多张空表，消除页面纵向堆叠。
- 5 按钮→单行收口：部署列表每行展示 `安装详情`（T3 必须保留精准文本内联可见，供 `installation_summary_cases.cjs` 定位）+ `访问分配` + 异常/原生包按需恢复动作 + `更多` `Dropdown`（`激活` / `停用`、`升级`、divider、danger `卸载` / `重试卸载`）。

## 5. 服务目录、发布与订阅

- 覆盖页面：`src/pages/panel/hub/registry/`、`src/pages/panel/hub/publication/`、`src/pages/panel/hub/subscription/`。
- 单页聚合：`hub/publication` 合并顶部横幅、能力目录卡与治理中服务卡为单个无边框白底 `<Card>`，右上角工具栏统一承载搜索、`刷新`、`发布已有服务` 与唯一主 CTA `配置服务`；内容区采用扁平 `Tabs`（`治理中服务 (N)` / `待治理 (N)` / `全部能力 (N)`）。
- 能力清单折叠：治理中服务条目中长能力绑定文本收敛为单行可展开切换按钮（`绑定 N 项能力（点击展开预览）`），展开后显示紧凑 `<Tag>`。
- 服务目录与订阅：`hub/registry` 合并顶部搜索栏到主 Card 工具栏，卡片底栏保留 `进入服务` + `编辑` + `更多` `Dropdown`（含 `核对原操作` 与带确认的 danger `删除`）；`hub/subscription` 审批态保留 `审核`/`驳回` 内联，正常态仅保留 `凭证` + `更多`（`启用`/`停用`/danger `删除`）。

## 6. 空间与访问管理

- 覆盖页面：`src/pages/panel/cas/namespace/`、`src/pages/panel/cas/access/`。
- 内置空间去冗余：`isDefaultNamespace(record)`（`panel`）隐藏永久禁用的 `同步入口` 和 `删除` 按钮，仅渲染 `编辑` + 灰色次级文本 `内置空间`；非默认空间维持可操作行内链及 `[aria-label="编辑空间"]`、`[aria-label="删除空间"]`。
- 单行空间上下文：`cas/access` 将独立的 `访问管理范围` Card 与多行 `<Descriptions>` 收口为统一无边框主 Card 顶部的单行紧凑控制条（`目标空间` 选择器 + 精简状态 `<Tag>`）+ `<Divider />` + 8 个权限 Tabs。

## 7. 存储资源与系统设置

- 覆盖页面：`src/pages/panel/infra/database/`、`src/pages/panel/operations/settings/`。
- 存储视图统一：`infra/database/index.tsx` 为 `<Tabs>` 包裹无边框圆角白底主 Card，与 P1 其他模块容器一致。
- 系统设置三页签化：`operations/settings/index.tsx` 收口为统一主 Card + 三页签（`品牌与外观` / `会话安全` / `日志保留策略`，与 `?tab=` 查询串双向同步）；`当前生效信息` 收进右上角 `生效信息` 打开的 `<Drawer>`；危险操作 `清除全部覆盖` 收进顶栏 `更多` `Dropdown`；`LogRetentionSettings` 保持独立只读失败兜底与 `保存日志保留策略` 精准按钮文本。

## 8. 运营支持与内容管理

- 覆盖页面：`src/pages/panel/infra/file/`、`src/pages/panel/infra/catalog/`、`src/pages/panel/support/audit/`、`support/todos/`、`support/notification/`、`support/feedback/`。
- 面包屑激活态：`BreadcrumbNav` 将末尾当前路径（包括根目录 `/static`）渲染为 `<Typography.Text strong>`，避免无实际跳转效果的可点击链接样式；上层祖先节点保持可点击。
- 单主按钮分工：`infra/catalog` 左侧分类树主按钮明确为 `新建根分类`（T1），右侧列表新建按钮降级为次级并在选中子目录时明确显示 `新建子分类`。
- 表格单层容器与图标补齐：`support/audit` 为 Tabs 内 `<ProTable>` 关闭外边距与边框，去除 Card 套 Card；`support/todos` 补齐 `EyeOutlined`，`support/feedback` 补齐 `EyeOutlined` 与 `DeleteOutlined`；全部 `ProTable` 均配统一 `cardProps` 无边框圆角阴影样式。
