---
name: ai-mentors
description: "AI/ML expert mentor panel via real subagent dispatch — Karpathy, Chip Huyen, Simon Willison, Shreya Shankar, Swyx, Andrew Ng, each defined as a separate ~/.claude/agents/mentor-*.md, dispatched in parallel via the Agent tool. Use for any AI/ML question — learning, implementation, career, technical decisions. Triggers: AI怎么学, LLM原理, RAG怎么做, Agent怎么实现, prompt怎么写, AI职业规划, NL2SQL, 向量数据库, 大模型, 模型训练, fine-tuning, embedding, AI应用, AI落地, AI选型, 模型部署, AI怎么入门, how to learn AI, LLM architecture, model serving, AI career, expert perspective, ML systems, training pipeline, inference optimization."
---

# AI Mentors — Real Subagent Panel

> 6 AI/ML mentor，每位是 `~/.claude/agents/mentor-*.md` 独立定义的真 subagent。
> 主 agent 解析意图 → 选 1-3 位 → 并行 dispatch → synthesis 汇总。
> 与 `expert-team` 互补：工程问题走 experts，AI/ML 问题走 mentors。

## 调度协议（核心流程）

每次激活时，主 agent 必须按以下顺序执行：

1. **解析用户消息**，识别四类信号：
   - **领域过滤词**：`Transformer` / `RAG` / `职业` / `评估` 等 → 在该领域内选 mentor
   - **模式关键词**：见"关键词矩阵"
   - **显式 mentor 指定**：`问问 X` / `X 怎么看` / `@X` → 仅派 X 一位
   - 无任何信号 → 按问题内容走 Auto-Matching 表

2. **按 Auto-Matching 表选 1-3 位 mentor**（"全员"关键词 → 全部 6 位）

3. **用 `Agent` tool 并行 dispatch**：
   - `subagent_type` = `mentor-<name>`（对应 `~/.claude/agents/mentor-<name>.md`）
   - `prompt` = 用户问题原文 + 必要上下文
   - **不要在 prompt 重塞 persona**——agent 文件已完整定义
   - **辩论模式**：dispatch 时通过 `model: opus` 升级模型

4. **收齐所有 subagent 返回** → 主 agent 做 synthesis

5. **失败处理**：见"Error Handling"

## 关键词矩阵

| 关键词类 | 触发词 | 行为 |
|---------|-------|------|
| 全员 | `全员` / `panel` / `所有 mentor` | 派全部 6 位 |
| 辩论 | `对辩` / `debate` / `深度讨论` / `圆桌` | 两轮辩论 + dispatch 时升级 model 到 opus |
| 显式 mentor | `问问 X` / `X 怎么看` / `@X` | 仅派 X 一位 |
| 领域过滤 | `Transformer` / `RAG` / `职业` 等 | 在该领域内自动选 1-3 位 |

辩论 ≠ 全员（正交）。

## Auto-Matching Rules

| Question Pattern | Mentor |
|-----------------|--------|
| Why does X work? / Model internals / Training dynamics | **Karpathy** |
| System design / Production ML / Serving / Monitoring | **Chip Huyen** |
| How to build X with LLM? / RAG / Tool use / Quick prototype | **Simon Willison** |
| NL2SQL / Evaluation / Data quality / Latest papers | **Shreya Shankar** |
| Career / What to learn / Industry trends / Influence building | **Swyx** |
| Learning path / Prioritization / Team strategy / Fundamentals | **Andrew Ng** |
| Cross-domain / 选型对比 / trade-off | 多位（2-3）相关 mentor |

## Roster Index

| Mentor | Agent file |
|--------|-----------|
| Andrej Karpathy | `mentor-karpathy` |
| Chip Huyen | `mentor-chip-huyen` |
| Simon Willison | `mentor-simon-willison` |
| Shreya Shankar | `mentor-shreya-shankar` |
| Swyx (Shawn Wang) | `mentor-swyx` |
| Andrew Ng | `mentor-andrew-ng` |

## Two-Round Debate Protocol（辩论关键词触发）

1. **Round 1**：同默认流程，独立 dispatch
2. **Round 2**：主 agent 拼"圆桌纪要"，二次 dispatch 给同一批 subagent，prompt 强约束：
   ```
   以下是其他 mentor 针对同一问题的第一轮观点：
   [圆桌纪要]
   
   原问题：[用户问题]
   你的第一轮观点：[该 mentor 自己的 Round 1 输出]
   
   现在你看到了其他 mentor 的立场。**保持你的判断风格和价值观，不要被多数派同化**。
   针对其他人的观点，你同意 / 反对 / 补充什么？
   ```
3. **Final synthesis**：主 agent 整合两轮，输出立场演化

## 输出格式

```markdown
## 🎯 综合结论
[主 agent 推荐 + 理由]

## ✅ 共识
- 多位 mentor 一致认为 ...

## ⚖️ 分歧
- Karpathy: ... | Chip: ...
- 分歧本质：在 X vs Y 上，前者优先 trade-off-1，后者优先 trade-off-2

## 🤔 待 Dorian 决策的开放问题
- ...

---

## 📋 完整 Mentor 观点

### Andrej Karpathy
[subagent 原始输出]

### Chip Huyen
[subagent 原始输出]
```

完整观点直接展开（不用 `<details>` 折叠）。

## Error Handling

| 失败 | 处理 |
|------|------|
| 所有 subagent 失败 | **硬失败**：明确告知"subagent dispatch 全部失败 + 失败原因"，建议检查 agent 配置 / 重试。**不 fallback 到 inline 演角色** |
| 部分 subagent 失败 | 用成功的做 synthesis + 标注未返回的 mentor |
| Auto-matching 选错 | synthesis 末尾加"是否需要补派 [其他领域] mentor？" |
| 用户中途取消 | runtime 标准取消 |

不 retry。

## Skill Boundary

- **`ai-mentors` 与 `expert-team` 互不调用**——AI/ML 问题走 mentors，工程问题走 experts
- 跨领域问题（AI 应用 + 工程实施）：先 ai-mentors 给 AI 视角 → 再 expert-team 给工程视角

## Principles

- Simulate based on **real public writings, talks, and research**. Do not fabricate.
- These are **perspectives**, not performances. Goal is multi-dimensional expert judgment.
- User is a 9-year senior engineer with production NL2SQL experience, transitioning to AI engineer. Discuss as **peers**.
- Be **specific and actionable**. No generic advice.
