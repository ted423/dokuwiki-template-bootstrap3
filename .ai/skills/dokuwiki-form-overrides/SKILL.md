---
name: "dokuwiki-form-overrides"
description: "覆盖 DokuWiki 核心表单与后台页面样式的经验：核心标记结构、与 Bootstrap 的冲突点、template.less 覆盖套路（登录框、注册、重设密码、资料更新、扩展管理器手动安装），以及一条对齐判据——带勾选框的表单按钮靠右、不带勾选框的表单按钮居中。当需要调整核心生成表单的布局，或排查核心样式不生效、选择器不命中时调用。"
---

# DokuWiki 表单与后台页面样式覆盖

本模板只做样式覆盖，**不改 DokuWiki 核心**。核心表单的标记和样式由 DokuWiki 生成，与 Bootstrap 的默认假设冲突，几乎所有表单布局问题都源于此。

## 何时使用

- 调整核心生成的表单布局：登录、注册、重设密码、资料更新（含认证令牌 / 删除账号）、订阅、扩展管理器手动安装等
- 覆盖写在 `css/core/_forms.css` 里的核心样式
- 排查"样式写了但没生效"——多半是选择器没命中真实标记

## 需求 / 验收标准

改动前先对照本节。以下要求对**登录框**、**注册 / 重设密码 / 资料更新**与**扩展管理器手动安装表单**同样适用：

- 标签文字在输入框**上方、靠左**；不要「文字与输入框并排」，也不要核心默认的**右对齐 + 加粗**
- 输入框**满格**；同一表单内多行输入框**必须等宽、左右边缘对齐**
- 表单块**居中**，不靠左
- 勾选框与提交按钮**各自独立成行**，按钮不得与勾选框并排
- **按钮对齐分两派，判据是"这个表单有没有勾选框"**：
  - **带勾选框**的表单（登录框、扩展管理器手动安装）→ 勾选框与按钮各自成行、**靠右**，且与输入框右缘**齐平**
  - **不带勾选框**的表单（注册 / 重设密码 / 资料更新）→ 按钮**居中**（用户明确指定：这三个页面"按钮保持在中部"）
- 同一行的多个按钮要**尺寸一致、间距均匀、整组居中（或整组齐平）**；按钮自带 `mr-2`、或其中一个按钮带图标，都会破坏这一点，见下
- 宽度随视口自适应，小屏不溢出；标签与输入框**不得出现意外换行**，需留足宽度兜底

表单特有的附加项：

- **登录框**：标题（`legend`）居中，且**标题下的横线要占满整宽**（曾被压成一小截）
- **注册 / 重设密码 / 资料更新**：字段排布同上（标签靠左、输入框满格），表单块整体居中；这三个页面**都没有勾选框，所以按钮居中**
- **扩展管理器手动安装**：与上述通用要求一致，无附加项

通用约定：

- 各表单样式**互不牵连**：改登录框不能影响注册/扩展管理器
- ⚠️ 但 `#dw__register` 是**注册页与资料更新页共用**的 id（核心 `UserProfile::updateProfileForm()` 写的就是 `new Form(['id' => 'dw__register'])`），动它要同时回归两页
- 只做 CSS 覆盖，**不改核心 PHP、不在 `EventHandlers.php` 里重排元素**

> 本 skill 不固定具体宽度值：宽度按需调整，只要求"随视口自适应、不溢出、不意外换行"。

## 项目关键事实

- 样式加载顺序：`style.ini` 里 `css/core/*` 在前、`css/template.less` 在后，所以模板能覆盖核心
- 本仓库**不含 DokuWiki 核心**，本地无法渲染后台页，别指望起服务看效果
- 运行时用 DokuWiki 自带的 **less.php** 编译，不是 less.js，语法兼容性更保守
- 核心 PHP 生成标记在 `inc/`：auth 表单在 `inc/Ui/User*.php`，表单组件在 `inc/Form/*.php`；插件后台标记在 `lib/plugins/<插件>/Gui*.php`
- **标记会被二次加工，只读核心源码只能看到一半**：
  - PHP 侧 `Template::normalizeContent()`（`Template.php` 约 1467~1528 行）：给 `[type=button|submit|reset]` 追加 `btn btn-default`、给非按钮类 `input/select/textarea` 追加 `form-control`、给 `label` 追加 `control-label`、给**每个 form** 追加 `form-inline`
  - 服务端事件 `EventHandlers::commonStyles()`：给所有 button 型元素追加 `btn btn-default mr-2`
  - 浏览器侧 `script.js`（约 140~171 行）：`[data-dw-icon]` → 在该元素**内部** prepend 一个 `<span class="iconify mr-1">`；同一段还重复做一遍 `form-inline` / `control-label` 的追加
