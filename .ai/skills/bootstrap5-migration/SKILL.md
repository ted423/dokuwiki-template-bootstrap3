---
name: "bootstrap5-migration"
description: "指导本 DokuWiki 模板从 Bootstrap 3 渐进迁移到 Bootstrap 5。当用户询问 BS5 升级可行性、迁移计划、类名映射、共存策略，或要求执行具体迁移步骤时调用。"
---

# Bootstrap 3 → 5 渐进迁移指南

## 何时使用

- 评估升级 Bootstrap 5 的可行性或工作量
- 制定/执行迁移计划（类名替换、组件重写、插件适配）
- 讨论 BS3 与 BS5 共存方案

## 项目关键事实

- 当前 Bootstrap **3.4.1**，资产位于 `assets/bootstrap/`：17 套 Bootswatch 3 主题（每主题一个目录，内含 `bootstrap.min.css`）+ Glyphicons 字体（`assets/bootstrap/fonts/`）+ `js/bootstrap.min.js`
- jQuery 由 **DokuWiki 核心自带**，BS5 迁移不要求移除 jQuery
- 共存先例：`css/bs4-utilities.less`（BS3 核心 + BS4 风格工具类混用），模板中已有 `mx-5`、`pb-5`、`d-flex` 等用法
- 图标体系已部分迁移到 **Iconify**（`assets/iconify/`，含 MDI 图标），迁移 Glyphicons 时优先复用
- 插件适配层：JS 在 `js/plugins/`、样式在 `css/plugins/`，逐文件对应一个 DokuWiki 插件
- 搜索补全：`assets/typeahead/bootstrap3-typeahead.min.js`（jQuery 插件，已停止维护，需替代方案）
- 核心文件：`main.php`、`detail.php`、`mediamanager.php`、`Template.php`（PHP 生成标记）、`tpl/`（17 个子模板，navbar.php 最复杂）、`script.js`（含 jQuery UI → BS3 的类名映射逻辑）

## 升级评估流程

1. 扫描 BS3 特有类名：`panel`、`label label-*`、`navbar-toggle`、`icon-bar`、`glyphicons`、`btn-default`、`btn-xs`、`hidden-*`、`visible-*`、`pull-right`、`data-toggle`、`data-target`、`data-dismiss`
2. 统计 JS 插件调用：`affix`（BS5 已删除）、`scrollspy`、`collapse`、`tooltip`、`popover`、`modal`、`tab`、`dropdown`
3. 盘点资产：主题目录数、Glyphicons 引用点、typeahead、jQuery UI 映射
4. 盘点插件：`js/plugins/` 与 `css/plugins/` 文件清单，标注各自依赖的 BS3 类

## BS3 → BS5 类名映射速查表

| Bootstrap 3 | Bootstrap 5 | 说明 |
|---|---|---|
| `panel` / `panel-default` | `card` | 子结构：`panel-heading`→`card-header`、`panel-body`→`card-body`、`panel-title`→`card-title` |
| `label label-*` | `badge bg-*` | 语义变化：BS3 的 `badge`（计数器）≈ BS5 的 `badge` 圆角样式 |
| `btn-default` | `btn-secondary` | |
| `btn-xs` | `btn-sm` | BS5 无 xs 尺寸 |
| `navbar-toggle` | `navbar-toggler` | |
| `icon-bar` ×3 | 自定义 SVG / `.navbar-toggler-icon` | |
| `navbar-right` | `ms-auto` | |
| `navbar-fixed-top` | `fixed-top` | |
| `navbar-inverse` / `navbar-default` | `navbar-dark` / `navbar-light` + `bg-*` | 反色逻辑变化 |
| `hidden-xs` 等 | `d-none d-sm-block` 等 | 响应式可见性体系重做 |
| `visible-xs-block` 等 | `d-block d-sm-none` 等 | `script.js` 的 mediaSize 检测依赖这组类 |
| `hidden-print` | `d-print-none` | |
| `pull-right` / `pull-left` | `float-end` / `float-start` | |
| `ml-*` / `mr-*` / `pl-*` / `pr-*` | `ms-*` / `me-*` / `ps-*` / `pe-*` | BS5 改用逻辑属性 |
| `text-right` / `text-left` | `text-end` / `text-start` | |
| `form-inline` | 移除，用 flex 工具类 | |
| `control-label` | `form-label` | |
| `input-sm` | `form-control-sm` | |
| `table-condensed` | `table-sm` | |
| `col-xs-*` | `col-*` | xs 成为默认断点前缀 |
| `data-toggle` / `data-target` / `data-dismiss` | `data-bs-toggle` / `data-bs-target` / `data-bs-dismiss` | 所有 JS 插件属性加 `bs-` 前缀 |
| `glyphicon glyphicon-*` | 无（用 Iconify/SVG） | 本项目用 `iconify('mdi:...')` |
| affix 插件 | 移除，用 CSS `position: sticky` | TOC/PageTools 固定定位 |
| `.in`（collapse 展开态） | `.show` | |
| `.active`（tab/nav） | 保留，但 tab 结构有变化 | `data-toggle="tab"` → `data-bs-toggle="tab"` |

## 共存策略（四阶段渐进迁移）

**核心原则：JS 和工具类可随时叠加；标记提前双写；基础 CSS 与主题的切换是唯一原子操作。绝不能双载两份完整 bootstrap.css。**

### Phase 0 — 纯清理（BS3 下零风险）
- Glyphicons → Iconify
- affix → CSS `position: sticky`
- 删除 IE9 shim（html5shiv/respond.js）

### Phase 1 — 引入 BS5 模块（只加不删）
- 用 Sass 构建部分版 BS5：仅 utilities + card（无同名冲突的模块）
- 或扩展 `css/bs4-utilities.less` 为 BS5 版
- 新增标记一律用 BS5 风格

### Phase 2 — 标记预迁移（BS3 下保持可渲染）
- **data 属性双写**：`data-toggle="dropdown" data-bs-toggle="dropdown"`——BS3 认前者、BS5 认后者，切换时刻无需再改 HTML。适用 dropdown / collapse / modal / tab
- panel→card、label→badge：先加临时垫片 CSS，再逐模板替换
- navbar 结构改造（`navbar-toggler` 等）配自定义 CSS 垫片

### Phase 3 — 切换时刻（原子操作）
- 一次性替换 `bootstrap.min.css` + 全部 Bootswatch 主题（17 套不能换一半）
- 加载 BS5 JS，暂时保留 BS3 JS 兜底
- 集中回归测试：主页、详情页、媒体管理器、主题切换、侧栏、TOC、插件页、打印、移动端

### Phase 4 — 收尾
- 移除 BS3 JS、清理双写的旧 data 属性、删垫片 CSS
- 替换 typeahead（候选：Algolia autocomplete / Tribute.js / 原生 dropdown 自实现）

## 冲突红线

- ❌ 双载完整 BS3 + BS5 CSS：同名类（`.btn`、`.navbar`、`.dropdown-menu`、`.modal`、`.row`、`.col-*`、`.form-control`）会全局互相覆盖
- ❌ Bootswatch 主题半量替换：基础 CSS 与主题必须同步切
- ⚠️ Bootstrap Wrapper、tabbox、wrap 等插件自身输出 BS3 标记，模板改完后仍需逐插件适配

## 输出约定

- 执行迁移改动时，每个 Phase 独立提交，保证中间状态可上线
- 汇报时按「已改文件 → 改动类型 → 验证方式」格式输出
