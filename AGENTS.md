# bm-cli — 项目 Agent 指令

## 1. 项目概述

`bm-cli` 基于 `beautiful-mermaid` 渲染引擎，构建 Agent-First 的 Mermaid CLI。仓库已包含完整渲染引擎（`src/`），CLI 层正在构建中。

## 2. 仓库结构

```
bm-cli/
├── AGENTS.md                  ← 本文件（项目约束，必须遵守）
├── src/                       ← 渲染引擎（beautiful-mermaid，不轻易改动）
│   ├── index.ts               ← 公共 API: renderMermaid() / renderMermaidAscii()
│   ├── ascii/                 ← 终端渲染器（Unicode/ASCII）
│   ├── class/ er/ sequence/   ← 各图类型渲染管线
│   ├── parser.ts              ← Mermaid 解析器
│   ├── layout.ts              ← dagre 布局
│   ├── renderer.ts            ← SVG 渲染
│   ├── theme.ts               ← 主题系统（14+ 主题）
│   ├── types.ts               ← 核心类型定义
│   └── __tests__/             ← 渲染引擎测试 + golden fixtures
├── src/cli/                   ← CLI 层（待建/正在建设）
│   ├── main.ts                ← CLI 入口（parseArgs 路由）
│   ├── core/execute.ts        ← 统一执行内核（term 与 agent 共享）
│   ├── commands/              ← 命令实现
│   │   ├── agent-capabilities.ts
│   │   ├── agent-exec.ts
│   │   ├── agent-batch.ts
│   │   └── term.ts
│   └── protocol/              ← 协议类型、错误码、编解码
│       ├── types.ts
│       └── errors.ts
├── doc/                       ← 设计文档（详细信源，不参与构建）
│   ├── AGENTS.md              ← 历史会话总结版（存档参考）
│   ├── 技术栈文档.md
│   ├── 项目设计文档.md
│   ├── drafts/agent-protocol/ ← 协议 JSON 草案（9 个文件）
│   └── specs/                 ← 语法规范（3 个文件）
├── homebrew/                  ← Homebrew 分发配置
├── .claude/skills/            ← 项目级 Skill
├── package.json               ← 当前仍为 beautiful-mermaid，需改名 bm-cli
├── tsconfig.json
└── tsup.config.ts             ← 需增加 CLI entry
```

## 3. 技术栈约束

- **语言**: TypeScript strict，与渲染引擎保持一致
- **运行时**: Node 20（分发），开发时可用 Bun
- **构建**: tsup（ESM/CJS + CLI bin 入口）
- **CLI 解析**: 原生 `parseArgs`，不引入重型框架
- **协议校验**: JSON Schema + Ajv（P1 阶段引入）
- **测试**: 渲染引擎用现有 `bun test`，CLI 层补充集成测试

## 4. 核心 API（渲染引擎，已就绪）

```typescript
// SVG 渲染（异步）
renderMermaid(text: string, options?: RenderOptions): Promise<string>

// 终端渲染（同步）
renderMermaidAscii(text: string, options?: AsciiRenderOptions): string
// AsciiRenderOptions.useAscii: true=ASCII, false=Unicode（默认）

// 支持图类型: flowchart / stateDiagram-v2 / sequenceDiagram / classDiagram / erDiagram
// 主题系统: THEMES 对象，14+ 主题，bg/fg + 可选 enrichment colors
```

## 5. 协议规范（必须遵守）

### 5.1 响应结构（判别联合）

```jsonc
// 成功
{ "id": "req-001", "ok": true,
  "data": { "format": "terminal-unicode", "content": "...", "warnings": [] },
  "error": null,
  "meta": { "durationMs": 12, "engine": "beautiful-mermaid",
            "renderMeta": { "requestedRenderer": "text", "actualRenderer": "text", "fallbackReason": null },
            "trace": { "parseMs": 2, "layoutMs": 4, "renderMs": 5, "serializeMs": 1 } } }

// 失败
{ "id": "req-001", "ok": false, "data": null,
  "error": { "code": "E_PARSE_SYNTAX", "category": "syntax", "retryable": false,
             "messageZh": "...", "messageEn": "...",
             "details": {}, "range": null, "suggestedAction": "..." },
  "meta": { "durationMs": 1 } }
```

### 5.2 错误码字典

| 错误码 | 类别 | 说明 |
|---|---|---|
| `E_PARSE_HEADER` | syntax | 图头解析失败 |
| `E_PARSE_SYNTAX` | syntax | Mermaid 语法错误 |
| `E_SYNTAX_UNSUPPORTED_DIAGRAM` | syntax | 不支持的图类型 |
| `E_SYNTAX_FORBIDDEN_DIRECTIVE` | syntax | 禁用指令 |
| `E_SYNTAX_PROFILE_MISMATCH` | syntax | 语法不符合 profile 要求 |
| `E_UNSUPPORTED_TYPE` | validation | 不支持的输出格式 |
| `E_INVALID_OPTION` | validation | 参数冲突或非法 |
| `E_TIMEOUT` | runtime | 执行超时 |
| `E_LIMIT_EXCEEDED` | runtime | 输入/输出超限 |
| `E_INTERNAL` | internal | 未预期内部错误 |

