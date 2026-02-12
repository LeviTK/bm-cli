# bm-cli 语法实现路线（Route1 -> Route2）

## 1. 目标

本文件定义两阶段实现顺序：

1. Route1：全量支持 + 规范化 + Skill 约束
2. Route2：兼容层修复 + 自动降级

并给出“单实现 + 多策略”落地方式，避免维护两套分叉解析器。

## 2. Route1（先执行）

### 2.1 范围

- 全量支持 5 类图语法（flow/state/sequence/class/ER）
- 引入 `full-v2` 与 `normalized-v2` profile
- 默认走 `normalized-v2 + strict`
- 更新项目 Skill，约束大模型稳定生成

### 2.2 关键产物

- `drafts/agent-protocol/syntax.profile.v2.draft.json`
- `specs/bm-cli-mermaid-syntax-v2.md`
- `.claude/skills/bm-cli-syntax/SKILL.md`（v2 规则）

### 2.3 关键实现点

1. Parser/Validator 识别 5 类图完整构造。
2. Normalizer 把等价写法折叠为 canonical 写法。
3. ErrorModel 输出结构化错误码与可定位信息。
4. Capabilities 暴露 `profiles/modes/idPolicy`。

### 2.4 验收

- 五类图语法通过率显著提升。
- 无兼容层时，`strict` 行为仍然确定可预测。
- LLM 产物可直接执行，减少人工修图。

## 3. Route2（后执行）

### 3.1 范围

- 增加 Compatibility Layer（仅一层，不新增第二解析器）
- 在 `recover` 模式下执行规则化修复
- 补充“可自动修复”错误信号，支持上游 agent 自动决策

### 3.2 修复策略

可修复示例：

- 图头别名与方向缺失修复
- ID 非法字符替换（保留映射）
- sequence 块缺失闭合补全（低风险场景）
- class/ER 关系符号标准化

不可静默修复：

- 语义歧义无法判定
- 安全敏感 init 指令
- 可能导致关系含义变化的结构改写

### 3.3 错误模型扩展

错误对象建议增加：

- `error.category`
- `error.retryable`
- `error.suggestedAction`
- `error.recoverable`

### 3.4 验收

- `recover` 模式修复成功率可量化。
- 所有自动修复都有审计字段（`meta.recover.*`）。
- 不出现“成功但语义漂移不可见”的静默错误。

## 4. 单实现 + 多策略（推荐）

### 4.1 定义

- 单实现：一套 Parser + Validator + Normalizer 主干
- 多策略：通过 `profile/mode/policy` 控制行为，而非复制实现

### 4.2 为什么比“全量实现 + 独立兼容层分叉”更好

- 共享 AST 和规则库，测试资产可复用。
- 不会出现两套语义边界逐步偏离。
- 新增图语法时只改一处核心逻辑。
- 维护成本随功能增长更可控。

### 4.3 可能代价

- 策略矩阵变复杂（profile x mode x route）
- 需要更严格的回归测试设计

控制方法：

- 把策略定义数据化（JSON profile + policy table）
- 每次改动自动跑策略矩阵测试

## 5. “全量支持+规范化” 与 “兼容层修复” 的区别

1. 目标不同
- 全量支持+规范化：提升“可表达性 + 生成一致性”
- 兼容层修复：提升“坏输入下的可执行率”

2. 触发时机不同
- 规范化：所有请求都执行
- 兼容修复：通常仅 `recover` 或显式开启

3. 风险模型不同
- 规范化：低风险，强调语义等价
- 兼容修复：中风险，需要审计与置信度

4. 成功指标不同
- 规范化：确定性与回归稳定
- 兼容修复：失败率下降与自动恢复率提升

## 6. 对 bm-cli 的破坏性评估

结论：按“单实现 + 多策略”实施时，破坏性可控。

- 向后兼容：保留 v1 profile，新增 v2 profile 显式启用
- 运行时兼容：默认仍可采用稳健策略（`normalized-v2 + strict`）
- 升级路径：从 `compat` 观察告警，再逐步启用 `recover`

## 7. 执行顺序建议

1. 先完成 Route1（规范先行，确保主路径稳定）。
2. 再补 Route2（兼容修复作为增益层）。
3. 最后扩展自动化测试矩阵与发布说明。
