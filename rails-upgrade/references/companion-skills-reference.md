# Companion Skills Reference

Load this before a companion handoff. The companion's installed `SKILL.md` and
reachable resources are the procedure; do not replace them with guessed steps.

## Locate and load

Use the active harness's skill catalog to resolve the exact installed entry point:

| Companion | Used for | Source directory in its repository |
|-----------|----------|------------------------------------|
| `dual-boot` | Setup, code patterns and CI guidance | `dual-boot/` |
| `rails-load-defaults` | Defaults alignment after each completed hop | `rails-load-defaults/` |
| `upgrade-cleanup` | Ending dual-boot on an explicit request | `upgrade-cleanup/upgrade-cleanup/` in this repository |

Codex discovers local skills under `.agents/skills/` in the app or
`~/.agents/skills/`; request them with `$dual-boot`, `$rails-load-defaults` or
`$upgrade-cleanup`. Claude Code local skills use `.claude/skills/` or
`~/.claude/skills/` and `/dual-boot`, `/rails-load-defaults` or `/upgrade-cleanup`.
Claude plugin skills use `/dual-boot:dual-boot`,
`/rails-load-defaults:rails-load-defaults` and `/upgrade-cleanup:upgrade-cleanup`.
These are user invocation forms, not shell commands or mandatory tool names.
An agent may invoke a native skill capability, or read the resolved entry point
and follow it inline. Pass parameters in prose; do not assume argument substitution
or that a Claude plugin manifest installs a Codex skill.

Resolve each companion's own references from its installed directory. Before
executing, read its entry point and selected workflow and check that required
operations can use native tools under the current permissions. If a required
operation is incompatible, explain it and stop that dependent workflow.

If absent, name the missing companion and point to its source:
[dual-boot](https://github.com/ombulabs/claude-code_dual-boot-skill) or
[rails-load-defaults](https://github.com/ombulabs/claude-code_rails-load-defaults-skill).
Install the directory above in the active harness's local skills directory,
then start a session that discovers it. Cleanup is bundled here at the nested
directory above. Do not install or overwrite a user's skills without authority.
Read-only readiness and breaking-change analysis do not require these companions.

## Preserve the handoff contract

Pass the absolute app directory, request shape, current and target Rails versions,
existing Gemfile/lockfile state, baseline and deprecation sweep evidence, test
commands, pending approvals and allowed mutations. The companion may narrow
this scope but cannot expand it. Preserve existing lockfiles and unrelated work;
raise any destructive replacement for a user decision before doing it.

Questions require an answer even without a native question tool. Track command
completion and original exit status. Return changed files, boot and suite results
for both Rails versions, decisions and blockers to the parent workflow; do not
mark delegation complete merely because an invocation or worker started.

The local cleanup skill owns keep-next and keep-current cleanup. The external
dual-boot cleanup procedure is optional context; it must not replace that workflow.
