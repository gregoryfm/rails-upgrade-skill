# Next-Hop Readiness Reference

**When to read this:** the request is the Next-Hop Readiness shape in `references/request-patterns-reference.md`: the user asks what stands between the app and the next Rails version ("what do I need to do to get to the next Rails version?", "are we ready for the next upgrade?"). It is a quick, read-only answer from the app's files, not an upgrade.

## Rules

- **One hop.** The answer covers the next version on the app's upgrade path, the hop the version guides start at its current Rails (the guide named `upgrade-<current>-to-*.md`: usually the next minor, a major when the line ends, as in 4.2 → 5.0, 6.1 → 7.0 and 7.2 → 8.0), the way `references/sequential-strategy-reference.md` plans hops. Never list what later versions remove, even when a scan or the user mentions them. If the user names a farther target, say the readiness check covers the next hop on the way there and name it.
- **Read-only.** No Gemfile or lockfile edits, no `bundle install`, no next_rails setup, no test suite run, no code fixes.
- **Only what ran.** Every item in the answer comes from the steps below. What they cannot see goes under "Not checked", not into a guess.

## Step 1: Patch status

Run `workflows/00-verify-latest-patch-workflow.md` Steps 1 and 2. Report the result; do not block on it. When the app is behind, the first item of the answer is the patch upgrade.

## Step 2: Gem limits

From the app root:

```bash
ruby <skill>/detection-scripts/gem_limits.rb
```

It reads `Gemfile.lock`, takes the next hop from the version guides, and lists every locked gem whose own gemspec excludes that Rails version. It needs no network and no `next_rails`. When `next_rails` is already in the bundle, `bundle exec bundle_report compatibility --rails-version=<target>` adds the version each capped gem can be bumped to (it needs network); otherwise list the capped gems without a target version.

A dual-boot app whose `Gemfile.next.lock` already pins the target has resolved the gem side of the hop: say so instead of listing the current lockfile's caps.

## Step 3: Code findings

From the app root:

```bash
ruby <skill>/detection-scripts/scan_patterns.rb --summary
```

With no `--target` it scans the hop after `Gemfile.lock`'s Rails version, the same hop as Step 2. Check that both outputs name the same hop. When the scanner stops because that hop has no patterns file, keep the hop: search the app by hand for each breaking change in that hop's version guide, the way `workflows/05-detect-breaking-changes-workflow.md` does when the scanner cannot run, and say in the answer that the code findings came from the guide. Before listing a HIGH finding, read one of its sites and drop the pattern when the site is not the API it describes (`workflows/05-detect-breaking-changes-workflow.md` Step 3). Treat UNSCANNED entries the same way.

## Step 4: Answer

Write it for the developer: no workflow numbers, no skill file paths.

```markdown
## Rails {CURRENT} → {TO}: what stands in the way

**Patch:** on {X.Y.Z}, the latest {X.Y} patch. / Upgrade to {X.Y.W} first.

**Gems capped below {TO}** ({N}): gem, locked version, declared limit, and the parent that pulls it in when it is not in the Gemfile. "None" when the list is empty.

**Fix before the bump** ({N} patterns, {S} sites): one line per pattern, HIGH first, with its site count and one file:line.

**Fix when ready** ({N} patterns): one line per pattern.

**Not checked:** the test suite and the deprecation warnings it prints (run it on the current version before starting the hop), boot under the target version, behavior changes no pattern can find.
```

End with one offer: start the upgrade to {TO}. A yes is a Full Upgrade request, which starts at Workflow 00.
