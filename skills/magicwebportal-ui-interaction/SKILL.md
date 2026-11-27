---
name: magicwebportal-ui-interaction
description: 用于规范和收口 magicWebPortal 的门户与管理台页面交互、按钮四级分层、功能块容器收口、响应式适配及 E2E/单测契约保护。当在 magicWebPortal 新增、修改或评审 portal/panel 页面、Card/Tabs/Modal/Table 布局、行内操作按钮、390px 移动端适配或顶栏空间切换组件时使用。
metadata:
  version: "1.0.0"
  author: "rangh"
  created_at: "2026-11-27T07:38:15+08:00"
---
# magicWebPortal 交互设计与页面收口规范

用于统一约束 `magicWebPortal` 的 Portal 门户与 Panel 管理台页面视觉容器、功能块结构、按钮四级分层、图标配对、390px 移动端排版，以及改动过程中对单元测试与 E2E 回归锚点的保护。

## 适用场景

- 在 `magicWebPortal/src/pages/portal` 或 `magicWebPortal/src/pages/panel` 新增页面、拆分标签页（Tabs）、重构表格/卡片列表或调整页面布局。
- 评审或收口页面按钮数量过多、多主按钮冲突、Card 套 Card、长文本清单撑破卡片或永久禁用按钮占位的页面缺陷。
- 调整顶栏入口（门户/管理台切换胶囊）、一体化“当前操作空间”切换面板或 390px 小屏布局适配。
- 配套同步 `magicWebPortal/src/__tests__/` 单元测试或 `magicTest/regression/` 浏览器用例。

## 壳层与文案基线

1. **导航与壳层**：
   - Portal 门户采用方案 C 顶部水平单行主导航，子页面通过 `<PortalTopNav />` 跳转，不额外加页内返回头或双导航条。
   - Panel 管理台采用方案 P1 扁平分组侧栏（移除手风琴折叠箭头与重复子组图标，按一级模块分组呈现）。
   - 顶栏右侧表面切换入口（`门户` / `管理台`）采用轻胶囊 pill 样式，桌面端图标+文案与右侧分割线分隔，移动端（`< 768px`）收敛为紧凑圆形图标按钮并隐藏冗余用户附属文本。
2. **空间上下文与文案**：
   - 将“切换空间”能力直接整合进 Panel 概览页头部一体化可点击的“当前操作空间”面板（原生 `<button>` + `NamespaceSwitchModal`），不单独堆砌第二个切换按钮。
   - 界面展示与提示文案统一使用 **“空间”**（如 `空间管理`、`目标空间`、`默认管理空间`），不再向用户暴露“租户空间”。

## 按钮四级分层原则（T1–T4）

| 层级 | 样式载体 | 单屏/单区配额 | 典型场景 |
| --- | --- | --- | --- |
| **T1 主 CTA** | `<Button type="primary">` | 每屏/每主卡最多 1 个 | `进入应用`、`新建应用定义`、`新建服务`、`配置服务`、`新建根分类`、`新建空间`、`提交工单`（工单子页） |
| **T2 轻强调次级动作** | 淡蓝描边或柔和默认按钮（`#f0f6ff` / `#91caff` / `#1677ff` 或 default Button） | 1–2 个 | 门户首页/列表中的 `进入服务`、`申请`/`重新申请`、卡片右上角 `提交工单`、`刷新`、`导入 ZIP` |
| **T3 行内文字链** | `<Button type="link">` / `<Button type="text">` | 每行直接展示 **不超过 2–3 个** | `查看`、`安装详情`、`编辑`、`访问分配`、`去处理`、`查看详情`、`查看回复` |
| **T4 折叠菜单与危险隔离** | `<Dropdown trigger={['click']}>`（触发器 `更多` `MoreOutlined`） | 其余低频操作与破坏性操作统一收口 | `API Key`、`发布`/`停用`、`开放`/`关闭订阅`、`升级`、`核对原操作`、`清除全部覆盖`；danger 操作（`删除`/`取消订阅`/`卸载`）置于分割线后并强制二次确认 |

**硬性禁止项**：
- 同屏或同一列表项中不得同时存在超过 1 个实心蓝主按钮。
- 不得用永久 `disabled` 的“死按钮”长期占位（如内置 `panel` 空间的 `同步入口` 和 `删除` 按钮应直接隐藏，以只读文本 `内置空间` 说明原因）。
- 所有功能按钮必须配齐语义一致的 `@ant-design/icons` 图标，不留无图标孤立按钮，也不强加会导致 E2E `exact: true` 名称校验失配的无障碍污染文本。

## 功能块与容器收口规则

