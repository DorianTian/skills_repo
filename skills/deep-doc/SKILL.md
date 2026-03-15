---
name: deep-doc
description: Generate deep technical analysis documents covering academic principles and engineering practice. Trigger when user asks to create/write/generate a technical deep-dive document, analysis doc, or 深度解析 document.
user-invocable: true
---

# Deep Technical Document Generator

Generate a comprehensive deep-dive technical document on the given topic.

## Topic

$ARGUMENTS

## Pre-flight

1. **Parse arguments**: Extract the topic and optional `--output` path. Default output: `/Users/tianqiyin/Documents/<topic>深度解析.md`
2. **Check existing docs**: Search `/Users/tianqiyin/Documents/` for existing documents on this topic. If found, inform the user and ask whether to overwrite or supplement.
3. **Scope confirmation**: Before writing, briefly confirm with the user:
   - The scope and depth level (source-code level / architecture level / engineering practice level)
   - Any specific sub-topics to focus on or skip
   - Target audience assumption (default: senior frontend engineer with 5+ years experience)

## Document Standards

**CRITICAL**: Follow ALL rules from the "深度技术文档规范" section in `~/.claude/CLAUDE.md`. Key requirements:

### Depth Requirements
- Every technical point must trace back to **underlying implementation** (source code, algorithms, data structures)
- No "black-box" descriptions — explain HOW things work, not just WHAT they do
- Include **time/space complexity analysis** where applicable
- Reference **source code paths** (e.g., `react-reconciler/src/ReactFiberBeginWork.js`)

### For Each Knowledge Point, Follow This Chain

```
Thesis (What & Why)
  → Underlying Principle (How - source code / algorithm level)
  → Evidence & Trade-offs (Why this approach over alternatives)
  → Code Example (runnable, with key lines annotated)
  → Production Application (real-world usage, config, tuning)
  → Limitations (when NOT to use, performance boundaries)
  → Pitfalls (production issues with root cause + solution)
```

### Document Structure

```
# Title

> **Scope**: one-line description of depth level
> **Conventions**: language/version constraints

## Table of Contents

## 一、Background & Motivation
## 二、Core Principles & Implementation
## 三 ~ N-3、Deep-dive Topics
## N-2、Comparison Analysis (if applicable)
## N-1、Production Pitfalls & Best Practices
## N、Interview Quick Answers (if applicable)
```

### Formatting Rules
- Major sections: Chinese ordinals (一二三四五...)
- Subtitles with `——` separator (e.g., `## 三、Inverted Index——The Soul of ES`)
- Comparisons in tables, flows in ASCII art
- Code blocks with language tags (```typescript / ```go / ```sql)
- Key terms **bold**, definitions in `> blockquote`
- Source references with file paths

## Writing Process

1. **Research phase**: Use WebSearch and WebFetch to gather authoritative sources (official docs, RFCs, source code repos, academic papers). Do NOT fabricate information.
2. **Outline phase**: Draft the table of contents and confirm structure with user before writing full content.
3. **Writing phase**: Write section by section. For each section:
   - Start with the core thesis
   - Dive into underlying implementation
   - Provide runnable code examples
   - Connect to production scenarios
   - Note pitfalls and limitations
4. **Review phase**: After completion, self-check:
   - [ ] Every principle has source-level explanation
   - [ ] Every principle has code examples
   - [ ] Production pitfalls section is substantive (not generic)
   - [ ] No black-box descriptions remain
   - [ ] Comparisons are multi-dimensional (not just "A is better")
   - [ ] ASCII architecture diagrams are accurate

## Quality Bar

- Target: a document that a **senior engineer** would find genuinely useful for deepening understanding, not a beginner tutorial
- Depth: equivalent to a well-written technical blog post on a top engineering blog (like Meta Engineering, Netflix Tech Blog)
- Accuracy: every claim must be verifiable. If unsure, mark with "[needs verification]" rather than guessing
- Length: as long as needed to cover the topic thoroughly. Typically 500-2000 lines for a major topic.
