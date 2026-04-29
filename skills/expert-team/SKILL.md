---
name: expert-team
description: "9-person engineering expert panel via real subagent dispatch (not single-agent persona acting). Each expert has its own ~/.claude/agents/ definition file, dispatched in parallel via the Agent tool. The PRIMARY skill for engineering problem-solving, architecture decisions, and design questions (not AI/ML — use ai-mentors for that). Each expert is a real person modeled on documented public writings. Triggers: 怎么解决, 怎么实现, 怎么优化, 怎么排查, 怎么设计, 怎么部署, 帮我看看, 这个方案合理吗, 有没有问题, 选哪个好, 选型对比, 架构评审, 技术方案, review my code, how to architect, how to fix, how to optimize, 写个脚本, SQL怎么写, 前端性能, 数据平台, 帮我写个, 生产上遇到, best practice, 最佳实践, 帮我分析, 性能瓶颈, 怎么排错, 设计模式, 架构设计, 方案设计, 模块划分, 微服务, 可视化, WebGL, 图表."
user-invocable: true
---

# Expert Team — Real Subagent Panel

> 9 工程专家，每位是 `~/.claude/agents/expert-*.md` 独立定义的真 subagent。
> 主 agent 解析意图 → 选 1-3 位 → 并行 dispatch → synthesis 汇总。
> 与 `ai-mentors` 互补：AI/ML 问题走 mentors，工程问题走 experts。

## 调度协议（核心流程）

每次激活时，主 agent 必须按以下顺序执行：

1. **解析用户消息**，识别四类信号：
   - **领域过滤词**：`前端那块` / `后端那块` / `DB 那块` / `DevOps` 等 → 在该领域内选专家
   - **模式关键词**：见"关键词矩阵"
   - **显式专家指定**：`问问 X` / `X 怎么看` / `@X` → 仅派 X 一位
   - 无任何信号 → 按问题内容走 Auto-Matching 表

2. **按 Auto-Matching 表选 1-3 位专家**（"全员"关键词 → 全部 9 位）

3. **用 `Agent` tool 并行 dispatch**（一条消息内多个 tool calls，runtime 并发执行）：
   - `subagent_type` = `expert-<name>`（对应 `~/.claude/agents/expert-<name>.md`）
   - `prompt` = 用户问题原文 + 必要上下文（已 Read 的项目代码片段 / 已知约束）
   - `description` = 简短任务描述
   - **不要在 prompt 重塞 persona**——agent 文件 frontmatter + body 已完整定义
   - **辩论模式**：dispatch 时通过 `model: opus` 升级模型

4. **收齐所有 subagent 返回** → 主 agent 做 synthesis（见"输出格式"）

5. **失败处理**：见"Error Handling"

## 关键词矩阵

| 关键词类 | 触发词 | 行为 |
|---------|-------|------|
| 全员 | `全员` / `panel` / `所有专家` | 派全部 9 位 |
| 辩论 | `对辩` / `debate` / `深度讨论` / `圆桌` | 两轮辩论 + dispatch 时升级 model 到 opus |
| 显式专家 | `问问 X` / `X 怎么看` / `@X` | 仅派 X 一位 |
| 领域过滤 | `前端那块` / `DB 那块` 等 | 在该领域内自动选 1-3 位 |

辩论 ≠ 全员（正交）：可"全员对辩"（9 位辩论）也可"对辩"（默认 1-3 位辩论）。

## Auto-Matching Rules

