# Harness compatibility evidence

Checked on 13 October 2026. Baseline: `83e05bc`.

## Approach

Both harnesses load the same skill directories and Rails procedures. Each entry
point carries its own execution rules: native operations, installed resource
paths, explicit app working directory, answer waiting and command completion.
Companions are loaded from their actual installed entry points and keep the
parent request's mutation limits. Repository maintenance rules live in
`AGENTS.md`; Claude's maintenance entry point imports that file.

The Claude plugin identities and manifests are unchanged. Codex uses local
skills; no Claude manifest or global tool mapping is needed. Detection scripts,
pattern files, report templates, supported versions and upgrade order are unchanged.

## Material issues and corrections

| File or surface | Previous failure risk | Correction |
|-----------------|-----------------------|------------|
| `CLAUDE.md` | Codex could miss maintenance conventions; app runtime could be told to read a file outside the installed skill | Shared maintenance source in `AGENTS.md`, with a Claude import; runtime rubric references removed from workflows |
| `rails-upgrade/SKILL.md` and cleanup entry point | Different tool availability could change questions, stop conditions or command results | Self-contained native operation, chat fallback and wait rules; explicit roots and exit-status evidence |
| Detection workflow | Claude `Grep`/`Read`/`Glob` schemas do not match Codex; regex errors could appear as clean findings | Action/result searches and reads, line ranges, explicit regex error handling; bundled scanner remains primary |
| Reports and preview workflows | Fixed reader arguments and ambiguous installed paths | Native line-range reads and quoted absolute scanner paths |
| Companion handoffs | A plugin name could be treated as a tool; absent dependencies could be improvised; permissions could expand | Resolve installed entry point and resources, load procedure inline if needed, return evidence, stop dependent work on absence or incompatibility |
| README manual cleanup install | Outer plugin directory has no `SKILL.md` | Copy `upgrade-cleanup/upgrade-cleanup/` |
| CI path filters | Maintenance, manifests and compatibility checks could change without CI | Cover these paths and run the new compatibility check |

## Baseline and local checks

All seven requested baseline commands passed. The same commands pass after the
changes, together with `ruby bin/test-harness-compatibility` and `git diff --check`:

```text
ruby bin/validate-patterns
ruby bin/validate-patterns --self-test
ruby bin/test-patterns
ruby bin/test-patterns --self-test
ruby bin/lint-skill
ruby rails-upgrade/detection-scripts/scan_patterns.rb --self-test
ruby rails-upgrade/detection-scripts/gem_limits.rb --self-test
```

The new stdlib repository check copies both skills into temporary Codex and
Claude local layouts and Claude plugin layouts. It checks manifest roots,
metadata, resource bytes and cleanup workflow resolution. It executes the actual
bundled scripts from a separate Rails source fixture whose path contains spaces.
It verifies matching findings and gem limits, default and explicit hop selection,
read-only tree preservation, output under app `tmp/`, and nonzero errors for
missing lockfiles, guides and patterns. A deliberately injected native tool
schema fails the check. This is packaging and script evidence, not model parity.

Runtime detection scripts did not change. Ruby 2.1 execution was not rerun;
the existing compatibility contract and documented Docker checks remain intact.

## Harness evidence

| Harness | Observed evidence | Limit |
|---------|-------------------|-------|
| Codex CLI 0.162.1 | Actual app-server `skills/list` discovers all four copied skills with repository scope, enabled, and no parse errors | Discovery alone does not prove workflow execution |
| Codex readiness request | Actual model run loaded the copied skill, ran both bundled scripts from its installed path, inspected `widget.rb:3`, and answered Rails 4.0.13 -> 4.1 with the HIGH dynamic finder finding | Zero fixture byte mutations; no tests, setup, reports or boot. Final response omitted the reference's closing upgrade offer |
| Codex missing companion | Targeted Workflow 04 model run loaded the handoff rules, found `dual-boot` unavailable, stopped setup and linked its source | Zero fixture byte mutations; no guessed setup. Final response omitted an explicit install destination; this was not a full upgrade traversal |
| Claude Code 2.1.296 | Actual `plugin validate` passes all four packages; no-model initialization lists all four namespaced skill commands | Root maintenance `CLAUDE.md` warning is expected: it is not app runtime context |
| Claude model execution | `auth status` reports `loggedIn: false`, `authMethod: none`; no API key or OAuth token in the environment | Paired model requests cannot run until Claude is authenticated |

The engine is available through a cached Claude SDK executable, rather than on
PATH. These checks used disposable installations and session settings. They did
not overwrite installed skills or global configuration.

## Companion source checks

Temporary read-only source checkouts:

- `dual-boot`: `1e8a04d1691217ec19b61c817c7aec6e6bbde6e8`
- `rails-load-defaults`: `b2024f1c069bda9f631e26e9e776a05cd3e4bd16`

Both expose a direct skill directory, required metadata and portable procedures
that can be followed inline. Codex and Claude discovery accepts both packages.
Handoffs pass app/version/test state and permissions rather than assuming Claude
argument substitution. No external repository was modified or published.
Full companion execution is unverified while paired runtime testing is blocked.

## Existing policy conflicts

These precede this change. They are reported separately to preserve the Rails
methodology. If encountered, the shared execution rules stop the affected action
and ask for resolution rather than choose a policy by harness.

| Surface | Conflict |
|---------|----------|
| Request routing vs general gates | Analysis can continue with failed tests; generic baseline says stop. Reports-only permits dual-boot setup but prohibits fixes, while some general deprecation and boot gates require fixes. Use the request-specific limits; raise any remaining conflict. |
| Baseline edge cases | The long-suite menu offers skipping despite a non-negotiable test gate. No-test smoke exceptions differ between workflow gates and reference stop conditions. |
| Upgrade examples and preview | Some illustrative steps bump Rails or defaults directly and give estimates, while current workflows require dual-boot, later defaults alignment and no estimates. Entry point says examples do not replace gates. |
| Cleanup directions | General no-rollback wording conflicts with abandoning the hop. Missing next lockfile can skip Phase 1 despite remaining NextRails branches. Keep-next instructions for `NextRails.current?` do not explicitly describe keeping an `else` branch. |
| Cleanup approvals and publishing | Direction confirmation and per-destructive-step confirmation differ; final phases prescribe commit/push without establishing separate authority. Preserve permissions and existing gates. |
| Companion setup and CI | Setup can overwrite an existing next lockfile on resume; external CI guidance allows less frequent next-version jobs than the parent's every-PR gate. Preserve state and the parent gate. |
| Defaults during dual-boot | Parent requires defaults alignment between hops; external Rails 7.0 digest guidance requires ending old-version execution first. Stop the affected setting for a user decision. |

## Remaining acceptance work

Full parity is **unverified**. After Claude authentication, run equivalent
disposable app fixtures in both harnesses for readiness, analysis, reports only,
single-hop and multi-hop upgrades, failing baseline, missing companion, cleanup
keeping next, and cleanup keeping current. Compare selected workflows, findings,
artifacts, mutations, questions, stops and validation evidence. Do not compare
response wording. Static checks do not prove these model behaviours.

See [installation and invocation instructions](../README.md#how-to-use-this-skill).
The current discovery rules were checked against
[Codex skill documentation](https://learn.chatgpt.com/docs/build-skills),
[Claude skill documentation](https://code.claude.com/docs/en/skills),
[Claude plugin manifest documentation](https://code.claude.com/docs/en/plugins-reference)
and [Claude file imports](https://code.claude.com/docs/en/memory#import-additional-files).
