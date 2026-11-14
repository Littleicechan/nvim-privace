# Neovim 配置说明

适用于 Neovim 0.11+（当前 WSL 是 0.12.6），插件管理用 lazy.nvim。
同一套文件在 WSL 和 Windows 上通用：


Leader 键是 **空格**。按下空格稍等，which-key 会弹出所有可用快捷键。

## 文件结构

```
nvim/
├── init.lua                  入口：设置 leader，依次加载下面的模块
├── lazy-lock.json            插件版本锁定（lazy 自动生成，别手改）
└── lua/config/
    ├── options.lua           基础选项
    ├── keymaps.lua           通用快捷键
    ├── autocmds.lua          自动命令
    ├── lazy.lua              安装/启动 lazy.nvim，自动导入 plugins/ 下所有文件
    └── plugins/
        ├── ui.lua            主题、状态栏、标签栏、终端、快捷键提示、缩进线
        ├── editor.lua        treesitter 语法高亮、telescope 搜索
        ├── coding.lua        文件树、git、自动括号、surround、TODO 高亮
        ├── lsp.lua           语言服务器（mason 安装）
        ├── cmp.lua           自动补全
        └── ai.lua            AI：Claude + MiniMax
```

想加新插件：在 `lua/config/plugins/` 里新建一个 `.lua` 文件，`return { ... }` 一个 lazy 插件列表即可，会被自动加载。

## 各文件内容

### init.lua
- leader 设为空格
- `vim.g.have_nerd_font = false`：终端用 Nerd Font 时改成 `true`，文件树/标签栏/状态栏会显示图标

### options.lua
- 行号 + 相对行号、高亮当前行、左侧符号列常显
- 默认 4 空格缩进（lua/js/ts/json/yaml/html/css 为 2 空格，见 autocmds）
- 搜索忽略大小写，输入大写时区分大小写
- 剪贴板与系统共享（WSL 用 xclip，Windows 原生）
- `:s` 替换实时预览、显示多余空格和 Tab
- `:q` 有未保存改动时询问而不是报错
- 持久 undo（关掉文件再打开也能撤销）
- 基于 treesitter 的代码折叠，打开文件时默认全部展开
- `timeoutlen = 400`：组合键（如 `jk`）要在 400ms 内按完

### autocmds.lua
- 复制时短暂高亮被复制的内容
- 重新打开文件时光标回到上次位置
- 文件在外部被修改（如终端里 AI 改了代码）时自动重新加载
- 帮助、quickfix 等窗口按 `q` 关闭
- 调整终端大小时自动平分窗口

### lazy.lua
- 没有 lazy.nvim 时自动从 GitHub 克隆（需要 git）
- `{ import = "config.plugins" }` 导入所有插件文件

### ui.lua
| 插件 | 作用 |
|---|---|
| tokyonight | 主题（night 风格） |
| lualine | 底部状态栏 |
| bufferline | 顶部文件标签 |
| which-key | 按 leader 后弹出快捷键提示 |
| indent-blankline | 缩进参考线 |
| toggleterm | 浮动终端（`<C-\>`） |

### editor.lua
- **nvim-treesitter**：语法高亮和缩进。自动安装 asm、bash、c、cpp、go、java、javascript、json、kotlin、lua、python、rust、toml、typescript、vim、yaml 解析器（需要 C 编译器，没有就跳过）
- **telescope**：模糊搜索文件、内容、缓冲区等（全文搜索需要 ripgrep）

### coding.lua
| 插件 | 作用 |
|---|---|
| nvim-tree | 文件树 |
| gitsigns | 左侧显示 git 改动、暂存/撤销改动块 |
| nvim-autopairs | 自动补全成对括号和引号 |
| nvim-surround | 增/改/删包围符号：`ys` / `cs` / `ds` |
| todo-comments | 高亮 TODO、FIXME、NOTE 等注释 |

