# Proma 项目 AI 交接上下文

> 文档版本：1.0.0
> 更新日期：2026-09-06
> 用途：供新的 AI 编程助手快速理解本项目、开发约束、已有定制和历史踩坑。

## 1. 项目概览

Proma 是一个**本地优先的 Electron AI 桌面 Agent**。仓库采用 Bun monorepo，主要能力包括：

- Chat 对话
- Agent 会话与 Pi Agent runtime
- 多 AI Provider / Channel 配置
- MCP、Skills、Automation、Planning、Vault 等 Agent 能力
- 本地会话、消息和配置持久化
- macOS / Windows / Linux 桌面构建

本仓库是 `proma-ai/Proma` 的个人 fork：

- GitHub fork：`Lucifer1H/Proma`
- 上游仓库：`proma-ai/Proma`
- 主应用：`apps/electron`
- 共享包：`packages/*`

## 2. 分支策略

### `main`

- 只用于跟踪上游更新。
- 尽量保持接近 `upstream/main`。
- 不在这里放个人功能定制。

### `dev`

- 日常开发和个人定制分支。
- 从 `main` 合并上游更新，不对重度定制分支做 rebase。
- 当前用户主要使用这个分支。

远端：

```text
origin   https://github.com/Lucifer1H/Proma.git
upstream https://github.com/proma-ai/Proma.git
```

## 3. 当前个人定制功能

以下内容必须在同步上游时保留，除非用户明确要求移除：

### 已移除功能

1. **语音输入**
   - 已移除语音听写 UI、服务、IPC、preload API、快捷键、样式、权限和相关文件。
2. **Proma 商业版推广**
   - 已移除 ChannelSettings 和 ChannelForm 中的商业版推广卡片/入口。
3. **Onboarding / Tutorial UI**
   - 已移除全屏 onboarding gate、设置页 onboarding 标签和 onboarding 组件。
   - FAQ 内容和部分启动品牌资源仍可保留，不要误删无关资源。

### 保留或新增功能

1. **DeepSeek 默认渠道可删除**
   - `apps/electron/src/main/lib/channel-manager.ts` 不应自动重新创建 DeepSeek 默认渠道。
   - `listChannels()` 应返回实际配置的渠道。
2. **`/goal` 会话目标**
   - 会话级别保存目标。
   - 目标以 mention chip 形式出现在输入框上方。
   - `/goal <text>` 用于设置目标。
   - 目标持久化到 Agent session metadata。
   - 每一轮 Agent system prompt 都会注入目标。
   - 不要使用“Codex 风格”措辞描述该功能。
3. **本地 Chat 工具设置**
   - 保留旧版 Chat 工具体系，包括 Tools 设置页及相关凭据/测试 IPC。
   - 上游曾整体删除或迁移这套体系，合并时不能只恢复表面 UI，必须同步恢复其配置字段、运行时模块、共享类型、IPC 和 preload bridge。
4. **一键运行时依赖修复脚本**
   - 根目录：`fix-runtime-deps.sh`
   - 用于修复 Pi runtime 嵌套依赖不完整的问题。

## 4. 关键目录

```text
apps/electron/
  src/main/                   Electron 主进程、IPC、Agent 服务
  src/preload/                类型安全的 contextBridge / IPC bridge
  src/renderer/               React + Vite 前端
  src/utility/                Agent runtime、terminal runtime
  default-skills/             随应用分发的默认 Skills
  package.json                Electron 应用版本

packages/shared/              类型、IPC 常量、通用工具
packages/core/                Provider、SSE、代码高亮等
packages/session-core/        会话分组、消息历史等
packages/ui/                  跨应用 UI

.github/workflows/             GitHub Actions
sync-upstream.sh               上游同步辅助脚本
fix-runtime-deps.sh            运行时依赖修复脚本
release-notes/                 发布说明
```

## 5. 必须遵守的开发规范

