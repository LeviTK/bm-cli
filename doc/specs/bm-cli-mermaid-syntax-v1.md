# bm-cli Mermaid 语法规范（v1）

## 1. 目标

本规范用于统一 `bm-cli` 的 Mermaid 输入语法，解决两个问题：

- 增加可控语法支持（`core-v1` / `extended-v1`）。
- 约束大模型输出，降低语法漂移导致的渲染失败与回归不稳定。

配套机器可读配置：

- `drafts/agent-protocol/syntax.profile.v1.draft.json`

## 2. 语法配置模型

`bm-cli` 使用 `syntaxProfile + syntaxMode` 双维度控制语法行为：

- `syntaxProfile`：定义可用图类型与构造集合。
- `syntaxMode`：定义校验与恢复策略。

默认值：

- `agent exec/batch`：`syntaxProfile=core-v1`，`syntaxMode=strict`
- `term`：`syntaxProfile=core-v1`，`syntaxMode=compat`

## 3. 支持图类型

`core-v1` 支持以下图类型：

- `flowchart`
- `stateDiagram-v2`
- `sequenceDiagram`
- `classDiagram`
- `erDiagram`

`extended-v1` 在 `core-v1` 基础上增加：

- `subgraph`
- `direction`
- `note over`

## 4. 规范化规则（LLM 必须遵守）

1. 每次请求只生成一个 Mermaid 图。
2. 第一行必须是图头（如 `flowchart TD`）。
3. 节点 ID 仅使用 ASCII 标识符，匹配：`^[A-Za-z][A-Za-z0-9_]*$`。
4. 文本标签可使用中英文和 emoji，但不允许把 emoji 放入节点 ID。
5. 语句顺序固定：图头 -> 声明 -> 关系。
6. 默认缩进 2 空格，行结束统一 LF。
7. 禁止在 `core-v1` 中使用以下构造：
   - `%%{init:...}%%`
   - `click`
   - `style`
   - `classDef`
   - `linkStyle`

## 5. 校验模式语义

- `strict`：
  - 未知指令报错。
  - 禁用构造报错。
  - 不自动改写。
- `compat`：
  - 未知指令告警。
  - 禁用构造报错。
  - 不自动改写。
- `recover`：
  - 未知指令告警。
  - 禁用构造告警。
  - 允许自动改写（仅删除/替换非关键指令）。

## 6. 建议错误码（语法相关）

- `E_SYNTAX_UNSUPPORTED_DIAGRAM`
- `E_SYNTAX_FORBIDDEN_DIRECTIVE`
- `E_SYNTAX_PROFILE_MISMATCH`

## 7. 大模型输出模板

```json
{
  "schemaVersion": "1.1",
  "op": "render",
  "input": {
    "text": "flowchart TD\n  A[Start] --> B[End]"
  },
  "output": {
    "format": "terminal-unicode"
  },
  "options": {
    "renderer": "text",
    "syntaxProfile": "core-v1",
    "syntaxMode": "strict"
  }
}
```

## 8. 实施建议

- 渲染前先做语法 profile 校验，再进入布局渲染。
- `recover` 模式下的改写必须写入 `warnings[]` 与 `meta.renderMeta.fallbackReason`。
- `capabilities` 必须返回语法 profile 与模式列表，供调用方自动适配。
