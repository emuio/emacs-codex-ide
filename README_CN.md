# Codex IDE for Emacs

[![GNU Emacs 28.1+](https://img.shields.io/badge/GNU%20Emacs-28.1%2B-blue.svg)](https://www.gnu.org/software/emacs/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Codex IDE for Emacs 是一个纯 Emacs 的 Codex 客户端，灵感来自 [claude-code-ide.el](https://github.com/manzaltu/claude-code-ide.el)。

这个包提供了对 `codex app-server` 的原生集成。它不同于基于终端的封装方式，会把 Codex 会话渲染成普通 Emacs buffer，并把交互界面完整保留在 Emacs 内部。

## 概览

### 功能

- 以 Emacs major mode 运行 Codex，不需要终端封装。
- 使用完整的 Emacs major-mode 语法高亮渲染代码块，而不是终端风格的格式化。
- 使用 Emacs diff 渲染显示 diff，让 patch 的外观和阅读方式更符合 Emacs，包括一个规范的 session diff buffer，可以跟随实时工作或 transcript 位置。
- 将 Codex 文件和代码引用转换为可点击的 Emacs widget，直接跳转到真实 buffer。
- 在 buffer 内保留 approval，并提供交互式 review 流程，用于确认命令和改动，无需离开当前 session。
- 可以展开或折叠 transcript 细节，既能快速浏览进度摘要，也能检查完整的 turn-by-turn 输出。
- 使用 MCP 集成，让 Codex 在可用时感知当前 Emacs window 和 buffer 状态。
- 提供交互式配置菜单，用于选择 model、sandbox、personality 以及其他 session 控制项。
- 在 session 运行时通过 header line 显示实时 quota 和 token 使用状态。
- 提供 session 管理 mode，可在 Emacs 内预览、搜索和恢复之前的 Codex sessions。

### 截图

#### Emacs 内的 Codex mode

![Emacs state aware](https://github.com/dgillis/emacs-codex-ide/blob/1c0bb00a35c8fcb20e8a30e28cdc56d774267049/screenshots/codex-mode-inside-emacs.png)
_Codex 能知道 Emacs 中当前激活的文件和 region。_

#### 运行多个 Codex sessions

![Multiple codex sessions](https://github.com/dgillis/emacs-codex-ide/blob/1c0bb00a35c8fcb20e8a30e28cdc56d774267049/screenshots/run-multiple-codex-sessions.jpg)
_同时运行和管理多个 agents。_

#### 可展开的 Codex 输出

![Toggle agent output](https://github.com/dgillis/emacs-codex-ide/blob/1c0bb00a35c8fcb20e8a30e28cdc56d774267049/screenshots/expandable-codex-output.jpg)
_展开或折叠 Codex 输出细节。_

#### 查看并恢复之前的 Codex sessions

![Manage past sessions](https://github.com/dgillis/emacs-codex-ide/blob/1c0bb00a35c8fcb20e8a30e28cdc56d774267049/screenshots/view-and-resume-prior-sessions.jpg)
_用于查看和恢复历史 sessions 的 mode。_

<!--
#### 基于 Emacs mode 的代码渲染

![Major-mode syntax coloring](https://github.com/user-attachments/assets/2dc363f4-ab76-44c2-b45b-51729c908465)
_代码块根据 Emacs major mode 渲染。_

#### 交互式 approvals

![Interactive approvals](https://github.com/user-attachments/assets/0ab2989b-4cc1-47f9-adbf-cd273ae9fe1f)
_基于 Emacs widget 的交互式 approvals。_
-->

## 安装

### 前置条件

- Emacs 28.1 或更高版本
- 已安装 Codex CLI，并且可以在 `PATH` 中找到
- 已安装 `transient`
- 如果要使用可选的 Emacs MCP bridge，需要可用的 `python3` 和 `emacsclient`

### 安装 Codex CLI

请参考官方 app-server 文档：[OpenAI Codex app-server docs](https://developers.openai.com/codex/app-server#api-overview)。

### 安装 Emacs package

在 Emacs 30+ 中使用带 `:vc` 的 `use-package` 安装：

```emacs-lisp
(use-package codex-ide
  :vc (:url "https://github.com/dgillis/emacs-codex-ide" :rev :newest)
  :bind ("C-c C-;" . codex-ide-menu))
```

使用 `use-package` 和 [straight.el](https://github.com/radian-software/straight.el) 安装：

```emacs-lisp
(use-package codex-ide
  :straight (:type git :host github :repo "dgillis/emacs-codex-ide")
  :bind ("C-c C-;" . codex-ide-menu))
```

安装后，运行 `M-x codex-ide-menu` 或 `M-x codex-ide`，即可为当前 project 启动 session。

## 快速开始

### `codex-ide-menu`

使用 `M-x codex-ide-menu` 作为主要入口。它会打开一个 transient menu，用于启动新 session、继续最近的 session、从 minibuffer 发送 prompt、切换到已有 buffer、打开 buffer lists，以及调整配置。

![The main menu is the recommended starting point for everyday Codex IDE commands.](https://github.com/dgillis/emacs-codex-ide/blob/1c0bb00a35c8fcb20e8a30e28cdc56d774267049/screenshots/codex-ide-menu.png)

### `codex-ide-session-mode`

`codex-ide-session-mode` 是 Codex 的 buffer interface。它负责渲染 conversation transcript，在当前位置保留可编辑 active prompt，stream assistant 输出，把文件引用转换成 links，并在 Emacs 内处理 interruption 或 approval 流程。

Key bindings：

- `C-c RET` 提交 active prompt。
- `C-c C-c` 或 `C-c C-k` 中断当前 response。
- `C-c C-d` 打开 session diff buffer。
- `C-M-p` 和 `C-M-n` 在 prompt lines 之间移动。
- 当 point 位于 active prompt 中时，`M-p` 和 `M-n` 循环 prompt history。
- `TAB` 和 `S-TAB` 在 clickable buttons 和 file links 之间移动。

### Session diff buffer

Codex IDE 可以为每个 session 显示一个规范的 diff buffer。可以从 session buffer 使用 `C-c C-d` 打开，也可以使用 `M-x codex-ide-session-diff-open`，或者在 `M-x codex-ide-menu` 中选择 `D` / `Session diff`。

Session diff buffer 派生自 `diff-mode`，所以普通 Emacs diff navigation 和 font-locking 都可用。它绑定到一个 Codex session，并复用以 `-session-diff` 结尾的稳定 buffer name，因此很适合作为 Codex 编辑文件时的 companion window。

这个 buffer 有三种 source states：

- `live`：显示最新或当前运行中的 turn diff。Codex 正在主动改动时适合使用这个状态，以便实时查看正在编辑的内容。传入的 file-change updates 会自动刷新 buffer。
- `transcript`：显示 session transcript 中 point 所在 prompt/response 的 diff。适合 review 之前的 turns，或者比较对话不同阶段产生的改动。session buffer 中 point 移动并选中不同 turn 时，diff buffer 会随之更新。
- `pinned`：持续显示某个选定 turn。适合在你希望 diff 保持固定，同时继续浏览 transcript 或等待新 activity 到来时使用。

`codex-ide-session-diff-mode` 中的 key bindings：

- `g` 刷新 diff buffer。
- `l` 切换到 `live`。
- `t` 切换到 `transcript`。
- `p` 切换到 `pinned`。
- `C-c TAB` 切换 point 所在 file diff 的展开状态。
- `C-c C-a` 折叠所有 file diffs。
- `C-c C-e` 展开所有 file diffs。
- 当 Codex IDE 可以解析位置时，`RET` 会从 diff line 跳转到对应 source file 位置。

Session diff buffer 刷新时，Codex IDE 会保留已有 file 和 hunk sections 的展开或折叠状态。新添加的 file sections 会在所有已有 file sections 都展开时默认展开；如果任何已有 file section 已折叠，新 file sections 也会默认折叠。可以自定义 `codex-ide-diff-new-file-section-fold-predicate` 来修改这个策略。

Session diff buffer 不同于静态 turn diff buffers。需要自动更新视图时使用 session diff；需要快照时使用某个 turn-specific diff。

## 示例

#### Codex session buffer mode

https://github.com/user-attachments/assets/e3e7be19-8774-4ae9-bef4-354ee45f9355

https://github.com/user-attachments/assets/ee21a396-9045-4b65-b0b4-0c17509a2841

#### Manage sessions mode

https://github.com/user-attachments/assets/e82093b9-a93d-408a-93f0-417c1cd69cc7

## 许可证

本项目使用 [MIT License](https://opensource.org/licenses/MIT) 授权。

## 免责声明

Codex(R) 是 OpenAI 的商标。Codex(R) 是 OpenAI 开发的应用。

本项目不隶属于 OpenAI，亦未获得 OpenAI 的认可或赞助。