这些要求来自仓库根目录 `AGENTS.md`，开发前必须阅读并遵守：

- 使用 **Bun**，不要使用 npm / pnpm。
- 常用命令：`bun run dev`、`bun run typecheck`、`bun test`。
- 注释、日志和用户可见工程文档优先使用中文，必要技术术语保留英文。
- 禁止使用 `any`。
- 对象类型优先使用 `interface`。
- 仅类型导入使用 `import type`。
- 状态管理统一使用 Jotai。
- UI 优先复用已有 Radix/shadcn primitives 和主题变量。
- 注意空状态、键盘操作、加载状态、深浅主题和可访问性。
- 本地持久化优先采用 JSON / JSONL，不引入本地数据库。
- 修改 JSON 配置或会话元数据时，使用：
  `apps/electron/src/main/lib/safe-file.ts` 的原子写封装。
- 功能改动应有 BDD 风格可执行测试，至少覆盖正常路径和主要边界。
- 不要随意新增依赖；先调研版本和维护状态。
- 每次改动都要递增对应交付物的 patch 版本；跨多个可发布包时逐个递增受影响包。
- 提交前检查 `git diff`，不要覆盖用户已有改动或提交无关文件。

## 6. IPC 修改规则

IPC 是四层契约，新增或修改 IPC 时必须同步检查：

1. `packages/shared`：通道常量、请求/响应类型
2. `apps/electron/src/main/ipc.ts`：主进程 handler
3. `apps/electron/src/preload/index.ts`：preload bridge 和类型
4. renderer：调用方、错误处理、状态更新

只修改其中一层会导致类型不一致或运行时 `window.electronAPI.xxx is not a function`。

## 7. Agent / Pi runtime 重要背景

Proma 只使用 **Pi Agent runtime**，不要重新引入 Claude Agent SDK 或其专属 session 语义。

重要位置：

- `apps/electron/src/main/lib/agent-orchestrator.ts`
- `apps/electron/src/main/lib/agent-service.ts`
- `apps/electron/src/main/lib/agent-session-manager.ts`
- `apps/electron/src/main/lib/agent-prompt-builder.ts`
- `apps/electron/src/utility/agent-runtime.ts`
- `apps/electron/src/renderer/components/agent/AgentView.tsx`
- `apps/electron/src/renderer/components/agent/AgentMessages.tsx`

用户项目的 `AGENTS.md` 必须由显式授权的项目根路径解析器注入：

- 不要恢复 cwd、祖先目录或额外目录的环境式规则发现。
- Proma 受管工作区的 `AGENTS.md` 和用户项目的 `AGENTS.md` 有不同所有权边界。
- 修改 Agent 工具、权限、上下文路径时，要检查工作区隔离、附加目录边界、会话恢复和 Automation/Collaboration 回归。

## 8. 最重要的历史踩坑：运行时依赖副本不完整

### 症状

Agent 发送消息后可能出现：

- 没有任何回答
- UI 显示完成但没有 assistant 输出
- 会话一直显示 `running`
- 无法停止 Agent
- 主进程出现 `runAgent 未处理异常`

### 曾经出现过的错误

```text
ERR_PACKAGE_PATH_NOT_EXPORTED
Cannot find module .../jiti/static
highlight.js/lib/core.js is not defined by exports
Could not resolve "typebox"
Could not resolve "./lib/dispatcher/proxy-agent"
```

### 根因

Pi Agent SDK 的嵌套依赖和 Electron 运行时副本不完整或版本不匹配。重点依赖包括：

- `jiti@2.7.0`
- `highlight.js@10.7.3`
- `typebox@1.3.7`
- `undici@8.9.0`

Vite / 其它依赖可能把不兼容版本放在顶层，或者 `bun install` 后 Pi SDK 所需的嵌套实体没有物理复制到：

```text
node_modules/@earendil-works/pi-coding-agent/node_modules/
apps/electron/node_modules/@earendil-works/pi-coding-agent/node_modules/
```

