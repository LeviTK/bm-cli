# bm-cli 项目 Agent 文件（会话总结版）

## 1. 项目定位

`bm-cli` 的目标是基于 `beautiful-mermaid` 渲染引擎，构建一个面向 AI Agent 的 CLI 工具。

- 优先服务 Agent，而非人类交互流程。
- 支持终端直接显示图表（Unicode/ASCII）。
- 支持中文与英文输出。
- 执行后释放资源，保持 one-shot 低占用。

## 2. 关键设计结论（来自当前会话）

- 主路径采用 Agent-First：`agent capabilities`、`agent exec`、`agent batch`。
- 人类友好入口保留 `term`，但与 `agent exec` 复用同一执行核心。
- 输入输出以 JSON 协议为主，结构稳定：`id/ok/data/error/meta`。
- 错误处理采用 `error.code` + 双语消息（`messageZh`/`messageEn`）。
- 支持 heredoc/pipe/here-string：`<<`、`|`、`<<<`，默认无需落盘。

## 3. 技术栈结论

- 语言：TypeScript（strict）。
- 运行时：Bun（开发测试）+ Node 20（分发兼容）。
- 构建：tsup。
- 协议校验：JSON Schema + Ajv。
- 终端中文对齐：引入 CJK 宽度计算（wcwidth 类方案）。
- 分发建议：npm 包 + Bun 单二进制双轨并行。

## 4. 必做优先级

### P0

- CJK 宽度修复（避免中文导致 ASCII/Unicode 图错位）。
- 结构化错误输出（`errors[]` + `warnings[]` + 稳定错误码）。
- `term` 与 `agent` 执行核心统一。
- 确定性输出（同输入同输出）。

### P1

- `schemaVersion` 与请求/响应 Schema 校验。
- `capabilities` 固定能力声明。
- 可选 `recover` 解析模式（默认严格）。

### P2

- 布局引擎抽象（为未来替换 `dagre` 预留接口）。
- 可观测性（耗时、错误分布、成功率）。
- 更完整的分发与运维增强。

## 5. 实现边界

- 不依赖 GUI 运行状态，不引入浏览器渲染链路作为核心方案。
- 不在默认路径引入交互式 prompt。
- 不提前膨胀命令面，保持最小可用核心。

## 6. 代码与协议约束

- 协议优先，禁止仅依赖自然语言错误描述。
- 诊断信息尽量包含可定位上下文（如行列信息）。
- 兼容升级必须通过 schema 版本控制与 deprecations 清单。
- 任何新增命令需同步更新 `capabilities` 与文档。

## 7. 测试与验收

- 使用 golden fixtures 保障渲染回归。
- 对中文节点、混合中英文本、长标签场景进行专项测试。
- CI 分层执行：协议校验 / 渲染回归 / 工程检查。
- MVP 验收标准：
  - Agent 请求可稳定返回结构化 JSON。
  - 终端可直接渲染且中文不乱列。
  - 执行后无常驻进程，资源可及时释放。

## 8. 分发补充（Homebrew）

- 项目需支持 `brew install`，参考独立 tap 模式（`owner/homebrew-tap` + `Formula/*.rb`）。
- 默认推荐在 release 发布 `bm-cli-darwin-arm64.tar.gz` 与 `bm-cli-darwin-x64.tar.gz` 两个 macOS 产物。
- Formula 优先安装预编译二进制，避免用户侧额外运行时依赖。
- 每次 release 必须同步更新 Formula 的 `version` 与 `sha256`。
- 文档必须提供标准安装命令：
  - `brew tap <owner>/tap`
  - `brew install <owner>/tap/bm-cli`

## 9. 协议草案文件索引（v1.1 + v2）

- `drafts/agent-protocol/capabilities.response.v1.1.draft.json`
- `drafts/agent-protocol/agent-exec.request.v1.1.draft.json`
- `drafts/agent-protocol/agent-exec.response.success.text.v1.1.draft.json`
- `drafts/agent-protocol/agent-exec.response.success.image-inline.v1.1.draft.json`
- `drafts/agent-protocol/agent-exec.response.error.v1.1.draft.json`
- `drafts/agent-protocol/agent-exec.response.error.syntax.v1.1.draft.json`
- `drafts/agent-protocol/agent-batch.contract.v1.1.draft.json`
- `drafts/agent-protocol/syntax.profile.v1.draft.json`
- `drafts/agent-protocol/syntax.profile.v2.draft.json`
- `specs/bm-cli-mermaid-syntax-v2.md`
- `specs/bm-cli-syntax-implementation-routes.md`

约束：

- `agent exec/batch` 输出保持纯 JSON/JSONL。
- `image-kitty` 仅用于 `term` 路径，不污染 agent 协议流。

## 10. 当前会话确认的协议优化（必须遵守）

1. `agent --json` 通道与终端图片输出隔离
- `agent exec/batch` 保持纯 JSON/JSONL，不直接输出 Kitty escape。
- 图片输出仅用于 `term`，或在 agent JSON 中以 `png-inline`/`png-ref` 返回。

2. `capabilities` 拆分为静态与运行时
- `capabilities.static`：支持格式、限制、操作集合等稳定能力。
- `capabilities.runtime`：本次会话探测结果、探测方式与置信度。

3. `renderer=auto` 默认策略按命令上下文区分
- `term` 默认 `auto`。
- `agent exec/batch` 默认 `text`，仅显式请求时启用 `image`。

4. 错误模型增强可自动修复信号
- 在 `error.code` + 双语消息基础上，增加：
  - `error.category`
  - `error.retryable`
  - `error.suggestedAction`

5. `batch` 语义补齐幂等与部分失败策略
- 响应必须包含 `index` 与 `id/requestId`。
- 保证请求顺序与响应顺序一致。
- 明确 `continueOnError` 默认值与可重试错误白名单。

6. 版本兼容从“版本号”升级到“协商规则”
- 声明 `minSupportedSchema` 与 `maxSupportedSchema`。
- 弃用项必须给出生效日期（如 `removeAfter`），避免跨版本调用歧义。

## 11. Mermaid 语法规范（新增）

- 语法支持以 `drafts/agent-protocol/syntax.profile.v2.draft.json` 为准（v1 作为向后兼容保留）。
- 人类可读规范以 `specs/bm-cli-mermaid-syntax-v2.md` 为准。
- 默认策略：
  - 路线1（默认）：`agent exec/batch` 使用 `syntaxProfile=normalized-v2` + `syntaxMode=strict`
  - `term`：`syntaxProfile=normalized-v2` + `syntaxMode=compat`
  - 路线2（显式修复）：`syntaxProfile=normalized-v2` + `syntaxMode=recover`
- 语法错误需优先使用机器码：
  - `E_SYNTAX_UNSUPPORTED_DIAGRAM`
  - `E_SYNTAX_FORBIDDEN_DIRECTIVE`
  - `E_SYNTAX_PROFILE_MISMATCH`
  - `E_SYNTAX_NORMALIZE_FAILED`
  - `E_SYNTAX_RECOVER_EXHAUSTED`

## 12. bm-cli Skill（新增）

- 项目级 Skill 路径：`.claude/skills/bm-cli-syntax/SKILL.md`
- 用途：约束大模型按 `normalized-v2` 规范生成 Mermaid，必要时按 `recover` 进行可审计修复，并生成带 `syntaxProfile/syntaxMode` 的请求体。
