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
- 常用操作 & 待办：`QuickActions` 标题栏增加 `<ThunderboltOutlined />` 与 `TodoList`（`<FileDoneOutlined />` + `<Badge>`）保持视觉对称；待办右上角保留 `查看全部 (N) <RightOutlined />`，移除底部重复 `查看全部待办 >`，行内 `去处理` 改为 `type="link"` + `aria-hidden="true"` 图标（维持 `aria-label="去处理"` 精确匹配）。

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
- 内置空间去冗余 & 普通空间收口：`isDefaultNamespace(record)`（`panel`）隐藏永久禁用的 `同步入口` 和 `删除` 按钮，仅渲染 `编辑` + 灰色次级文本 `内置空间`；非默认空间行收口为 `编辑`（`[aria-label="编辑空间"]`）+ `更多` `Dropdown`（`[aria-label="更多空间操作"]`，收纳 `同步入口` 与 danger `删除`）。
- 单行空间上下文：`cas/access` 将独立的 `访问管理范围` Card 与多行 `<Descriptions>` 收口为统一无边框主 Card 顶部的单行紧凑控制条（`目标空间` 选择器 + 精简状态 `<Tag>`）+ `<Divider />` + 8 个权限 Tabs。
- 8 个子页签全面去内框与行内收口：`account`、`role`、`template`、`endpoint`、`registration`、`oauth` 均去掉内嵌边框、`headStyle`/`bodyStyle` `paddingInline: 0` 且 `<ProTable>` 配置 `cardBordered={false}`；`account`/`endpoint`/`template`/`oauth`/`federation` 多动作表格行均收敛为 `≤ 2 个直出链接 + 更多 Dropdown`（`oauth` 同步统一使用 `空间接入设置` / `空间 OAuth2 应用接入` 文案）。

## 7. 存储资源与系统设置

- 覆盖页面：`src/pages/panel/infra/database/`、`src/pages/panel/operations/settings/`。
- 存储视图统一与去套框：`infra/database/index.tsx` 为 `<Tabs>` 包裹无边框圆角白底主 Card；`StorageResourceHeader` 在无右侧动作时隐藏冗余重复标题（仅 `数据库实例` 保留右侧 `+ 新建数据库实例` 动作条），3 个 Tab 内 `<ProTable>` 统一关闭 `cardBordered` 与外边框（保持 `<ProTable<...> size="small"` 顺序契约）。
- 系统设置三页签化：`operations/settings/index.tsx` 收口为统一主 Card + 三页签（`品牌与外观` / `会话安全` / `日志保留策略`，与 `?tab=` 查询串双向同步）；`查看当前生效信息` 与 danger `清除全部覆盖` 一并收进右上角 `更多` `Dropdown`（点击打开 `<Drawer>` 或确认弹窗）；会话安全 `恢复继承` 弱化为 `type="link" danger` + `RollbackOutlined`；`LogRetentionSettings` 保持独立只读失败兜底与 `保存日志保留策略` 精准按钮文本。

## 8. 运营支持与内容管理

- 覆盖页面：`src/pages/panel/infra/file/`、`src/pages/panel/infra/catalog/`、`src/pages/panel/support/audit/`、`support/todos/`、`support/notification/`、`support/feedback/`。
- 面包屑激活态：`BreadcrumbNav` 将末尾当前路径（包括根目录 `/static`）渲染为 `<Typography.Text strong>`，避免无实际跳转效果的可点击链接样式；上层祖先节点保持可点击。
- 单主按钮分工：`infra/catalog` 左侧分类树主按钮明确为 `新建根分类`（T1），右侧列表新建按钮降级为次级并在选中子目录时显示 `新建子分类`；列表行动作与树右键菜单统一使用 `新建子分类` + `编辑` + `更多`（danger `删除` + `Modal.confirm`）并补全图标。
- 表格单层容器与通知隔离：`support/audit` 为 Tabs 内 `<ProTable>` 关闭边框与内边距；`support/notification` 行内 `查看` + `编辑` 直出并将 danger `删除` 收口进 `更多` `Dropdown` + `Modal.confirm`；`support/todos`、`support/feedback` 补齐图标并配统一 `cardProps` 无边框圆角阴影样式。

## 9. Workbench 应用与服务工作台

- 覆盖页面：`src/pages/workbench/apps/$appKey/`、`src/pages/workbench/services/$serviceID/`、`src/components/ApplicationPageRenderer/`、`src/components/service-debugger/`、`src/app.tsx`（`WorkbenchTopNav` / `RightHeaderActions`）。
- 顶栏统一：`WorkbenchTopNav` 使用单枚浅蓝选中胶囊（`.magic-layout-portal-nav-item-active`）替代旧的实心主蓝按钮与“管理”文本按钮；右侧入口扩展支持 `workbench` 路由展示统一的 `门户` / `管理台` 胶囊开关。
- 服务工作台（`/workbench/services/:serviceID`）：`WorkbenchHeader` 通过 `meta` 承载调试模式与订阅状态/配额条；主体 `<Tabs>` 收口于单层无边框白底 `.serviceSurface` `<Card>`；`ServiceDebugger`、`ServiceAPIKeys`、`ServiceAccessGuide` 支持 `embedded` 无嵌套卡模式，HTTP 方法使用语义色 `<Tag>`，`轮换`/`撤销` 收敛为 T3 link 按钮，`发送请求`/`下载接口合同`/`下载 OpenAPI`/`创建 API Key` 保持精准按钮文本。
- 应用工作台（`/workbench/apps/:appKey`）：`InstalledApplicationPages` 补齐统一 `WorkbenchHeader`（应用名/描述/Key 标签/返回按钮）；`PageApplicationNavigation` 顶栏与树形目录对齐无边框圆角阴影并去掉实心主蓝选中按钮以礼让页面内 T1 `新建` 主 CTA；`PageDirectoryRecords`/`PageRecordHistory`/`PageSelectedDetail`/`EntityBusinessActions`/`EntityBusinessWrites`/`EntityListPage` 统一行内 T3 动作、分页右对齐与语义图标，保留 `frame.borderWidth`/`frame.bordered` 显式作者覆写契约及 `业务操作`/`刷新业务记录`/`重新加载应用` 测试锚点。
  - 字段分类显示与单值写入：`PageFieldValue` 支持 `display`（`tag`/`badge`/`boolean-switch`/`progress`/`link`/`code`/`datetime`/`relative-time`/`bytes`）、`format`、`copyable`、`emptyText`、`thousandSeparator`、`maxTagCount`、`booleanLabels`、`thresholds` 与 `inlineEdit`（非主键/非只读标量字段经 `queryActionRecord` + `expectedVersion` + `submitBusinessWrite` + `assertBusinessWriteReceipt` 执行）；未配置扩展属性时保持轻量 `<span>`。
  - 筛选、目录动作与设计器同步：`PageSourceFilterForm` 支持 `string` `contains`、数值 `gte`/`lte` 区间、`filters.presets` 一键预设与可消除已激活筛选标签，保持 `启用...筛选` / `...筛选值` / `应用筛选` / `清除筛选` 锚点；`entity-directory` `actions` 作为 T3 `业务操作` 与 `查看详情`/`编辑` 并列（单行不超过 3 个）；`metric-group` 支持单项 `metrics.itemTones`；`PagePresentationEditor` 与 `PageDraftEditor` 与 `magic.application-ui/v1` 保持同步不递增协议版本。