### 修复流程

在仓库根目录执行：

```bash
./fix-runtime-deps.sh
```

脚本会执行：

1. `bun install`
2. `sync:runtime-deps`
3. 校验 `jiti` 和 `highlight.js`
4. 校验 Electron 二进制
5. 检查 Electron runtime 副本

如果仍有问题，手动执行：

```bash
bun install
bun run --filter='@proma/electron' sync:runtime-deps
```

然后**完全重启 dev**，旧 Electron 进程不会自动加载新依赖：

```bash
pkill -f electronmon || true
pkill -f 'Electron.*code/Proma' || true
pkill -f 'bun run watch:' || true
pkill -f 'node_modules/.bin/vite dev' || true
bun run dev
```

如果出现：

```text
已有 Proma 进程持有单实例锁
```

说明旧进程没有清干净。先清理相关进程再启动，不要连续启动多个 dev 实例。

## 9. Agent 无回答问题的诊断顺序

遇到“发消息没有回答”时，不要先修改 UI，按以下顺序排查：

1. 查看 dev 主进程日志。
2. 搜索以下关键词：
   - `SDK 确认模型`
   - `provider_error`
   - `runAgent 未处理异常`
   - `jiti/static`
   - `highlight.js`
   - `Could not resolve`
3. 检查嵌套依赖版本和文件是否存在。
4. 执行 `./fix-runtime-deps.sh`。
5. 完全重启 dev，确认不是旧 Electron 进程。
6. 若 runtime 已正常加载但日志出现：

```text
provider_error - 服务繁忙
```

则优先判断为 Provider / CPA 服务侧问题，而不是本地渲染问题。
7. 检查当前 Agent channel、model、endpoint 和认证状态。

曾验证过的 OpenCode Go endpoint：

```text
https://opencode.ai/zen/go/v1/models
```

曾验证过 CPA health endpoint：

```text
https://hub.610421.xyz/v1/models
```

未经用户授权，不要把 API Key、Authorization header 或私密配置写入文档、日志、URL 或提交。

## 10. Provider / 网络注意事项

- 用户 macOS 常用 Clash：`127.0.0.1:7890`。
- Git 的 GitHub 代理可能写在 `~/.gitconfig`，而不是环境变量：

```text
http.https://github.com.proxy=http://127.0.0.1:7890
```

- 如果代理未运行，临时拉取 GitHub 可使用：

```bash
git -c 'http.https://github.com.proxy=' fetch upstream main
git -c 'http.https://github.com.proxy=' push origin dev
git -c 'http.https://github.com.proxy=' push --force-with-lease origin main
```

- 不要直接修改用户全局 Git 配置，除非用户明确要求。
- CPA 返回 HTTP 401（无认证）通常说明服务可达，不等于服务故障。
- Provider 返回 429、服务繁忙、认证错误时，先区分网络/服务问题与本地 Agent runtime 问题。

## 11. 上游同步标准流程

### 更新前

```bash
cd ~/code/Proma
git status -sb
git fetch upstream main
```

确认工作区干净后：

```bash
git checkout main
git rebase upstream/main
git -c 'http.https://github.com.proxy=' push --force-with-lease origin main
git checkout dev
git merge --no-edit main
```

### 合并冲突处理原则

优先保留本地定制：

- 删除 onboarding
- 删除 voice input
- 删除商业版推广
- DeepSeek 不自动重建
- `/goal` 目标功能
- 本地 Chat 工具体系

同时吸收上游正常更新，例如 Agent runtime、模型、MCP、Bridge、Markdown 编辑器等改进。

冲突处理后检查：

```bash
git grep -n -E '^(<<<<<<<|=======|>>>>>>>)( |$)' -- . ':!*.lock'
git diff --check
```

### 依赖和验证

```bash
bun install
bun run --filter='@proma/electron' sync:runtime-deps
bun run --filter='@proma/electron' typecheck
```