- 最常"压掉你刚写的宽度/间距"的是两条：`.mr-2` 的 `margin-right: .5rem !important`，以及 BS3 的 `.form-inline .form-control { width: auto }`（`@media (min-width:768px)`，优先级 **0-2-0**）

## 核心表单的真实标记（头号坑）

### auth 表单 = 新 Form API（`inc/Ui/User*.php`）

`UserLogin` / `UserRegister` / `UserResendPwd` / `UserProfile` 都用 `dokuwiki\Form\Form` 构建，**不是** `form_makeTextField()` 那套旧 API（旧 API 现在基本只在插件里出现）。

重设密码页的真实结构（`UserResendPwd`，请求重发密码这一形态）：

```html
<form id="dw__resendpwd" class="doku_form form-inline">
  <div class="no">
    <fieldset>
      <legend>重设密码</legend>
      <input type="hidden" name="do" value="resendpwd">
      <input type="hidden" name="save" value="1">
      <br>
      <label class="block">
      <span>用户名或邮箱</span>
      <input name="login" type="text" class="edit form-control" />
      </label>
      <br>
      <br>
      <button name="" value="1" type="submit" class="btn btn-default mr-2 btn-success">重设密码</button>
    </fieldset>
  </div>
</form>
```

同一页还有第二种形态（`autopasswd` 关闭且 URL 带有效 `pwauth` token 时）：`pass` / `passchk` 两个密码字段，**按钮仍然只有一个**。登录、注册、资料更新是同一套骨架，只是字段名不同。

要点：

- **`edit` 类不是自动加的**，是核心自己 `addClass('edit')` 加的（auth 表单加了，扩展管理器没加）。别把它当稳定契约。
- `InputElement::addClass()` 给 `<label>` 和 `<input>` **同时**加类，但 auth 表单紧接着 `getLabel()->attr('class', 'block')` 把 label 的类**覆盖**掉 —— 真实结果是 label 只有 `block`、input 只有 `edit`。
- 文本 / 密码字段的 `<span>` 在 `<input>` **之前**；`CheckableElement`（勾选框）**反过来：`<input>` 在前、`<span>` 在后**。`label.block span { display: block }` 这类规则在勾选框上会翻车。
- `CheckableElement` **没有自带 `checkbox` 类**（构造函数里只设 `value=1`），页面上的 `checkbox` 类是 `normalizeContent()` 补的。
- 核心在字段之间插 `<br>`（重设密码 1~3 处；资料更新每个字段后一处），字段块级化后只会变成空行 → `br { display: none }`。
- 字段普遍带 `size="50"`（≈400px），**宽度完全靠 CSS 压住**；选择器一旦落空就会撑破容器。
- **勾选框的有无决定按钮怎么对齐**：`#dw__login`（记住我）与 `#extension__manager form.install`（覆盖）带勾选框 → 靠右；`#dw__register` / `#dw__resendpwd`（注册、重设密码、资料更新）没有勾选框 → 居中。
- 按钮的 class 由三方叠加：核心没有默认类 → `commonStyles()` 加 `btn btn-default mr-2` → `formUpdateProfileOutput()` 之类再加 `btn-success` → `normalizeContent()` 又加一遍 `btn btn-default`。**`[type="submit"]` 的 `margin: ... !important` 会把 `.mr-2` 的右外边距覆盖成 0，而 `type="reset"` / 无 `type` 的按钮保留 8px** → 多按钮表单因此"挤在一起 + 整组偏移"。

### 新 Form API（插件后台，如扩展管理器）

同一个 `dokuwiki\Form\Form`，但类不一样：