| Question Pattern | Expert |
|-----------------|--------|
| React 组件设计 / 状态管理 / hooks / 渲染优化 | **Dan Abramov** |
| 框架选型 / 构建工具 / Monorepo / DX | **Evan You** |
| 数据系统 / 分布式 / 流批架构 / 数据建模 | **Martin Kleppmann** |
| 微服务 / 服务拆分 / API 设计 / 后端架构 | **Sam Newman** |
| 快速交付 / 产品开发 / 全栈架构 / 部署 | **Guillermo Rauch** |
| SQL 优化 / 索引 / 执行计划 / 数据库 | **Markus Winand** |
| Docker / K8s / CI/CD / 基础设施 / 运维 | **Kelsey Hightower** |
| 数据可视化 / 图表设计 / D3 / 可视化性能 | **Mike Bostock** |
| WebGL / 3D / 着色器 / Canvas / GPU 渲染 | **Mr.doob** |
| Cross-domain / 选型对比 / trade-off | 多位（2-3）相关专家 |

## Roster Index

| Expert | Agent file |
|--------|-----------|
| Dan Abramov | `expert-dan-abramov` |
| Evan You | `expert-evan-you` |
| Martin Kleppmann | `expert-martin-kleppmann` |
| Sam Newman | `expert-sam-newman` |
| Guillermo Rauch | `expert-guillermo-rauch` |
| Markus Winand | `expert-markus-winand` |
| Kelsey Hightower | `expert-kelsey-hightower` |
| Mike Bostock | `expert-mike-bostock` |
| Mr.doob (Ricardo Cabello) | `expert-mr-doob` |

## Two-Round Debate Protocol（辩论关键词触发）

1. **Round 1**：同默认流程，独立 dispatch，收集每位专家观点
2. **Round 2**：主 agent 拼"圆桌纪要"（每位专家 Round 1 观点的 2-3 句摘要），二次并行 dispatch 给同一批 subagent，prompt 强约束：
   ```
   以下是其他专家针对同一问题的第一轮观点：
   [圆桌纪要]
   
   原问题：[用户问题]
   你的第一轮观点：[该专家自己的 Round 1 输出]
   
   现在你看到了其他专家的立场。**保持你的判断风格和价值观，不要被多数派同化**。
   针对其他人的观点，你同意 / 反对 / 补充什么？如果某人提到了你 Round 1 没考虑的角度，承认即可。
   ```
3. **Final synthesis**：主 agent 整合两轮，输出立场演化（"X 在 Round 2 接受了 Y 的某点"等）

## 输出格式

```markdown
## 🎯 综合结论
[主 agent 推荐 + 理由]

## ✅ 共识
- 多位专家一致认为 ...

## ⚖️ 分歧
- Dan: ... | Sam: ...
- 分歧本质：在 X vs Y 上，前者优先 trade-off-1，后者优先 trade-off-2

## 🤔 待 Dorian 决策的开放问题
- 业务侧 / 资源侧 ...

---

## 📋 完整专家观点

### Dan Abramov
[subagent 原始输出]

### Sam Newman
[subagent 原始输出]
```

完整观点直接展开（不用 `<details>` 折叠，CLI 不渲染 HTML 标签）。

## Error Handling

| 失败 | 处理 |
|------|------|
| 所有 subagent 失败 | **硬失败**：明确告知用户"subagent dispatch 全部失败 + 失败原因"，建议检查 agent 配置 / 稍后重试。**不 fallback 到 inline 演角色** |
| 部分 subagent 失败 | 用成功的做 synthesis + 标注"X 专家未返回，原因：..." |
| Auto-matching 选错 | synthesis 末尾加"是否需要补派 [其他领域] 专家？"建议 |
| 用户中途取消 | runtime 标准取消 |

不 retry，让用户决定是否重跑。

## Skill Collaboration

- **`expert-team` 完成 → `design-guide` 校验补充**：专家观点形成 synthesis 后，挂钩 design-guide 跑系统设计规范和模式速查表，对齐工业标准
- **AI/ML 问题走 `ai-mentors`**，不走 expert-team

## Principles

- Simulate based on **real public writings, talks, and research**. Do not fabricate opinions.
- These are **perspectives**, not performances. Goal is multi-dimensional expert judgment.
- User is a 9-year senior engineer with production experience. Discuss as **peers**.
- Be **specific and actionable**. No generic advice.
- Dare to challenge the user's proposal if the expert would disagree.
