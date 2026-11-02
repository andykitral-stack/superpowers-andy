# Reference Repositories Workspace Design

## Goal

Make seven complementary public repositories for AI agent workflows, context,
and skills available locally alongside `obra-superpowers` for reference.

## Scope

Clone each upstream repository into a sibling directory in the workspace root:

| Repository | Local directory |
|---|---|
| `github/awesome-copilot` | `awesome-copilot` |
| `anthropics/skills` | `skills` |
| `EveryInc/compound-engineering-plugin` | `compound-engineering-plugin` |
| `agentsmd/agents.md` | `agents.md` |
| `langchain-ai/deepagents` | `deepagents` |
| `promptfoo/promptfoo` | `promptfoo` |
| `VoltAgent/awesome-agent-skills` | `awesome-agent-skills` |

Each clone retains its own Git history and upstream remote. The clones are
independent repositories; they are not submodules and are not added to a shared
parent repository.

## Out of Scope

- Installing dependencies or running any of the repositories.
- Modifying repository contents, settings, or remotes.
- Adding submodules, a catalog file, or a workspace-level Git repository.
- Updating or changing `obra-superpowers`.

## Execution and Failure Handling

Before cloning, check that each target directory does not already exist. Do not
overwrite, delete, or repurpose an existing directory. If a target already
exists, or a clone fails, stop and report the affected path and error rather
than silently skipping or replacing it.

## Acceptance Criteria

- All seven named repositories exist as sibling directories in the workspace.
- Each directory is a Git repository whose `origin` points to the matching
  upstream URL.
- No repository content is changed by this operation, and no dependencies are
  installed.
