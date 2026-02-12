# bm-cli Mermaid 语法规范（v2 / Route1）

## 1. 目标

本规范用于把 `bm-cli` Mermaid 支持从 v1 子集提升到“全量支持 + 规范化输出”：

- 全量覆盖 5 类图：`flowchart` / `stateDiagram-v2` / `sequenceDiagram` / `classDiagram` / `erDiagram`
- 保留上游 Mermaid 主流能力，避免“描述能写、执行失败”
- 对大模型生成增加规范化约束，保证输出确定性与可回归

机器可读配置见：`drafts/agent-protocol/syntax.profile.v2.draft.json`。

## 2. 配置模型

语法行为由 `syntaxProfile + syntaxMode` 决定：

- `syntaxProfile`
  - `full-v2`：尽量完整的语法支持（表达优先）
  - `normalized-v2`：保留语义全量，但强制规范化格式（稳定优先）
- `syntaxMode`
  - `strict`：违规即失败
  - `compat`：违规告警，不自动修复
  - `recover`：可自动修复，并返回修复明细

默认建议：

- `agent exec/batch`：`normalized-v2 + strict`
- `term`：`normalized-v2 + compat`

## 3. 五类图全量支持说明

### 3.1 Flowchart

支持构造：

- 图头与方向：`flowchart`/`graph` + `TB/TD/BT/LR/RL`
- 节点：基础节点、带标签节点、形状节点
- 关系：实线/虚线/粗线、箭头、关系标签
- 结构：`subgraph` + `direction`
- 样式：`style`、`classDef`、`class`、`linkStyle`
- 交互：`click`
- 初始化指令：`%%{init:...}%%`

支持难度：中。

- 原因：语法分支多，但解析结构稳定，规则主要集中在 token 与关系定义。

可行性：高。

- 当前项目已具备 flowchart 主路径，扩展点主要在校验层与规范化层，不需重写渲染核心。

### 3.2 State Diagram (`stateDiagram-v2`)

支持构造：

- 起止：`[*]`
- 状态：简单状态、复合状态、嵌套状态
- 迁移：带/不带标签迁移
- 特殊节点：choice/fork/join
- 指令：`direction`
- 注释：`note left of` / `note right of`

支持难度：中高。

- 原因：复合状态和并发状态的层级语义需要更严格 AST 约束。

可行性：高。

- 通过状态块闭合检查与层级规范化可以稳定落地。

### 3.3 Sequence Diagram

支持构造：

- 参与者：`participant`、`actor`、`create`、`destroy`
- 消息：同步/异步/虚线/开放箭头消息
- 生命周期：`activate` / `deactivate`
- 片段：`loop`、`alt`、`opt`、`par`、`critical`、`break`
- 分支关键字：`else`、`and`
- 背景块：`rect`
- 注释：`note left of`、`note right of`、`note over`
- 计数：`autonumber`

支持难度：高。

- 原因：控制块嵌套最复杂，错误通常是块不闭合或 `else/and` 归属错误。

可行性：中高。

- 需要在语法层引入块栈校验；实现复杂但边界清晰。

### 3.4 Class Diagram

支持构造：

- 类声明：`class X` 与块内成员
- 成员：字段/方法、可见性、静态/抽象标记
- 泛型：`Class~T~`
- 命名空间：`namespace`
- 关系：继承、实现、组合、聚合、依赖、关联
- 标签/基数：关系标签与 cardinality
- 反向写法与 inline member 语法

支持难度：高。

- 原因：关系语法和成员语法并存，且有多种等价写法。

可行性：中高。

- 通过“先声明后关系”的规范化和关系操作符白名单可控实现。

### 3.5 ER Diagram

支持构造：

- 实体与属性定义
- 属性修饰：`PK`、`FK`、`UK`、`comment`
- 关系线：`--`（identifying）/`..`（non-identifying）
- 多种基数组合：`||`、`|o`、`}|`、`}o`
- 关系标签

支持难度：中高。

- 原因：主要复杂度在基数组合的合法性校验与标准化输出。

可行性：高。

- 语法模式较固定，适合规则驱动实现。

## 4. 规范化规则（Route1 必须执行）

1. 一次请求只允许一个 Mermaid 图。
2. 图头规范化：`graph` 统一为 `flowchart`，`stateDiagram` 统一为 `stateDiagram-v2`。
3. ID 规则：`^[A-Za-z][A-Za-z0-9_-]*$`（允许连字符，禁止 Unicode ID）。
4. 标签允许中英文和 emoji，但不得进入 ID。
5. 行结束统一 `LF`，缩进统一 2 空格，去除行尾空白。
6. 语句推荐顺序：图头 -> 声明 -> 关系 -> 样式/注释。
7. 规范化不得静默删语义；发生改写必须写入 `warnings[]` 或 `meta.recover.*`。

## 5. Skill 约束（Route1）

项目 Skill 必须约束大模型：

- 默认输出 `normalized-v2 + strict`
- 只有用户显式要求“最大表达能力”时使用 `full-v2`
- 只有用户显式要求“尽量修复继续执行”时使用 `recover`
- 输出 JSON 请求体时必须携带：
  - `options.syntaxProfile`
  - `options.syntaxMode`

## 6. 实施与验收

实施最小闭环：

1. 语法识别：识别 5 类图头与构造。
2. 规则校验：按 profile + mode 返回结构化错误。
3. 规范化输出：生成 canonical Mermaid 文本。
4. 结果透出：在 `meta` 返回 `profile/mode/normalizeChanged`。

验收标准：

- 五类图各提供不少于 10 个 golden 用例（正常 + 边界 + 错误）。
- 相同输入重复执行结果一致（确定性）。
- `recover` 模式必须可审计（输出改写规则和置信度）。

## 7. 兼容性声明

- v1 仍可继续使用（向后兼容）。
- v2 作为新能力层按显式 profile 启用。
- 默认 profile 建议保持 `normalized-v2`，避免“全放开”导致回归噪声。