- `addTextInput($name, $label)` → `InputElement('text', ...)`，**只有显式 `addClass()` 加的类**（扩展管理器的输入框只有 `block`，没有 `edit`）
- `InputElement::addClass()` 会把类**同时加到 `<label>` 和 `<input>`** 上
- `ButtonElement` **没有默认 class**；`type` 由调用方 `->attr('type', ...)` 指定，**不指定就没有 `type` 属性**
- 表单本身会被追加 `doku_form` 类，页面级还会追加 `form-inline`

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
>
> 这条**同样适用于 auth 表单**：它们的字段带 `size="50"`，`input.edit` 一旦落空就会把卡片撑破。稳妥写法是 `label.block input`（带 id 前缀）。

### 哪些同类表单**还没被覆盖**（改版时要一起回归）

| 页面 / 表单 | id | 现状 |
|---|---|---|
| 注册 / 资料更新 | `#dw__register`（两页共用） | ✅ 已覆盖（居中卡片，按钮居中） |
| 重设密码 | `#dw__resendpwd` | ✅ 已覆盖（按钮居中） |
| 登录 | `#dw__login` | ✅ 已覆盖（按钮靠右） |
| 扩展管理器手动安装 | `#extension__manager form.install` | ✅ 已覆盖（按钮靠右） |
| 认证令牌（资料页） | `#dw__profiletoken` | ❌ 无覆盖：退回核心 fieldset；JWT 用 `<code style="display:block;word-break:break-word">` 输出，在居中容器里折行；按钮是 `addButton('regen', …)`，**没有 `type` 属性**，`[type="submit"]` 命不中 |
| 删除账号（资料页） | `#dw__profiledelete` | ❌ 无覆盖：核心只有 `display: block; margin-top: 2.8em`；含勾选框 + 可选"当前密码"确认 |
| 订阅邮件 | `#subscribe__form` | ❌ 无覆盖：核心自带 `width: 400px; text-align: center`，且输入框**没有 `label.block` 包裹** → 核心的 `input.edit { width: 50% }` 不命中，宽度不可控 |
| 媒体搜索 | `#dw__mediasearch` | ❌ `css/core/_media_popup.css` 第 197~208 行是一排**空规则**（只有选择器、没有声明），等于没写 |
| 高级搜索 | `.search-results-form fieldset.search-form` | ⚠️ 有覆盖，但 `input[name="q"] { width: 50% }`（0-1-1）会被 `.form-inline .form-control { width: auto }`（0-2-0）压掉 |
| 用户管理器 | `#user__manager` | ❌ 只有 `.import_users { clear: both }` |
| 编辑 / Recent / Revisions / 冲突 / 草稿 | — | ⚠️ 只有 `commonStyles()` 给的 `btn btn-default mr-2`，没有统一的间距 / 居中规则 |

## 核心样式冲突点（`css/core/_forms.css`）

| 核心规则 | 影响 |
|---|---|
| `.dokuwiki form { display: inline }` | 要居中/限宽必须显式 `display: block` |
| `.dokuwiki fieldset { width: 400px; text-align: center; margin: auto }` | 固定宽度 + 强制居中 |
| `.dokuwiki label.block { display: block; text-align: right; font-weight: bold }` | 标签文字右对齐 + 加粗 |
| `.dokuwiki label.block select, .dokuwiki label.block input.edit { width: 50% }` | 输入框半宽；**只命中带 `edit` 的输入框**（auth 表单有，扩展管理器没有） |
| `#dw__login label[for="remember__me"] { margin-left: 50% }` | 勾选框被推到中间 |
| `#dw__resendpwd fieldset, #dw__register fieldset { padding-bottom: 0.7em }` | 与模板的 `padding: 1em 1.25em 1.25em` 抢；模板靠同优先级 + 后加载取胜 |
| `#subscribe__form { display: block; width: 400px; text-align: center }`、`#subscribe__form label { display: block; margin: 0 .5em .5em }` | 订阅页自带一套，与 Bootstrap 抢 |
| `#dw__profiledelete { display: block; margin-top: 2.8em }` | 资料页删除表单只有这一条 |

