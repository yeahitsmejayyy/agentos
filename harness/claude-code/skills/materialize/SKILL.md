---
name: materialize
description: Install a .proc module or scaffold's actual code into a project — the producing-half counterpart to recall. Recall injects a standard as guidance; materialize installs the artifact itself (a module's src/ + its bundled tests, or a scaffold's starting point). Only materializable entries (modules/scaffolds). Use when you want to USE a standard's code, not just read it.
allowed-tools: Read Bash
---

# materialize

Recall says *"here's the convention."* **Materialize** says *"install the actual thing."* It copies a
`materializable` `.proc` entry's code into a target project — a **module**'s `src/` + its bundled
`tests/` (the oracle), or a **scaffold**'s starting point. Principles and patterns are *recall-only*;
they have no code to install.

## Steps
1. **Identify** the entry and the target: which module/scaffold (under `$AGENT_OS_PROC`), and which
   project directory to install into.
2. **Confirm** with the user — show what will land (the file list) and where. Never overwrite.
3. **Run** the engine:
   ```bash
   bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/agent-os/../materialize.sh" <name> <target-dir>
   ```
   (it resolves `$AGENT_OS_PROC`, validates `materializable: true`, copies the code, **skips anything
   already present**, and reports each file). If the adapter path differs, call the repo's
   `harness/claude-code/materialize.sh <name> <target-dir>`.
4. **Report** what installed — and that the **bundled tests came with it**: a module isn't proven without
   its oracle, so run them to confirm the install conforms.

## Hard rules (CONSTITUTION)
- **Never overwrite.** Existing files are skipped, not clobbered (guard-the-irreversible). To replace one,
  the user deletes the old file first, deliberately.
- **Only materializable entries.** A `principle`/`pattern` has no code — recall it, don't materialize it.
- **The tests travel with the code.** A module's oracle is part of the standard; install it too.
- **Confirm before writing into a project.** Show the file list + target first.
