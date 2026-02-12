---
name: bm-cli-syntax
description: Generate, normalize, and repair Mermaid syntax for bm-cli v2. Use when users ask to create Mermaid for bm-cli, fix bm-cli syntax errors, standardize Mermaid style, or produce agent exec/batch JSON with syntaxProfile and syntaxMode.
---

# bm-cli Syntax Skill (v2)

用于约束大模型在 `bm-cli` 场景下输出“可执行、可回归、可自动修复”的 Mermaid。

## 1. 使用目标

1. 优先生成可直接执行的 Mermaid。
2. 语法尽量完整覆盖 5 类图。
3. 输出格式稳定，减少回归噪音。
4. 在必要时提供可审计自动修复。

## 2. 图类型与默认策略

支持图类型（全量）：

- `flowchart`
- `stateDiagram-v2`
- `sequenceDiagram`
- `classDiagram`
- `erDiagram`

默认策略：

- `syntaxProfile=normalized-v2`
- `syntaxMode=strict`
- `renderer=text`（agent 通道）

切换规则：

- 用户明确要“最大语法表达”时，切到 `full-v2`。
- 用户明确要“尽量修复继续执行”时，切到 `recover`。
- `agent exec/batch` 不直接输出终端 escape，只输出 JSON。

## 3. 生成规范（必须遵守）

1. 一次请求仅输出一个 Mermaid 图。
2. 第一行必须是图头（如 `flowchart TD`）。
3. ID 规则：`^[A-Za-z][A-Za-z0-9_-]*$`（允许连字符）。
4. 标签可用中英文和 emoji，但 emoji 不进入 ID。
5. 缩进统一 2 空格，换行统一 LF，去掉行尾空白。
6. 语句顺序：图头 -> 声明 -> 关系 -> 样式/注释。
7. 不允许发明 Mermaid 私有语法关键字。

## 4. 五类图最小检查清单

### flowchart

- 图头方向合法（`TB/TD/BT/LR/RL`）。
- 边操作符与标签位置合法。
- `subgraph` 成对闭合。

### stateDiagram-v2

- `[*]` 起止节点使用合法。
- 复合状态块正确闭合。
- 迁移标签位置正确。

### sequenceDiagram

- 参与者声明优先于消息。
- `loop/alt/opt/par/critical/break` 块正确闭合。
- `else/and` 放在合法父块中。

### classDiagram

- 类声明/成员语法合法。
- 泛型 `~T~` 写法合法。
- 关系符号与 cardinality 组合合法。

### erDiagram

- 实体先定义后引用。
- 属性修饰仅用 `PK/FK/UK`。
- 基数组合与关系线（`--`/`..`）匹配。

## 5. 修复策略（仅 recover）

可自动修复：

- 图头别名统一（`graph` -> `flowchart`）。
- ID 非法字符替换并保留映射。
- 低风险块闭合补全。
- 关系符号标准化。

不可静默修复：

- 安全敏感 init 指令。
- 语义歧义无法唯一判定。
- 可能改变业务关系语义的重写。

## 6. 输出 JSON 时的固定字段

输出 `agent exec`/`batch` 请求体时必须包含：

- `schemaVersion`
- `op`
- `input.text`
- `output.format`
- `options.renderer`
- `options.syntaxProfile`
- `options.syntaxMode`

`recover` 时建议附带：

- `options.recover=true`
- `options.recoverPolicy`（例如 `safe-only`）

## 7. 推荐模板

```json
{
  "id": "req-001",
  "schemaVersion": "1.1",
  "op": "render",
  "input": {
    "text": "flowchart TD\n  start-node[Start] --> end-node[End]"
  },
  "output": {
    "format": "terminal-unicode"
  },
  "options": {
    "renderer": "text",
    "syntaxProfile": "normalized-v2",
    "syntaxMode": "strict"
  }
}
```

## 8. 参考文件

- `doc/drafts/agent-protocol/syntax.profile.v2.draft.json`
- `doc/specs/bm-cli-mermaid-syntax-v2.md`
- `doc/specs/bm-cli-syntax-implementation-routes.md`