模板侧 `css/template.less` 另有 `.dokuwiki fieldset { border: none }`，已去掉核心的边框。

## 覆盖套路

### 约定

- 统一写在 `css/template.less`，按页面/组件分区并加注释
- 每个表单**独立成块，不要合并成共享选择器**（登录、注册、扩展管理器各一块），否则改一处会波及别的表单。**例外**：`#dw__register, #dw__resendpwd` 本来就是一条共享规则，因为核心让资料更新页复用了注册页的 id
- 选择器带 `#dw__login`、`#extension__manager form.install` 这类 id/页面前缀，天然压过 `.dokuwiki ...`；但**宽度规则还是得带前缀或 `!important`**，因为 `normalizeContent()` 给每个 form 加了 `form-inline`，BS3 的 `.form-inline .form-control { width: auto }`（0-2-0）会压掉单属性选择器

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

/* 勾选框 / 提交按钮右对齐 —— 只用于「带勾选框」的表单（登录框、扩展管理器）；
   不带勾选框的表单（注册 / 重设密码 / 资料更新）按钮要居中，别套这几行 */
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

- **避开 `:has()`**：less.php 对它的支持不确定，解析失败会拖垮整份样式表。`:not(:last-child)`、`:last-of-type`、属性选择器都可以放心用——`[type="submit"]:not(:last-child)` 是"只在多按钮表单里生效"的干净写法
- **优先级必须压过 `.form-inline .form-control`（0-2-0）**：所有 form 都被追加了 `form-inline`，所以 `input[name="q"] { width: 50% }` 这类规则在 ≥768px 会失效。要稳就带 id 前缀
- **`.mr-2` 的坑**：它是 `margin-right: .5rem !important`。单类规则压不过它；而带 id 前缀的 `margin` 简写 `!important`（如 `[type="submit"] { margin: .5em 0 0 !important }`）又能反过来把它清零。两条 `!important` 谁赢看优先级、不看书写先后 → 多按钮表单会出现"一个按钮有 8px 外边距、另一个没有"，表现为挤在一起 + 整组偏移。**修法：把 submit 和 reset 放进同一条规则，再用相邻选择器给一次统一间距**
- **`[data-dw-icon]` 会改变按钮尺寸**：`script.js` 把图标 prepend 到按钮**内部**，带图标的按钮天然更宽。核心往往只给 submit 加、不给 reset 加 → 并排按钮宽度不一致。要么都带、要么都不带
- **没有 `type` 属性的按钮**（如 `#dw__profiletoken` 的 `regen`）命中不了 `[type="submit"]`，要写成 `form button` 或给它加类
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

### 2. 注册 / 重设密码 / 资料更新（`#dw__register`、`#dw__resendpwd`）

一条规则管**三页**（资料更新页复用 `#dw__register`）。当前形态：居中卡片 `max-width: 420px` + **标签靠左** + **输入框满格** + **按钮居中**（这三个页面没有勾选框）+ 清掉 `<br>`。关键片段：

```less
  label.block { display: block; width: 100%; text-align: left !important; margin-bottom: 0.75em; }
  label.block span { display: block; margin-bottom: 0.25em; }

  /* 按元素匹配，不要只写 input.edit：这些字段带 size="50"，选择器落空会撑破卡片 */
  label.block input,
  label.block select { display: block; width: 100% !important; margin: 0 auto !important; text-align: left; }

  br { display: none; }                      /* 清掉核心插进来的空行 */

  /* 两个按钮必须放同一条规则：只写 type="submit" 会把 .mr-2 的不对称留给 reset */
  [type="submit"],
  [type="reset"] { display: inline-block; margin: 0.5em 0 0 !important; float: none !important; }
  [type="submit"] + [type="reset"] { margin-left: 0.75em !important; }

  /* 核心只给 submit 加 data-dw-icon → 图标让保存按钮更宽。
     只对"后面还跟着按钮"的 submit 去图标，单按钮页不受影响 */
  [type="submit"]:not(:last-child) svg,
  [type="submit"]:not(:last-child) .iconify { display: none; }
```

按钮居中靠的是表单/`fieldset` 上的 `text-align: center`（inline-block 的 `margin: auto` 不居中，别指望它）。

