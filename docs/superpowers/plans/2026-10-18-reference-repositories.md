# Reference Repositories Workspace Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make seven complementary public repositories for AI agent workflows, context, and skills available locally alongside `obra-superpowers` for reference.

**Architecture:** Clone each upstream repository into an independent sibling directory in the workspace root. Preserve each repository's Git history and `origin`; do not modify repository contents or create a parent repository.

**Tech Stack:** Git for Windows, PowerShell, GitHub HTTPS remotes.

**Spec:** [2026-10-18-reference-repositories-design.md](../specs/2026-10-18-reference-repositories-design.md)

## Global Constraints

- Each clone retains its own Git history and upstream remote.
- The clones are independent repositories; they are not submodules and are not added to a shared parent repository.
- Do not install dependencies or run any of the repositories.
- Do not modify repository contents, settings, or remotes.
- Do not add submodules, a catalog file, or a workspace-level Git repository.
- Do not update or change `obra-superpowers`.
- Do not overwrite, delete, or repurpose an existing target directory.
- If a target exists or a clone fails, stop and report the affected path and error rather than silently skipping or replacing it.

## Review Focus

- An existing destination must not be overwritten: check all seven before cloning and stop if any exists.
- A failed clone must not be hidden by later work: clone sequentially and stop on the first nonzero exit code.
- Each repository must use its exact expected upstream URL as `origin`: verify all seven URLs after cloning.
- A partial run must not delete or replace completed clones: leave successful clones untouched and report remaining work.
- Clones must remain independent repositories: verify each Git top-level directory is its target directory.

---

### Task 1: Clone and Verify the Seven Reference Repositories

**Files:**
- Create: `C:\Users\andyk\OneDrive\Programming\VS Code\awesome-copilot\` (Git clone)
- Create: `C:\Users\andyk\OneDrive\Programming\VS Code\skills\` (Git clone)
- Create: `C:\Users\andyk\OneDrive\Programming\VS Code\compound-engineering-plugin\` (Git clone)
- Create: `C:\Users\andyk\OneDrive\Programming\VS Code\agents.md\` (Git clone)
- Create: `C:\Users\andyk\OneDrive\Programming\VS Code\deepagents\` (Git clone)
- Create: `C:\Users\andyk\OneDrive\Programming\VS Code\promptfoo\` (Git clone)
- Create: `C:\Users\andyk\OneDrive\Programming\VS Code\awesome-agent-skills\` (Git clone)

**Interfaces:**
- Consumes: the approved repository-to-directory mapping in the spec.
- Produces: seven independent local Git repositories with matching HTTPS `origin` remotes.

- [ ] **Step 1: Check all destination paths before making changes**

Run in PowerShell:

```powershell
$root = 'C:\Users\andyk\OneDrive\Programming\VS Code'
$names = @(
    'awesome-copilot',
    'skills',
    'compound-engineering-plugin',
    'agents.md',
    'deepagents',
    'promptfoo',
    'awesome-agent-skills'
)
$existing = $names | ForEach-Object {
    $path = Join-Path $root $_
    if (Test-Path -LiteralPath $path) { $path }
}
if ($existing) {
    $existing
    throw 'One or more clone destinations already exist. Stop without modifying them.'
}
```

Expected: no output and no error. If any destination is listed, stop and report it; do not clone into or remove it.

- [ ] **Step 2: Clone the repositories sequentially**

Run each command from PowerShell. After each command, confirm its exit code is zero before running the next; stop at the first failure and report the path and error.

```powershell
git clone https://github.com/github/awesome-copilot.git 'C:\Users\andyk\OneDrive\Programming\VS Code\awesome-copilot'
git clone https://github.com/anthropics/skills.git 'C:\Users\andyk\OneDrive\Programming\VS Code\skills'
git clone https://github.com/EveryInc/compound-engineering-plugin.git 'C:\Users\andyk\OneDrive\Programming\VS Code\compound-engineering-plugin'
git clone https://github.com/agentsmd/agents.md.git 'C:\Users\andyk\OneDrive\Programming\VS Code\agents.md'
git clone https://github.com/langchain-ai/deepagents.git 'C:\Users\andyk\OneDrive\Programming\VS Code\deepagents'
git clone https://github.com/promptfoo/promptfoo.git 'C:\Users\andyk\OneDrive\Programming\VS Code\promptfoo'
git clone https://github.com/VoltAgent/awesome-agent-skills.git 'C:\Users\andyk\OneDrive\Programming\VS Code\awesome-agent-skills'
```

- [ ] **Step 3: Verify each clone's root and upstream remote**

Run in PowerShell:

```powershell
$root = 'C:\Users\andyk\OneDrive\Programming\VS Code'
$expected = [ordered]@{
    'awesome-copilot' = 'https://github.com/github/awesome-copilot.git'
    'skills' = 'https://github.com/anthropics/skills.git'
    'compound-engineering-plugin' = 'https://github.com/EveryInc/compound-engineering-plugin.git'
    'agents.md' = 'https://github.com/agentsmd/agents.md.git'
    'deepagents' = 'https://github.com/langchain-ai/deepagents.git'
    'promptfoo' = 'https://github.com/promptfoo/promptfoo.git'
    'awesome-agent-skills' = 'https://github.com/VoltAgent/awesome-agent-skills.git'
}
foreach ($name in $expected.Keys) {
    $path = Join-Path $root $name
    $actualRoot = (& git -C $path rev-parse --show-toplevel).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Not a Git repository: $path" }
    $actualRemote = (& git -C $path remote get-url origin).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Missing origin remote: $path" }
    if ((Resolve-Path -LiteralPath $actualRoot).Path -ne (Resolve-Path -LiteralPath $path).Path) {
        throw "Unexpected Git root for $path : $actualRoot"
    }
    if ($actualRemote -ne $expected[$name]) {
        throw "Unexpected origin for $path : $actualRemote"
    }
    Write-Output "$name verified: $actualRemote"
}
```

Expected: one `verified` line for each of the seven repositories. If a check fails, report the repository and observed error; do not rewrite its remote or remove the clone.
