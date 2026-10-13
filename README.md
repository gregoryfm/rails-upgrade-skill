# Rails Upgrade Assistant Skill

A skill for Codex and Claude Code that helps you upgrade Ruby on Rails applications from version 2.3 through 8.1. Both harnesses use the same workflows, guides, patterns, templates and scripts.

## What Does This Skill Do?

The Rails Upgrade Assistant analyzes your Rails application and generates:

- **Comprehensive Upgrade Reports** - Detailed migration guides with OLD vs NEW code examples from your actual codebase
- **app:update Previews** - Shows exactly what configuration files will change when you run `rails app:update`

The skill follows a sequential upgrade strategy—you upgrade one minor/major version at a time (e.g., 5.2 → 6.0 → 6.1 → 7.0), never skipping versions.

## Why Trust This Skill?

This skill is built on real-world experience, not just documentation:

- **60,000+ developer hours** of Rails upgrade experience
- **Upgrades from Rails 2.3 to Rails 8.1** for clients worldwide
- Based on the methodology documented in ["The Complete Guide to Upgrade Rails"](https://www.fastruby.io/upgrade) ebook
- Created by the team at [FastRuby.io](https://fastruby.io), specialists in Rails upgrades since 2017

We've encountered (and solved) edge cases that don't appear in any documentation. This skill encapsulates that hard-won knowledge.

## How to Use This Skill

### Installation

Full upgrades use two companion skills: [rails-load-defaults](https://github.com/ombulabs/claude-code_rails-load-defaults-skill) and [dual-boot](https://github.com/ombulabs/claude-code_dual-boot-skill). Read-only next-hop readiness and breaking-change analysis do not require them. The cleanup skill lives at `upgrade-cleanup/upgrade-cleanup/SKILL.md`. Install the actual inner skill directory for a local install.

### Codex plugins from this fork

The `gregory-rails` marketplace includes `rails-upgrade`, `upgrade-cleanup`,
`dual-boot` and `rails-load-defaults`. The first two use this checkout's existing
plugin packages. Companion plugins use pinned upstream commits, so installing
the catalog does not silently select a newer procedure.

To install the PR revision from your terminal:

```bash
codex plugin marketplace add gregoryfm/rails-upgrade-skill --ref gm/codex-claude-compatibility
codex plugin add rails-upgrade@gregory-rails
codex plugin add upgrade-cleanup@gregory-rails
codex plugin add dual-boot@gregory-rails
codex plugin add rails-load-defaults@gregory-rails
codex plugin list --marketplace gregory-rails --json
```

After merging this PR, use `--ref main` instead. To test a local checkout,
register its absolute directory with `codex plugin marketplace add
/absolute/path/to/rails-upgrade-skill`. Marketplace paths resolve from that
checkout root, including cleanup's outer plugin directory.

Restart Codex, open a new chat in the Rails app, and select the installed skill.
The Plugins directory can also install plugins from the registered marketplace.
These commands change your Codex settings when you run them. The installation
test for this PR used a disposable container and did not run them on the host.

The catalog is at `.agents/plugins/marketplace.json`. Codex supports the
existing Claude-compatible manifests through its plugin loader; no workflow
copies or Codex-only manifests are needed. This is a private marketplace route,
not publication in the public plugin directory. See the
[official packaging documentation](https://developers.openai.com/plugins/build/plugins#marketplace-metadata).

### Codex or Claude Code local skills

From a checkout of the revision you want to use, prepare the companion sources:

```bash
RAILS_SKILL_REPO="$(pwd)"
git clone https://github.com/ombulabs/claude-code_dual-boot-skill.git /tmp/rails-upgrade-dual-boot
git clone https://github.com/ombulabs/claude-code_rails-load-defaults-skill.git /tmp/rails-upgrade-load-defaults
```

Use fresh temporary clone paths if these already exist. Then choose one destination:

```bash
# Codex: personal installation
RAILS_SKILLS_DEST="$HOME/.agents/skills"
# Or Claude Code: personal installation
# RAILS_SKILLS_DEST="$HOME/.claude/skills"
# Or app-scoped: absolute path to your Rails app, with the selected harness directory
# RAILS_SKILLS_DEST="/absolute/path/to/app/.agents/skills"
# RAILS_SKILLS_DEST="/absolute/path/to/app/.claude/skills"
```

Before copying, check that none of the four destination names already exists.
Do not merge into or overwrite an existing skill. Back it up or choose a fresh
app-scoped installation. Copy each complete skill, including its resources:

```bash
mkdir -p "$RAILS_SKILLS_DEST"
cp -R "$RAILS_SKILL_REPO/rails-upgrade" "$RAILS_SKILLS_DEST/rails-upgrade"
cp -R "$RAILS_SKILL_REPO/upgrade-cleanup/upgrade-cleanup" "$RAILS_SKILLS_DEST/upgrade-cleanup"
cp -R /tmp/rails-upgrade-dual-boot/dual-boot "$RAILS_SKILLS_DEST/dual-boot"
cp -R /tmp/rails-upgrade-load-defaults/rails-load-defaults "$RAILS_SKILLS_DEST/rails-load-defaults"
```

Start a new session in the Rails app. Codex discovers `.agents/skills` and
`~/.agents/skills`; Claude Code discovers `.claude/skills` and `~/.claude/skills`.
Confirm the four skills appear. If multiple installed versions share a name,
select the intended entry point. Copying a `.claude-plugin/plugin.json` file does
not install a local Codex skill; the plugin loader uses it when you install the
package through a marketplace.

### Claude Code plugins

The existing plugin names and marketplace routes remain supported. The
marketplace supplies its published revision; to test changes on your fork, use
the local install above or load this checkout for one Claude session:

```bash
claude --plugin-dir "$RAILS_SKILL_REPO" \
  --plugin-dir "$RAILS_SKILL_REPO/upgrade-cleanup" \
  --plugin-dir /tmp/rails-upgrade-dual-boot \
  --plugin-dir /tmp/rails-upgrade-load-defaults
```

Run that command from the intended Rails app directory after setting the absolute
checkout path. The plugin roots differ from local skill roots: cleanup's plugin
root is `upgrade-cleanup/`, while its skill root is one level further down.

**From inside the Claude Code CLI prompt (recommended):**

```
/plugin marketplace add ombulabs/claude-skills
/plugin install rails-upgrade@ombulabs-ai
/plugin install rails-load-defaults@ombulabs-ai
/plugin install dual-boot@ombulabs-ai
/plugin install upgrade-cleanup@ombulabs-ai
```

**From your terminal:**

```bash
claude plugin marketplace add https://github.com/ombulabs/claude-skills.git
claude plugin install rails-upgrade@ombulabs-ai
claude plugin install rails-load-defaults@ombulabs-ai
claude plugin install dual-boot@ombulabs-ai
claude plugin install upgrade-cleanup@ombulabs-ai
```

### Basic Usage

Open the intended Rails app directory in either harness. Explicit invocation:

| Installation | Upgrade | Cleanup |
|--------------|---------|---------|
| Codex local | `$rails-upgrade Upgrade this app to Rails 7.2` | `$upgrade-cleanup Keep next and clean up dual-boot` |
| Codex plugin | `$rails-upgrade:rails-upgrade Upgrade this app to Rails 7.2` | `$upgrade-cleanup:upgrade-cleanup Keep next and clean up dual-boot` |
| Claude Code local | `/rails-upgrade Upgrade this app to Rails 7.2` | `/upgrade-cleanup Keep current and abandon this hop` |
| Claude Code plugin | `/rails-upgrade:rails-upgrade Upgrade this app to Rails 7.2` | `/upgrade-cleanup:upgrade-cleanup Keep next and clean up dual-boot` |

These are chat commands, not terminal commands. Natural language also works:

```
"Upgrade my Rails app to 7.2"
"Help me upgrade from Rails 6.1 to 7.0"
"What breaking changes are in Rails 8.0?"
```

### Workflow

1. **Ask for an upgrade** → The agent runs the selected assessment and generates reports from your app.
2. **Complete the selected workflow** → A full upgrade continues through implementation and validation. A reports-only request stops after both reports. Required questions and approval gates wait for your answer in either harness.

## Available Commands

| Command | Description |
|---------|-------------|
| `$rails-upgrade` / `/rails-upgrade` / `/rails-upgrade:rails-upgrade` | Start the upgrade assistant using the invocation for your installation |
| "Finish the upgrade" / "Clean up dual-boot" / "Abandon this upgrade" | Trigger the `upgrade-cleanup` plugin. Asks whether to keep the next or current version, then drops `NextRails.next?` / `NextRails.current?` branches and retires dual-boot scaffolding. |
| "Upgrade to Rails X.Y" | Generate reports from detection results |
| "Show app:update changes" | Preview configuration file changes |
| "Plan upgrade from X to Y" | Get multi-hop upgrade strategy |

## Design Decisions & Best Practices

This skill implements the **FastRuby.io upgrade methodology**, which includes:

### Dual-Boot Strategy

Run your application with two versions of Rails simultaneously using the [`next_rails`](https://github.com/fastruby/next_rails) gem. This allows you to test both versions during the transition and deploy backwards-compatible changes before the version bump.

See the [dual-boot skill](https://github.com/ombulabs/claude-code_dual-boot-skill) for setup, code patterns, and CI configuration.

### Post-Upgrade Cleanup

Once a hop is finished (or abandoned), the `upgrade-cleanup` sibling plugin tears down the dual-boot scaffolding so the tree stops carrying two Rails versions in parallel. It is scoped tightly to scaffolding removal, not a kitchen-sink "finish the upgrade" pass.

Activate it with phrases like "finish the upgrade", "clean up dual-boot", or "abandon this upgrade". The workflow:

1. **Phase 0 - Pre-flight.** Detects Docker vs local, smoke-checks `bundle` / `bin/rails runner` on both sides, and asks whether to keep the **next** version (finishing) or the **current** version (abandoning / pausing the hop).
2. **Phase 1 - Dual-boot removal.** Drops `NextRails.next?` / `NextRails.current?` branches, strips the `next?` Gemfile method and conditional groups, sweeps for `deprecation_tracker` residue *before* removing `next_rails` (the gem ships `DeprecationTracker`; leftover `require`s break test boot), swaps lockfiles, and updates CI to drop the dual-boot job.
3. **Phase 2 - Old-version code retirement.** Monkey-patches, stale gem pins, `docker-compose.yml` / `compose.yaml` sister services (`web-next`, `worker-next` with `BUNDLE_GEMFILE: Gemfile.next`), and doc drift (`README`, `bin/setup`, `.tool-versions`, `Dockerfile`).
4. **Phase 3 - Housekeeping.** CI matrix entry, `Dockerfile` / `.ruby-version` / `.tool-versions` alignment for Ruby bumps.
5. **Phase 4 - Final verification.** Local or CI, with explicit fallback to CI when the local environment can't run tests.
6. **Phase 5 - Commit and PR.** Suggested commit messages, single-purpose PR.

Out of scope by design: `load_defaults` alignment (handled by `rails-load-defaults`), deprecation triage (next-hop work owned by `rails-upgrade`), and migration class suffix / `db/schema.rb` regen (upgrade artifacts, not cleanup).

### Sequential Upgrades Only

We **never skip versions**. Each Rails minor/major version introduces changes that build on previous versions. Skipping creates compound issues that are nearly impossible to debug.

```
✅ Correct: 6.0 → 6.1 → 7.0 → 7.1
❌ Wrong:   6.0 → 7.1 (skipping 6.1 and 7.0)
```

### Deprecation-First Approach

Before upgrading:
1. Enable deprecation warnings in your current version
2. Fix all deprecation warnings
3. Deploy those fixes to production
4. Then bump the Rails version

This reduces the upgrade to a single Gemfile change.

## What This Skill Doesn't Do

Be aware of these limitations:

| Limitation | Explanation |
|------------|-------------|
| **Gradual deployments** | This skill focuses on code changes, not deployment strategies. Rolling deployments, canary releases, and feature flags are outside its scope. |
| **Debugging monkeypatching issues** | If gems or your code monkeypatch Rails internals, you may encounter weird issues that require manual investigation. |
| **Accurate time estimates** | The difficulty ratings and time estimates are rough guidelines based on typical applications. Your mileage will vary based on codebase size, test coverage, and custom code complexity. |
| **Request boundaries** | Full upgrades include code changes. Reports-only work stops before implementation. Readiness is read-only. Cleanup needs an explicit request and a confirmed direction. |
| **Gem compatibility resolution** | While we note common gem version requirements, resolving complex dependency conflicts requires manual intervention. |
| **Rails LTS upgrades** | While many of the things this Skill can do will work to upgrade Rails LTS, the strategy for those apps will be different and the Rails source code is not the same as the main Rails repository |

## Contributing

`AGENTS.md` holds repository maintenance instructions; `CLAUDE.md` imports it.
Installed skills carry their own execution rules and do not depend on a global
tool mapping. See [compatibility evidence and remaining blockers](docs/harness-compatibility.md).

Run the repository checks before a PR:

```bash
ruby bin/validate-patterns
ruby bin/validate-patterns --self-test
ruby bin/test-patterns
ruby bin/test-patterns --self-test
ruby bin/lint-skill
ruby rails-upgrade/detection-scripts/scan_patterns.rb --self-test
ruby rails-upgrade/detection-scripts/gem_limits.rb --self-test
ruby bin/test-harness-compatibility
```

The compatibility check uses temporary local and plugin installations with a
separate fixture app. It checks packaging and script execution; passing it does
not prove model behaviour. Runtime scripts remain stdlib-only and Ruby 2.1
compatible. If they change, run the Docker Ruby 2.1 checks in `AGENTS.md`.

We welcome contributions! Here's how you can help:

### Adding or Updating Version Guides

1. Fork the repository
2. Create a branch: `git checkout -b add-rails-X-Y-guide`
3. Add/update files in `version-guides/`
4. Follow the existing format and structure
5. Submit a pull request

### Reporting Issues

- Found incorrect information? [Open an issue](https://github.com/ombulabs/claude-code_rails-upgrade-skill/issues)
- Have a suggestion? We'd love to hear it
- Encountered an edge case? Share your experience

### Guidelines

- Keep content factual and based on official Rails documentation
- Include code examples with BEFORE/AFTER patterns
- Test detection patterns against real codebases when possible
- New detection pattern? Add a `match`/`no_match` fixture to its `*.expectations.yml` file and run `bin/test-patterns` before opening a PR
- Attribute sources appropriately

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Sponsors

This project is sponsored by:

### [OmbuLabs.ai](https://ombulabs.ai) | Custom AI Solutions

We build custom AI solutions that integrate with your existing workflows. From Claude Code skills to full AI agent systems.

### [FastRuby.io](https://fastruby.io) | Ruby Maintenance, Done Right

The Rails upgrade experts. We've been upgrading Rails applications professionally since 2017, helping companies stay current and secure.

---

**Questions?** Open an issue or reach out to us at [hello@ombulabs.com](mailto:hello@ombulabs.com)