### 5.3 进程退出码

- `0` 成功 / `2` 请求参数错误 / `3` 渲染失败 / `4` 系统错误

### 5.4 命令行为差异

| 行为 | `agent exec/batch` | `term` |
|---|---|---|
| 输出格式 | 纯 JSON/JSONL | 终端直出文本 |
| 默认 renderer | `text` | `auto` |
| image-kitty | 仅 `png-inline`/`png-ref` 字段 | 直接写终端 escape |
| syntaxMode 默认 | `strict` | `compat` |

## 6. 编码规则

- CLI 层代码放 `src/cli/`，不改动 `src/` 根目录的渲染引擎文件
- `term` 与 `agent exec` 共享 `src/cli/core/execute.ts` 执行内核，禁止双实现
- 响应体用 `data.format + data.content` 判别联合，禁止 `terminal: ... / svg: null` 占位
- JSON 字段顺序固定，确定性输出（同输入同输出，排除 `durationMs`）
- 错误必须返回 `error.code`，禁止仅靠自然语言描述
- `agent exec/batch` 的 stdout 仅输出 JSON，禁止混入终端 escape
- 不引入交互式 prompt，不引入重型 CLI 框架
- 新增命令必须同步更新 `capabilities` 输出

## 7. 分批开发计划

### Batch 1 — 最小可运行 CLI ✅ 验收条件在下方

| 任务 | 产出文件 |
|---|---|
| `package.json` 增加 `bin.bm`，改名 `bm-cli` | `package.json` |
| `tsup.config.ts` 增加 CLI entry | `tsup.config.ts` |
| CLI 入口（`parseArgs` 路由） | `src/cli/main.ts` |
| `agent capabilities --json` | `src/cli/commands/agent-capabilities.ts` |
| `agent exec --json`（stdin JSON → 渲染 → stdout JSON） | `src/cli/commands/agent-exec.ts` |
| `term`（heredoc/pipe → 终端直出） | `src/cli/commands/term.ts` |
| 统一执行内核 | `src/cli/core/execute.ts` |
| 协议类型定义 | `src/cli/protocol/types.ts` |
| 错误码字典 + 双语消息 | `src/cli/protocol/errors.ts` |

验收：
```bash
echo '{"op":"render","input":{"text":"graph LR; A-->B"},"output":{"format":"terminal-unicode"}}' | npx bm agent exec --json
npx bm agent capabilities --json
echo "graph LR; A-->B" | npx bm term
```

### Batch 2 — 协议稳定化 + 错误模型

- 错误模型完整化: `code/category/retryable/suggestedAction/messageZh/messageEn`
- 成功响应增加 `warnings[]`
- `meta.trace` 阶段耗时（parse/layout/render/serialize）
- 确定性输出: 固定 JSON 字段顺序
- 进程退出码映射（0/2/3/4）

### Batch 3 — 协议草案修复

- `agent-exec.request` 删除 `options.recover`（`syntaxMode=recover` 已表达）
- `capabilities` 增加 `normalized-v2` / `full-v2` profile
- `capabilities` 增加 `engine.version`
- `image-inline` 响应补齐 `meta.trace`
- `batch` contract 增加 `schemaVersion` / `requestId`
- SKILL.md 删除 `options.recoverPolicy`

### Batch 4 — 测试骨架 + golden fixtures

- CLI 集成测试: capabilities / exec / term
- 5 类图 × unicode/ascii golden 文件
- 中文/emoji/混排节点 golden 用例
- 协议回归: 冲突参数、错误码 snapshot

### Batch 5 — batch 命令 + 资源保护

- `agent batch --jsonl` 流式处理
- `continueOnError` + 响应顺序保证
- `limits` 检查: `timeoutMs` / `maxInputBytes`
- 超时中断 + `E_TIMEOUT` / `E_LIMIT_EXCEEDED`

### Batch 6 — 文档收敛 + CI

- 三份文档去重（AGENTS 仅指针，设计文档为信源，技术栈仅选型）
- GitHub Actions CI: 类型检查 + 测试
- Homebrew `update_formula.sh` 修复 BSD sed 兼容

### 后续批次（P1/P2）

- **Batch 7**: CJK 字素簇宽度模块，patch 上游 ASCII 渲染
- **Batch 8**: 终端能力探测 + `renderer=auto` 回退链
- **Batch 9**: `image-kitty` 渲染链路（`@resvg/resvg-js` + Kitty 协议）
- **Batch 10**: Syntax Profile v2 校验层（normalize + recover）
- **Batch 11**: npm 发布 + Homebrew tap + release-manifest

## 8. 文档索引

| 文件 | 用途 |
|---|---|
| `doc/AGENTS.md` | 历史会话总结（存档参考） |
| `doc/项目设计文档.md` | 架构 + 协议 + 验收（唯一设计信源） |
| `doc/技术栈文档.md` | 技术选型与工程结构 |
| `doc/drafts/agent-protocol/*.json` | 协议 JSON 草案（9 个） |
| `doc/specs/*.md` | 语法规范（3 个） |
| `.claude/skills/bm-cli-syntax/SKILL.md` | 大模型语法约束 Skill |
