---
name: "dokuwiki-form-overrides"
description: "覆盖 DokuWiki 核心表单与后台页面样式的经验：核心标记结构、与 Bootstrap 的冲突点、template.less 覆盖套路（登录框、注册、扩展管理器手动安装）。当需要调整核心生成表单的布局，或排查核心样式不生效、选择器不命中时调用。"
---

# DokuWiki 表单与后台页面样式覆盖

本模板只做样式覆盖，**不改 DokuWiki 核心**。核心表单的标记和样式由 DokuWiki 生成，与 Bootstrap 的默认假设冲突，几乎所有表单布局问题都源于此。

## 何时使用

- 调整核心生成的表单布局：登录、注册、重设密码、订阅、扩展管理器手动安装等
- 覆盖写在 `css/core/_forms.css` 里的核心样式
- 排查"样式写了但没生效"——多半是选择器没命中真实标记

## 需求 / 验收标准

改动前先对照本节。以下要求对**登录框**与**扩展管理器手动安装表单**同样适用：

- 标签文字在输入框**上方、靠左**；不要「文字与输入框并排」，也不要核心默认的**右对齐 + 加粗**
- 输入框**满格**；同一表单内多行输入框**必须等宽、左右边缘对齐**
- 表单块**居中**，不靠左
- 勾选框与提交按钮**各自独立成行、靠右**，按钮不得与勾选框并排
- 勾选框与按钮**不得超出输入框右边缘**，要与输入框右缘**齐平**
- 宽度随视口自适应，小屏不溢出；标签与输入框**不得出现意外换行**，需留足宽度兜底

表单特有的附加项：

- **登录框**：标题（`legend`）居中，且**标题下的横线要占满整宽**（曾被压成一小截）
- **注册 / 重设密码**：字段排布同上，整体居中
- **扩展管理器手动安装**：与上述通用要求一致，无附加项

通用约定：

- 各表单样式**互不牵连**：改登录框不能影响注册/扩展管理器
- 只做 CSS 覆盖，**不改核心 PHP、不在 `EventHandlers.php` 里重排元素**

> 本 skill 不固定具体宽度值：宽度按需调整，只要求"随视口自适应、不溢出、不意外换行"。

## 项目关键事实

- 样式加载顺序：`style.ini` 里 `css/core/*` 在前、`css/template.less` 在后，所以模板能覆盖核心
- 本仓库**不含 DokuWiki 核心**，本地无法渲染后台页，别指望起服务看效果
- 运行时用 DokuWiki 自带的 **less.php** 编译，不是 less.js，语法兼容性更保守
- 核心 PHP 生成标记在 `inc/`，插件后台标记在 `lib/plugins/<插件>/Gui*.php`

## 核心表单的真实标记（头号坑）

### 旧 API（登录 / 注册 / 重设密码）

核心 PHP 用 `form_makeTextField()` 一类函数生成，**输入框带 `edit` 类**：

```html
<form id="dw__login">
  <fieldset>
    <legend>登录</legend>
    <label class="block"><span>用户名</span><input class="edit"></label>
    <label class="block"><span>密码</span><input class="edit" type="password"></label>
    <label class="block" for="remember__me"><span>记住我</span><input type="checkbox" id="remember__me"></label>
    <button type="submit" class="button">登录</button>
  </fieldset>
</form>
```

依据：核心 `_forms.css` 用 `.dokuwiki label.block input.edit` 和 `#dw__login label[for="remember__me"]` 定位，且按这两个选择器写的覆盖确实生效。

### 新 Form API（插件后台，如扩展管理器）

`dokuwiki\Form\Form` 生成，与旧 API **不一样**：

- `addTextInput($name, $label)` → `InputElement('text', ...)`，**不会加 `edit` 类**，只有显式 `addClass()` 加的类
- `InputElement::addClass()` 会把类**同时加到 `<label>` 和 `<input>`** 上
- `addCheckbox()` → `CheckableElement`，自带 `checkbox` 类
- 表单本身会被追加 `doku_form` 类

扩展管理器「手动安装」的实际标记：

```html
<form class="install doku_form" enctype="multipart/form-data">
  <div class="no">
    <label class="block"><span>从 URL 安装</span><input name="installurl" type="url" class="block"></label>
    <br>
    <label class="block"><span>上传扩展包</span><input name="installfile" type="file" class="block"></label>
    <br>
    <label class="block"><span>覆盖</span><input name="overwrite" type="checkbox" class="checkbox block"></label>
    <br>
    <button type="submit" class="button">安装</button>
  </div>
</form>
```

> **用 `input.edit` 写覆盖会全部落空**：输入框退回浏览器默认宽度（文件框天然比文本框宽），表现为「两行输入框左右不齐」「按钮/勾选框超出输入框右边缘」。按元素或 `type` 匹配：`label.block input`。

## 核心样式冲突点（`css/core/_forms.css`）

| 核心规则 | 影响 |
|---|---|
| `.dokuwiki form { display: inline }` | 要居中/限宽必须显式 `display: block` |
| `.dokuwiki fieldset { width: 400px; text-align: center; margin: auto }` | 固定宽度 + 强制居中 |
| `.dokuwiki label.block { display: block; text-align: right; font-weight: bold }` | 标签文字右对齐 + 加粗 |
| `.dokuwiki label.block select, .dokuwiki label.block input.edit { width: 50% }` | 输入框半宽 |
| `#dw__login label[for="remember__me"] { margin-left: 50% }` | 勾选框被推到中间 |

模板侧 `css/template.less` 另有 `.dokuwiki fieldset { border: none }`，已去掉核心的边框。

## 覆盖套路

### 约定