### lsp.lua
- mason 自动安装：bashls、gopls、jdtls、lua_ls、pyright、rust_analyzer、ts_ls
- **clangd（C/C++）不走 mason**，系统里装了就自动启用（`sudo apt install clangd`，Windows 装 LLVM）
- lua_ls 已配置识别 `vim` 全局变量，并避免把家目录当成项目根
- C/C++ 项目最好有 `compile_commands.json`，clangd 才能找到头文件

### cmp.lua（VS Code 风格）
- 补全来源：语言服务器、代码片段、文件路径；前面这些都没结果时才补当前文件里的词
- 菜单自动弹出并默认选中第一项，`Enter` / `Tab` 直接接受，`Up` / `Down` 换选项
- 片段：LuaSnip + **friendly-snippets**（VS Code 格式的片段库，比如 Python 里输入 `def`）
- 参数提示：**lsp_signature.nvim**，输入 `(` 时自动弹出函数签名
- 类型图标：VS Code 同款 codicons（借用 **lspkind** 的图标表），需要 Nerd Font，并把 `init.lua` 里的 `vim.g.have_nerd_font` 改成 `true`；没开就显示 `Method`、`Function` 这样的文字
- 命令行 `:` 和搜索 `/` 也有补全

### ai.lua
- **codecompanion.nvim**：编辑器内 AI 聊天、行内修改、代理工具
  - `claude` 适配器：`claude-opus-5-5`，读取环境变量 `ANTHROPIC_API_KEY`
  - `minimax` 适配器：`MiniMax-M3.1-Flash`（可切换 `MiniMax-M3`），走 MiniMax 的 Anthropic 兼容接口
  - 默认用 Claude；聊天窗口里按 `ga` 切换适配器/模型
- **Claude Code 终端**（需要 `npm i -g @anthropic-ai/claude-code`）
  - 官方版用 `ANTHROPIC_API_KEY`
  - MiniMax 版把 Claude Code 接到 `api.minimaxi.com/anthropic`
- MiniMax key：优先读 `MINIMAX_API_KEY`，没有就读 `~/.mmx/config.json`
- 改模型：修改文件开头的 `CLAUDE_MODEL` / `MINIMAX_MODEL`

## 快捷键速查

### 通用
| 键 | 模式 | 功能 |
|---|---|---|
| `jk` | 插入 | 退出插入模式 |
| `<Esc>` | 普通 | 取消搜索高亮 |
| `<leader>w` / `q` / `Q` | 普通 | 保存 / 退出 / 全部退出 |
| `<C-h/j/k/l>` | 普通 | 切换窗口 |
| `<C-方向键>` | 普通 | 调整窗口大小 |
| `<leader>-` / `<leader>\|` | 普通 | 上下 / 左右分屏 |
| `<S-h>` / `<S-l>` | 普通 | 上一个 / 下一个文件 |
| `<leader>bd` | 普通 | 关闭当前文件 |
| `J` / `K` | 可视 | 上下移动选中行 |
| `<` / `>` | 可视 | 缩进后保持选中 |
| `<leader>p` | 可视 | 粘贴且不覆盖已复制内容 |
| `<C-\>` | 普通/终端 | 浮动终端 |
| `<Esc><Esc>` | 终端 | 回到普通模式 |

### 文件与搜索
| 键 | 功能 |
|---|---|
| `<leader>e` / `E` | 文件树开关 / 定位当前文件 |
| `<leader>ff` | 找文件 |
| `<leader>fg` | 全文搜索（需要 ripgrep） |
| `<leader>fb` | 打开的文件 |
| `<leader>fr` | 最近文件 |
| `<leader>fh` | 帮助文档 |
| `<leader>fd` | 诊断列表 |
| `<leader>ft` | 搜索 TODO |

### 代码 / LSP
| 键 | 功能 |
|---|---|
| `gd` / `gD` | 跳到定义 / 声明 |
| `K` | 悬浮文档 |
| `grr` / `gri` | 引用 / 实现（nvim 内置） |
| `<leader>rn` | 重命名 |
| `<leader>ca` | 代码操作 |
| `<leader>lf` | 格式化 |
| `<leader>d` | 当前行诊断 |
| `<leader>xq` | 诊断放进 location list |

