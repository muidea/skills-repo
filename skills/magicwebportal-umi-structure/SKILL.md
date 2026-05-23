---
name: magicwebportal-umi-structure
description: 用于调整或评审 magicWebPortal 的 Umi Max 前端目录结构、页面私有组件归属、跨页面 service 边界和菜单层级落点。涉及 src/pages、src/components、src/services、.umirc.ts routes、panel/portal/workbench 页面组织或清理 features/components 旧目录时使用。
metadata:
  version: "1.0.0"
  author: "rangh"
  created_at: "2026-05-02T09:01:21+08:00"
---
# magicWebPortal Umi Max 目录归属

用于在 `magicWebPortal` 中处理 Umi Max 页面、组件、service 和菜单层级目录治理。目标是让代码落点与业务功能所属关系一致，同时保持路由 URL、API URL 和模型名稳定可验证。

## 适用场景

- 用户要求整理 `magicWebPortal` 代码结构、按菜单层级收拢页面、迁移 `component` / `service`、清理 `features` 或旧目录。
- 修改 `.umirc.ts` 路由组件路径、`src/pages` 页面目录、`src/components` 公共组件边界、`src/services` API 封装边界。
- 排查 Umi Max 因目录迁移导致的构建失败、`useModel` 失效、测试 import 失效或业务 URL 被误改。

## 核心原则

- `src/pages` 按菜单层级和功能所属关系组织，不按技术层或笼统 `features` 分组。
- 页面私有 UI、hooks、types、utils 放在对应页面或功能目录的 `components/` 内。
- 同一业务域内多页面共享内容放在该域的 `shared/`、`types/` 或上层稳定目录，不要放回全局 `src/components`。
- 只有跨 panel、portal、workbench 或跨多个业务域复用的组件才放 `src/components`。
- 只有跨页面或跨入口复用的 API service 才放 `src/services`；单页面私有 API 封装放页面本地 `service.ts`。
- 路由 URL 和 API URL 是业务契约，目录迁移时默认不能改。只允许改 `.umirc.ts` 的 `component` 指向。
- Umi model 名随 `src/pages` 路径变化；迁移含 `model.ts` 的页面时，必须同步检查所有显式 `useModel('<name>')`。
- 不创建空目录，不保留旧 alias 引用，不引入 `features` 这类已废弃组织方式。

## 目录落点

典型结构：

```text
src/pages/panel/
├── application/
│   ├── definition-publish/
│   │   ├── index.tsx
│   │   ├── definition/
│   │   │   ├── index.tsx
│   │   │   ├── model.ts
│   │   │   ├── service.ts
│   │   │   └── components/
│   │   ├── package/
│   │   └── release/
│   └── deployment/
│       ├── index.tsx
│       ├── model.ts
│       ├── service.ts
│       └── components/
├── cas/
│   ├── namespace/
│   ├── access/
│   │   ├── account/
│   │   ├── role/
│   │   ├── endpoint/
│   │   ├── registration/
│   │   └── shared/
│   ├── types/
│   └── utils.ts
└── components/
    └── dashboard/
```

菜单层级示例：

```text
认证授权
├── 租户空间
└── 访问管理
    ├── 账号
    ├── 接入角色
    ├── 接入端点
    └── 注册管理
```

上述示例对应：

```text
src/pages/panel/cas/namespace/
src/pages/panel/cas/access/account/
src/pages/panel/cas/access/role/
src/pages/panel/cas/access/endpoint/
src/pages/panel/cas/access/registration/
```

## 工作流程

1. 先读取 `.umirc.ts`、`src/utils/panelMenu.ts` 和目标 `src/pages` 目录，确认业务菜单、路由 URL、页面组件路径三者关系。
2. 识别文件归属：单页面私有、同菜单功能簇共享、业务域共享、全局共享、跨入口 API service。
3. 先移动页面和私有组件，再修正 import；不要先做粗暴全局替换。
4. 迁移 `model.ts` 时同步修正显式 `useModel` 名称；动态拼接的 model 名要确认常量来源不依赖错误的私有目录。
5. 迁移 service 时先查引用。被多个页面或 workbench/portal/panel 跨入口共用的 service 保留在 `src/services`。
6. 清理旧目录和空目录，更新相关文档中的旧路径。
7. 验证构建、测试和路径扫描。

## 验证清单

在 `magicWebPortal` 下至少执行：

```bash
rg -n "@/components/(panel|portal|workbench)|src/components/(panel|portal|workbench)|@/features|src/features|apps//components" src .umirc.ts
git diff --check
yarn build
```

按改动范围补充测试：

```bash
yarn test src/__tests__/panel-menu.test.ts
yarn test src/__tests__/portal-display.test.ts
yarn test src/__tests__/apps-utils.test.ts
```

必要时检查路由组件和显式 model 名：

```bash
node -e "const fs=require('fs'); const path=require('path'); const config=fs.readFileSync('.umirc.ts','utf8'); const re=/component:\\s*'([^']+)'/g; let m, miss=[]; while((m=re.exec(config))){ let comp=m[1]; let p=comp.startsWith('./') ? path.join('src/pages', comp.slice(2)) : comp.replace(/^@\\//,'src/'); const candidates=[p,p+'.tsx',p+'.ts',path.join(p,'index.tsx'),path.join(p,'index.ts')]; if(!candidates.some(fs.existsSync)) miss.push(comp); } if(miss.length){ console.error(miss.join('\\n')); process.exit(1)} console.log('route components ok')"
```

## Formatter

- `SKILL.md` / Markdown / YAML: 保持标题、列表和代码块格式稳定；归档前运行 `skill-hub validate magicwebportal-umi-structure --links`。
- `scripts/`: 当前模板未包含脚本；新增 Go/Python/JavaScript/TypeScript/Shell 等脚本时，必须在本段补充项目可运行的具体 formatter 命令。
- 常见 formatter 示例：Go 使用 `gofmt -w <files>`，Python 优先使用仓库已有的 `ruff format <files>` 或 `black <files>`，JavaScript/TypeScript 优先使用仓库已有的 `npm run format` 或 `prettier`，Shell 优先使用仓库已有 formatter 或语法检查。
- 不要声明当前项目无法执行的 formatter；如果对应文件类型没有 formatter，明确写出人工格式要求。

## 输出要求

- 明确说明迁移后的目录边界：哪些内容进入页面私有目录，哪些内容保留为全局共享。
- 明确说明业务 URL/API URL 是否保持不变。
- 给出已运行的测试、构建和路径扫描结果。
- 如果调整了目录规则或文档，按需运行 `skill-hub validate magicwebportal-umi-structure --links`，并在用户要求同步时执行 `skill-hub feedback magicwebportal-umi-structure --force`。

## 注意事项

- 不要为了“收拢”把跨入口 service 放进某个页面私有目录。
- 不要把 `src/pages/.../components` 当成路由入口；`.umirc.ts` 的 `conventionRoutes.exclude` 必须继续排除 `/components/`、`model.ts`、`service.ts`、`types.ts`、`utils.ts` 等非页面文件。
- 不要把内部目录名泄漏到业务 URL，例如目录可用 `definition-publish`，但 route 仍可保持 `/panel/application/workspace/`、`/panel/application/definition/`。
- 不要保留旧 `src/features` 或 `@/components/panel|portal|workbench` 业务引用。
- 迁移包含 `$appKey`、`$serviceID` 的路径时，shell 命令必须正确引用字面量 `$`，避免变量展开成空字符串。