- 统一写在 `css/template.less`，按页面/组件分区并加注释
- 每个表单**独立成块，不要合并成共享选择器**（登录、注册、扩展管理器各一块），否则改一处会波及别的表单
- 选择器带 `#dw__login`、`#extension__manager form.install` 这类 id/页面前缀，天然压过 `.dokuwiki ...`，不必堆 `!important`

### 通用片段

```less
/* 表单块：居中 + 限宽（宽度值按需，不写死） */
display: block;              /* 压过核心的 form { display: inline } */
width: 100%;
max-width: <按需>;
margin: 1em auto !important;

/* 输入框满宽，并把标签文字挤到上一行 */
/* <span> 保持 inline 即可，靠 input 的 display:block 换行，无需给 span 设 display:block */
label.block input {
  display: block;
  width: 100% !important;
}

/* 勾选框 / 提交按钮右对齐 */
text-align: right;                 /* 表单级：让孤立的 submit 落到右侧 */
label.block { text-align: left; }  /* 标签文字仍靠左 */
label.block:last-of-type { text-align: right; }  /* 最后一个 label（勾选框）右对齐 */
label.block input[type="checkbox"] {
  display: inline-block;
  width: auto !important;
  margin: 0 0 0 0.5em;
}
```

### 要点

- **避开 `:has()`**：less.php 对它的支持不确定，解析失败会拖垮整份样式表。用 `:last-of-type`、属性选择器等稳妥写法
- **避开 `clamp()` / `min()` / `max()`**：响应式宽度用 `min-width` + `max-width` + `vw` 组合
- 勾选框的尺寸复位靠 `input[type="checkbox"]`（属性选择器计入优先级，能压过 `label.block input`）
- Bootstrap 3 有全局 `* { box-sizing: border-box }`，所以 `width: 100%` 的输入框右边缘正好等于容器右边缘，右对齐的按钮会与之齐平
- 字段全变块级后，标记里那些 `<br>` 只会多出空行，可 `form.xxx br { display: none }` 清掉
- Bootstrap 会给 `<legend>` 加下划线：想让标题居中同时下划线占满整宽，设 `legend { text-align: center; width: 100%; margin: 0 0 .75em }`

## 三个已落地的变体

### 1. 登录框（`#dw__login`）

```less
#dw__login {
  display: block !important;
  width: 100%;
  /* 宽度随视口自适应：留一个下限兜底、一个上限封顶，具体值按需调整 */
  margin: 2em auto !important;
  text-align: left;

  fieldset {
    display: block;
    width: 100% !important;
    max-width: none;
    margin: 0 auto !important;
    text-align: right;   /* 勾选框与按钮靠右 */
    padding: 1em 1.25em 1.25em;
  }
  legend { text-align: center; width: 100%; margin: 0 0 0.75em; }
  label.block { display: block; width: 100%; text-align: left; margin-bottom: 0.75em; }
  label.block input.edit { display: block; width: 100%; margin: 0; text-align: left; }
  label[for="remember__me"] { display: block; width: 100%; margin-left: 0 !important; margin-bottom: 1em; text-align: right; }
  [type="submit"], button[type="submit"] { display: inline-block; margin: 0.5em 0 0 !important; float: none !important; }
}
```

### 2. 注册 / 重设密码（`#dw__register`、`#dw__resendpwd`）

同一套结构，但整体**居中**：表单与 `fieldset` 用 `margin: 0 auto`，`label.block` 与输入框用 `text-align: center` / `margin: 0 auto`，输入框收窄并居中。

### 3. 扩展管理器手动安装（`#extension__manager form.install`）

沿用登录框的排布（同一套"标签在上靠左、输入框满格、勾选框与按钮靠右齐平"的规则），差异只有两点：

- 选择器前缀换成 `#extension__manager form.install`
- 输入框**按元素匹配**（`label.block input`），因为新 Form API 没有 `edit` 类

## 踩过的坑与红线

- ❌ **用 PHP 重排表单元素**：曾改 `EventHandlers.php` 的 `formLoginOutput` 去挪动 checkbox/按钮，索引算错导致勾选框插到按钮后面、按钮上移。**布局问题一律用 CSS 解决**
- ❌ **改 `template.less` 前不重读文件**：文件可能已被改动，`Edit` 会报 "String to replace not found"。每次编辑前先读最新内容
- ❌ **`:has()` / `clamp()`**：less.php 编译风险，见上
- ❌ **把多个表单合并到一个选择器**：会互相牵连，回归面变大
- ⚠️ 改完要提醒用户清 DokuWiki 的 CSS 缓存，否则浏览器里看不到变化

## 验证方法

- 本仓库无核心源码，**无法本地渲染**，改动靠选择器推演 + 核心源码核对
- 查核心/插件真实标记：`WebFetch` 拉官方源码
  - `https://raw.githubusercontent.com/dokuwiki/dokuwiki/master/inc/Form/Form.php`
  - `https://raw.githubusercontent.com/dokuwiki/dokuwiki/master/inc/Form/InputElement.php`
  - `https://raw.githubusercontent.com/dokuwiki/dokuwiki/master/lib/plugins/<插件>/Gui*.php`
- LESS 语法自检：`template.less` 大括号配平即可——`([regex]::Matches($c,'\{')).Count` 与 `\}` 计数相等。离线环境 `npx lessc` 不可用
- 优先级自检：属性选择器与类选择器都计入「类」这一档，`input[type="checkbox"]` 与 `input.edit` 同权重，靠**书写顺序**决出胜负；要稳就再加一层前缀

## 相关文件

- `css/template.less` —— 所有覆盖的落点
- `css/core/_forms.css` —— 需要对抗的核心表单样式
- `style.ini` —— 样式加载顺序（核心在前，模板在后）
- `EventHandlers.php` —— **不要**在这里改表单结构