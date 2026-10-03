# tmux-agents

[English](README.md) | 简体中文

**子 agent 不该在任务结束后就消失。** 内置的子 agent 都在你看不见的地方跑，最后只给你一段总结，背后的过程全没了。

tmux-agents 让每个 Claude 或 Codex 子 agent 都在自己的 tmux 窗口里运行。你可以在实时预览里看它干活，也可以随时切进去给它指示。

agent 之间可以互相派任务、同步进度。它们的 pane 会一直保留到你关闭为止，对话之后也还在：Codex 用 `codex resume`，Claude 用 `claude --resume` 就能找回来。

看得见过程，留得住历史，随时接着做。

- **真实的会话，不是黑盒。** 每个子 agent 都是完整的 Claude 或 Codex 会话，所有历史都在屏幕上。你可以批准提示、追问，或者中途纠正它。
- **一眼看出谁在等你。** 状态栏上方有一行，显示每个子 agent 是在工作、已完成、在等权限，还是在等你。
- **agent 之间能对话。** 对 Claude 说"连接 codex，让它 review 这个 diff"，Codex 的回复会作为一条新消息回到 Claude。
- **不打扰你。** 子 agent 放在每个项目各自的隐藏 session 里，不会改动你的布局；你在某个 pane 里打字时，消息也不会插进来。
- **只需要 tmux 和 bash。** 不用跑任何服务，状态都存在 tmux pane 上。

## 截图

<p align="center">
  <img src="docs/message-request.png" width="49%" alt="Claude 发出的请求出现在 Codex 的 pane 里">
  <img src="docs/message-reply.png" width="49%" alt="Codex 的回复回到 Claude 的 pane">
</p>

<p align="center">Claude 请 Codex 做 review，回复作为一条新消息回来。</p>

<p align="center">
  <img src="docs/agent-list.png" width="49%" alt="agent 列表：子 agent 的状态、父 agent，以及选中项的实时预览">
  <img src="docs/popup.png" width="49%" alt="从列表里用 popup 打开一个隐藏的 Codex 子 agent">
</p>

<p align="center"><code>prefix + a</code> 列出你的子 agent，带实时预览。用 popup 打开一个，就能回答它或者给它指示。</p>

状态栏：状态栏上方的一行会统计子 agent，有 agent 需要你时变成红色或黄色：

```
      ⠹ auth-review: reading src/auth.ts  │  api ⠹ 2 ✓ 1 · blog ⠹ 1
```

设计说明、协议细节和已知的坑：[DESIGN.md](DESIGN.md)（英文）。

## 安装

最简单的方式：让 Claude Code 或 Codex 帮你装。

> 按照 https://github.com/TheClooneyCollection/tmux-agents/blob/main/skills/tmux-agents-setup/SKILL.md 帮我安装 tmux-agents

它会检查你的环境、运行安装脚本，每处配置改动都先给你看，然后带你走一遍 quick start。之后对任何 agent 说 "tmux-agents quick start"，就能再走一遍。

### 手动安装

需要 tmux 3.2+ 和 bash。`fzf` 可选（选择器和实时 agent 列表会更好用）。

```sh
git clone https://github.com/TheClooneyCollection/tmux-agents.git
cd tmux-agents
./install.sh            # 先加 --dry-run 看看它会做什么
```

`install.sh` 会：

- 把 `tmux-*` 命令链接到 `~/.local/bin`（用 `BIN_DIR` 修改）
- 把 `tmux-agents` 和 `tmux-agents-setup` 两个 skill 链接到 `~/.claude/skills/` 和你的 Codex home
- 复制 Codex rules（Codex 会忽略符号链接的 `.rules` 文件）
- 不加 `--force` 时，绝不覆盖已有的真实文件

然后把这些加到你自己的配置里（`install.sh` 会用你的实际路径打印出来）：

| | |
| --- | --- |
| **tmux** | 在 `~/.tmux.conf` 里加 `source-file ~/path/to/tmux-agents/tmux/tmux-agents.conf`，然后重新加载 |
| **PATH** | `~/.local/bin` |
| **Claude** | 把 [`integrations/claude/settings.json`](integrations/claude/settings.json) 里的 `allow` 规则合并进 `~/.claude/settings.json` |
| **Codex** | wrapper：[`integrations/fish/functions/`](integrations/fish/functions) 或 [`integrations/sh/codex.sh`](integrations/sh/codex.sh) |