涉及构建规则、external 清单或运行时依赖时，至少执行：

```bash
bun run electron:build
```

最后：

```bash
git add -A
git commit -m "merge: 同步上游更新至 <commit>"
git -c 'http.https://github.com.proxy=' push origin dev
```

## 12. 自动同步 Workflow 的已知问题

文件：`.github/workflows/sync-with-upstream.yml`

该 workflow 每 6 小时或手动触发一次，只处理 `main`。此前收到失败邮件：

```text
[Lucifer1H/Proma] Run failed: Sync fork with upstream - main
```

排查原则：

- 先查看 Actions 具体失败步骤和日志，不要仅凭邮件标题猜测原因。
- 可能涉及上游合并冲突、远端分支状态、权限或 workflow 执行环境。
- 本地手动同步是可靠兜底。
- `dev` 不应由该 workflow 直接覆盖。

## 13. UI / Markdown 注意事项

### KaTeX 警告

曾出现：

```text
LaTeX-incompatible input and strict mode is set to 'warn':
Unicode text character "目" used in math mode [unicodeTextInMathMode]
```

这是 KaTeX 在 `$...$` 或 `$$...$$` 数学模式中遇到中文 Unicode 字符时的警告。它不影响使用，且尝试全局设置 `strict: false` 曾导致页面渲染异常，因此目前保持默认行为，暂不处理。

### Electron CSP 警告

开发模式可能出现：

```text
Electron Security Warning (Insecure Content-Security-Policy)
```

这是 Vite dev server 没有 CSP 或需要 `unsafe-eval` 的开发环境警告。通常只影响开发控制台观感，不影响功能。文件预览、截图预览等非信任内容页面已有更严格 CSP。除非用户明确要求安全加固，不要为了消除开发噪音贸然修改主界面 CSP。

## 14. 删除消息功能状态

曾经实现过 Agent 会话内删除单条消息，但用户后来明确要求回退，当前状态是：

- Agent 单条消息删除按钮：不存在
- `agent:delete-message` IPC：不存在
- `removeAgentSDKMessage`：不存在
- 相关回退提交：`6c6dbaaf`

不要自动重新加入该功能。

Chat 侧已有自己的删除能力，不要因为 Agent 删除功能被回退而误删 Chat 删除功能。

## 15. 当前版本和最近同步状态

本交接文档创建时的状态：

- 上游最新：`a39675c6`
- `main`：`84680c22`
- `dev`：`a4ab9cc5`
- 最近上游同步已完成，类型检查通过。
- 当前 dev 依赖修复脚本可用。

版本号可能随着后续上游同步变化，处理任务时应以实际 `package.json` 和 Git 状态为准，不要盲信本文档中的快照。

## 16. 工作方式建议

开始任何任务时：

1. 先读取本文件和根目录 `AGENTS.md`。
2. 检查 `git status -sb`，避免覆盖用户未提交改动。
3. 先搜索现有实现，再新增代码。
4. 修改 IPC 时检查四层契约。
5. 修改默认 Skill 时递增其 `SKILL.md` frontmatter `version`。
6. 修改 Agent runtime 或依赖后执行最小相关测试、typecheck，并视情况执行 Electron build。
7. 先给出诊断依据，再做修改；不要把 provider 错误误判成本地代码错误。
8. 提交前检查 `git diff`、`git diff --check` 和工作区状态。
9. 不要提交密钥、token、用户会话内容、个人路径之外的敏感数据。

## 17. 给新 AI 的简短指令

你正在维护的是一个带有个人定制的 Proma fork。默认目标不是“把代码改得像上游”，而是：

> 在吸收上游更新的同时，保留本文件第 3 节列出的所有本地行为；遵守第 5 节工程规范；遇到 Agent 无回答优先排查 Pi runtime 嵌套依赖和 Provider 日志；不要未经确认恢复已移除的 voice/onboarding/商业推广，也不要重新加入已回退的 Agent 单条消息删除功能。