1. **统一主容器**：单页功能块统一使用无边框圆角白底主 `<Card bordered={false} size="small" style={{ borderRadius: 'var(--magic-surface-radius)', boxShadow: 'var(--magic-surface-shadow)' }}>`（`ProTable` 通过 `cardBordered={false}` 与 `cardProps` 配置同等样式）。
2. **禁止 Card 套 Card**：严禁在主 `<Card>` 或 `<Tabs>` 的 `children` 中再嵌套带边框阴影的 `<Card>`；内嵌组件（如 `ArtifactDeploymentPanels`、`PackagedUninstallReviews`、`RuntimePlacementTasks`、`Audit` 内嵌 `ProTable`）需去掉内框与多余水平内边距。
3. **同源合并与 Tabs 分层**：
   - 搜索框、筛选器与刷新按钮合并入主 `<Card>` 的 `extra` 或 `Tabs` `tabBarExtraContent`，不再单独切出一条“头部搜索 Card”。
   - 同属一个业务主题的多张表格或配置板块（如部署审批、部署任务、发布治理与能力目录、系统设置三大块、存储资源三类视图）收敛为同一主 Card 内的扁平 `<Tabs>`，并用 URL `?tab=` 保持刷新直达。
4. **低频只读信息与长列表收口**：
   - 长只读生效配置明细（如 `系统设置 -> 当前生效信息`）收进右侧 `<Drawer>` 按需打开。
   - 数十项能力绑定清单不以长文本流平铺，收敛为单行可点击展开切换的 `<Tag>` 摘要。
   - 卡片网格空态使用 `<Empty>` 指引右上角主 CTA，禁止渲染巨型虚线 `+ 新建...` 占位卡。
   - 同源新建入口（如 `问题反馈` + `功能需求`）合并为单按钮并在 Modal 内通过 `Radio.Group` 切换类型。

## 移动端 390px 响应式红线

- 门户 `List.Item`（如 `.serviceListItem`、`.sideListItem`）在窄屏（`<= 767px` / `<= 575px`）必须设置 `flex-direction: column; align-items: stretch;`，并强制覆盖 AntD v5 逻辑属性 `.ant-list-item-action { margin-inline-start: 0 !important; width: 100%; }` 与 `.ant-list-item-meta { width: 100%; min-width: 0; }`，防止右侧操作按钮把标题/描述列挤成“单字竖排”。
- 表格固定开启 `tableLayout="fixed"` 并为次要时间/UUID/标识列设置 `responsive` 断点，禁止出现横向页面溢出（`scrollWidth <= innerWidth`）。

## 实施流程与契约保护

1. 修改前对照 [8 大页面群收口对照清单](references/page-group-checklist.md) 锁定目标页面与组件边界，并搜索 `magicWebPortal/src/__tests__/` 与 `magicTest/regression/` 确认受影响契约锚点：
   - 关键精准按钮/文本锚点：`安装详情`（内联可见）、`配置服务`、`保存日志保留策略`、`查看全部 (N)`、`查看`、`进入服务`、`去处理`（需通过 `aria-label="去处理"` 与 icon `aria-hidden="true"` 保持无障碍名称精确一致）、`[aria-label="编辑空间"]`、`[aria-label="删除空间"]`、`<Link to="..."><Button ...>模型包管理</Button></Link>`。
2. 当操作被折叠进 `<Dropdown>` 或块被移入 `<Tabs>` 导致原有测试直接查询不到 DOM 时，严禁悄悄删测试，必须同步更新对应单测或 E2E（例如先打开 `[role=tab]` 或点击 `[aria-label="更多..."]` 后再点击对应菜单项）。
3. 完成编辑后按顺序执行下方验证。

## Formatter

- `magicWebPortal` 前端代码（`.ts`、`.tsx`、`.less`、`.js`）：
  ```bash
  export PATH="/home/rangh/.nvm/versions/node/v20.19.3/bin:$PATH"
  cd /home/rangh/codespace/magicWebPortal
  npx prettier --write <changed-files>
  yarn test
  yarn build
  ```
- 若同步修改了 `magicTest/regression/*.cjs`，必须运行语法检查及受影响离线单测：
  ```bash
  export PATH="/home/rangh/.nvm/versions/node/v20.19.3/bin:$PATH"
  node --check <changed-cjs-files>
  ```
- `SKILL.md` 与 `references/*.md` 保持标题层级、表格对齐与相对链接有效；归档前从 `/home/rangh/codespace` 运行 `skill-hub validate magicwebportal-ui-interaction --links`。

## 输出要求

- 按“修改页面/组件 → 同步的测试/E2E 契约 → Prettier / `yarn test` / `yarn build` / `skill-hub validate` 实测输出”逐项报告。
- 明确列出 skill-hub 校验和本地归档结果；除非用户明确指示，严禁私自 `git commit`、`git push` 或 `skill-hub push`。

## 注意事项

- 不要在 `Portal` 或 `Panel` 页面重新引入“租户空间”字样。
- 折叠危险操作至 `更多` 后，`onOk` 仍须走原有的防御性确认、版本并发检查与错误提示链路，不可跳过 `Modal.confirm`。
- 检查 `deployment-table-layout.test.ts` 与 `ArtifactDeploymentPanels.tsx` 的契约限制（例如无参数 `<Space>` 禁止检查、`tableLayout="fixed"` 强制检查）。