<details>
<summary>每一项是做什么的</summary>

- **tmux：** `prefix + a`（agent 列表）、`prefix + A`（连接）、子 agent 状态行，以及刷新边框、响铃提醒和发送排队消息的 hooks。如果命令没有链接到 `~/.local/bin`，在 `source-file` 那行之前加上 `%hidden TMUX_AGENTS_BIN="/那个/目录"`。
- **Claude：** agent 发消息、查看、spawn、报告进度、关闭自己的子 agent 时都不用再弹确认。`tmux-connect`（不带 `--from`）、`tmux-disconnect` 和不带参数的 `tmux-dismiss` 仍然由你来操作，照样会询问。
- **Codex：** Codex 在一个共享的后台进程里执行命令，里面的 `$TMUX_PANE` 可能属于别的 pane，所以要靠 wrapper 把每个 Codex 固定到它自己的 pane（见 DESIGN.md）。fish 用户把函数复制到 `~/.config/fish/functions/`；bash/zsh 用户在 `~/.bashrc` 或 `~/.zshrc` 里 `source` 那个 sh 文件。
- **可选：** 在 `CLAUDE.md` / `AGENTS.md` 里告诉 agent 所有子 agent 都用 `tmux-spawn` 开。skill 里有具体说明。

</details>

更新用 `git pull` 就行，链接会自动指向新脚本。如果 rules 有变化，再跑一次 `./install.sh`。

有多个 Codex 账号？见[使用指南](docs/guide.md#more-than-one-codex-account)（英文）。

## 快速上手

1. 把一个 tmux 窗口分成两半，一边启动 `claude`，另一边启动 `codex`。
2. 对 Claude 说："用 tmux-agents 连接 codex 那个 pane，让它 review 这个 diff"。请求会出现在 Codex 的 pane 里，回复会回到 Claude。
3. 对 Claude 说："开一个子 agent 给 parser 加测试"。它在隐藏窗口里运行，状态栏上方那一行会显示它的进度。
4. 按 `prefix + a` 查看它。按 Enter 用 popup 打开，按 `prefix + d` 返回。

也可以让 agent 带你走一遍：对它说 "tmux-agents quick start"。

## 快捷键

| 按键 | |
| --- | --- |
| `prefix + a` | agent 列表，带实时预览 |
| `prefix + A` | 把当前 pane 连接到另一个 pane（`ctrl-a`：任意窗口） |
| `prefix + d` | 在 popup 里：返回列表。在列表里：关闭列表 |

列表里：`enter` 打开 · `ctrl-o` 跳过去 · `ctrl-x` 关闭 agent · `ctrl-d` 关闭所有已完成的 · `ctrl-a` 切换所有 pane / 子 agent

关掉的子 agent 会在列表底部的 `closed` 区保留 7 天：按 `enter` 就能带着完整对话重新打开。也可以让它的父 agent 帮你重开。

状态：`⠹` 工作中 · `✓` 已完成 · `⚠` 等待权限（红）· `◆` 需要你（黄）· `✗` 已退出

## 命令

这些命令由 agent 替你运行，每个都支持 `--help`。

| 命令 | |
| --- | --- |
| `tmux-connect` | 给当前 pane 命名并连接到另一个 pane |
| `tmux-ask` | 给已连接的 agent 发消息 |
| `tmux-spawn` | 在隐藏窗口或 `--split` 指定的可见分屏中启动子 agent |
| `tmux-agents` | agent 列表（`prefix + a`） |
| `tmux-peers`、`tmux-peek` | 查看连接关系；读取另一个 pane 的内容 |
| `tmux-dismiss`、`tmux-disconnect` | 关闭子 agent；断开 pane 之间的连接 |
| `tmux-agent-report` | 报告进度，显示在状态行上 |

消息如何传递、子 agent 的细节、设置项和实现原理：见[使用指南](docs/guide.md)（英文）。

## 许可证

MIT，见 [LICENSE](LICENSE)。