已知遗留：这一块的 `legend` 仍是 `width: auto`，而登录框是 `width: 100%` —— 标题下划线宽度**尚未对齐**。

### 3. 扩展管理器手动安装（`#extension__manager form.install`）

沿用登录框的排布（同一套"标签在上靠左、输入框满格、勾选框与按钮靠右齐平"的规则），差异只有两点：

- 选择器前缀换成 `#extension__manager form.install`
- 输入框**按元素匹配**（`label.block input`），因为新 Form API 没有 `edit` 类（auth 表单同理：它们的字段带 `size="50"`，更不能只靠 `edit`）
- 这个表单**有勾选框**（「覆盖」），所以勾选框与按钮**靠右**——与变体 2 的三个页面相反

## 踩过的坑与红线

- ❌ **用 PHP 重排表单元素**：曾改 `EventHandlers.php` 的 `formLoginOutput` 去挪动 checkbox/按钮，索引算错导致勾选框插到按钮后面、按钮上移。**布局问题一律用 CSS 解决**
- ❌ **改 `template.less` 前不重读文件**：文件可能已被改动，`Edit` 会报 "String to replace not found"。每次编辑前先读最新内容
- ❌ **`:has()` / `clamp()`**：less.php 编译风险，见上
- ❌ **把多个表单合并到一个选择器**：会互相牵连，回归面变大
- ⚠️ **只写 `[type="submit"]`**：`type="reset"` 和无 `type` 的按钮活在自己的规则外，会保留 `.mr-2` 的右外边距 → 按钮组挤在一起且整体偏左
- ⚠️ **给多个并排按钮中的一个加 `data-dw-icon`**：那个按钮会变宽，跟旁边的对不齐
- ⚠️ **把"按钮靠右"的通用规则套到没有勾选框的表单**：注册 / 重设密码 / 资料更新这三页用户明确要求按钮居中
- ✅ 小技巧：`[type="submit"]:not(:last-child)` 能只在"多按钮"表单里生效，单按钮页保持原样
- ⚠️ 改完要提醒用户清 DokuWiki 的 CSS 缓存，否则浏览器里看不到变化

## 验证方法

- 本仓库无核心源码，**无法本地渲染**，改动靠选择器推演 + 核心源码核对
- 查核心 / 插件的真实标记：`raw.githubusercontent.com` 经常超时，**改用 GitHub Contents API 更稳**——把 `https://api.github.com/repos/dokuwiki/dokuwiki/contents/<路径>` 交给 `WebFetch`，并明确要求"解码 base64 后逐字输出源码"
  - `inc/Ui/UserResendPwd.php`、`inc/Ui/UserProfile.php`、`inc/Ui/UserRegister.php`、`inc/Ui/Login.php`
  - `inc/Form/InputElement.php`、`inc/Form/CheckableElement.php`、`inc/Form/ButtonElement.php`
  - `lib/plugins/<插件>/Gui*.php`
- 动手前先 grep 该页面的 id，确认**还有哪些同类表单没被覆盖**（见上文清单），一并评估
- LESS 语法自检：`template.less` 大括号配平即可——`([regex]::Matches($c,'\{')).Count` 与 `\}` 计数相等。离线环境 `npx lessc` 不可用
- 优先级自检：属性选择器与类选择器都计入「类」这一档，`input[type="checkbox"]` 与 `input.edit` 同权重，靠**书写顺序**决出胜负；要稳就再加一层前缀

## 相关文件

- `css/template.less` —— 所有覆盖的落点
- `css/core/_forms.css`、`css/core/_search.less`、`css/core/_media_popup.css` —— 需要对抗的核心样式（后两个是覆盖不全的重灾区）
- `Template.php` 的 `normalizeContent()` —— 页面级二次加工（按钮 / 标签 / 输入框 / form 的类都从这里补）
- `script.js` 的 `dw_template.init()`（约 140~171 行）—— `[data-dw-icon]` / `form-inline` / `control-label` 的浏览器侧加工
- `style.ini` —— 样式加载顺序（核心在前，模板在后）
- `EventHandlers.php` —— **不要**在这里改表单结构