### 补全（插入模式）
| 键 | 功能 |
|---|---|
| `<CR>` / `<Tab>` | 接受选中项（默认就是第一项） |
| `<Up>` / `<Down>`（或 `<C-p>` / `<C-n>`） | 上一项 / 下一项 |
| `<Tab>` / `<S-Tab>`（菜单没开时） | 跳到片段的下一个 / 上一个占位 |
| `<C-Space>` | 手动触发补全 |
| `<C-e>` | 关闭菜单 |
| `<C-b>` / `<C-f>` | 滚动文档 |
| `<C-s>` | 手动显示函数签名（nvim 内置） |

### Git
| 键 | 功能 |
|---|---|
| `]h` / `[h` | 下一个 / 上一个改动块 |
| `<leader>gs` / `gr` | 暂存 / 撤销改动块 |
| `<leader>gp` | 预览改动块 |
| `<leader>gb` | 查看这一行是谁改的 |
| `<leader>gd` | 对比当前文件 |

### AI
| 键 | 功能 |
|---|---|
| `<leader>aa` | 开关 AI 聊天（Claude） |
| `<leader>an` | 新建 MiniMax 聊天 |
| `<leader>ap` | AI 动作面板 |
| `<leader>ai` | 行内 AI 修改（普通/可视） |
| `<leader>ad` | 把选中内容加进聊天（可视） |
| `<leader>ac` | 终端：Claude Code（官方） |
| `<leader>am` | 终端：Claude Code（MiniMax） |
| `ga` | 聊天窗口内切换模型 |

## 依赖

| 依赖 | 用途 | WSL 安装 | Windows 安装（winget） |
|---|---|---|---|
| git | lazy 下载插件 | 已有 | `Git.Git` |
| node / npm | pyright、ts_ls、bashls、Claude Code | 已有 | `OpenJS.NodeJS.LTS` |
| C 编译器 | 编译 treesitter 解析器 | 已有 gcc | `zig.zig`（优先使用；单独装 LLVM 不够，缺 C 标准库头文件） |
| MSVC C++ 工具 | clangd 需要的 C/C++ 标准库头文件 | 不需要 | VS Build Tools 加 `Microsoft.VisualStudio.Workload.VCTools` 工作负载（winget 没有 `modify`，要用 VS Installer 的 `setup.exe modify`，并以管理员身份运行） |
| clangd | C/C++ 补全 | `sudo apt install clangd` | `LLVM.LLVM`（已装 23.1.5；不在 PATH 上，options.lua 会给 nvim 补上） |
| go | 安装 gopls（mason 用 `go install`） | 已有 | `GoLang.Go`（没装就跳过 gopls；Windows 上 nvim 会把 GOPROXY 设成带 goproxy.cn 兜底） |
| cargo | rust_analyzer 运行需要 | rustup 官方脚本（`~/.cargo/bin` 目前是空的，cargo 不在 PATH 上） | 已装在 `G:\Language\Rust`：先设用户环境变量 `RUSTUP_HOME=G:\Language\Rust\rustup`、`CARGO_HOME=G:\Language\Rust\cargo`，再运行 `rustup-init.exe -y -c rust-src`（winget 的 `Rustlang.Rustup` 会装到 `%USERPROFILE%\.cargo`） |
| ripgrep | 全文搜索 | `sudo apt install ripgrep` | `BurntSushi.ripgrep.MSVC` |
| unzip | mason 安装部分工具 | `sudo apt install unzip` | 自带 |
| Claude Code | AI 终端 | `npm i -g @anthropic-ai/claude-code` | 同左 |

环境变量：
- `ANTHROPIC_API_KEY`：Claude
- `MINIMAX_API_KEY`：MiniMax（WSL 可省略，会读 `~/.mmx/config.json`）

## 常用命令
- `:Lazy`：插件管理（`U` 更新、`S` 同步）
- `:Mason`：语言服务器管理
- `:checkhealth`：检查环境问题
- `:LspInfo` / `:checkhealth vim.lsp`：查看语言服务器状态
- `:CodeCompanionChat`：AI 聊天
