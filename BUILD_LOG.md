# Build log

Two things live in this file: the real story of how smartorganize got to
its current state, and the exact commands to rebuild it if this working
copy (or the machine it's on) disappears. Both are pulled from `git log`,
not from memory, so if a claim here stops matching the history, trust the
history and fix this file.

## How it got here

**Jul 28, commit `6622f57`.** The first commit lands everything at once:
`bin/smartorganize`, the four `lib/smartorganize/*.rb` files (cli, config,
organizer, version), and a Minitest spec with 5 tests and 19 assertions.
Commit message calls it "Day 1 of Ruby learning path," and the code backs
that up, comments explain what `attr_reader` does, what `&.` means, why
constants are ALL_CAPS. This is a teaching codebase as much as a working
one.

**Same day, three more commits.** `df91eff` adds a `Color` module (ANSI
codes, with a `tty?`/`NO_COLOR` check so output degrades gracefully when
piped). `ef6c745` adds `--dry-run` and `--verbose` via a hand-rolled
`parse_args` that separates flags from positional args regardless of
order. `410139d` adds human-readable file sizes, a y/n confirmation
prompt before `organize` actually moves anything, and `--force` to skip
it.

**Jul 30, `bd2696c`.** `--quiet` and `--recursive` show up, and scanning
gets split into `scan_directory` (flat) and `scan_recursive`
(`Dir.glob("**/*")`) so the recursive case doesn't bolt onto the simple
one.

**Aug 1, two commits.** `832d25f` fixes a real bug: the shebang in
`bin/smartorganize` had comments above it, which means the OS never saw
`#!` as the first two bytes and `./bin/smartorganize` silently fell
through to the wrong interpreter. Same commit splits the y/n prompt out
of `cmd_organize` into `confirmed?`, and swaps a couple of
machine-specific example paths in comments for generic ones. `8f28cf9`
adds GitHub Actions CI running the Minitest suite, pinned to whatever
Ruby version `.ruby-version` says. The commit message notes rubocop was
considered and skipped, no config for it yet, so a bare run would just
fail on unconfigured style rules.

**Aug 2, `038602e`.** Two bugs, related. `cmd_stats` and `cmd_undo` built
`Organizer.new` without passing `recursive: recursive?`, so
`smartorganize stats --recursive` quietly ignored the flag and only
looked at the top level. Fixing that exposed a second bug: `scan_recursive`
was passing the *base* directory into `build_file_entry` instead of each
file's actual containing directory, so any nested file resolved to a path
that didn't exist and blew up with `Errno::ENOENT`. The first bug was
invisible until someone tried to verify the fix and hit the second one.

**Aug 7, three commits.** `9e48e71` adds a CI workflow that scans commit
authors, committers, and messages for AI-tool names and blocks the merge
if it finds one. `8e4f8eb` is an empty "trigger GitHub re-index" commit,
no file changes. `27eae6a` widens the attribution check to also cover
`git log`'s author/committer fields specifically, not just message text.

**Aug 8, `d73309e`.** `docs/DESIGN.md` shows up with mermaid diagrams of
the command flow. Worth flagging: the diagrams describe
`scanner.rb`/`undo.rb`/`stats.rb` as separate files. They never existed
as separate files, that logic has lived inside `organizer.rb` since the
first commit. Treat DESIGN.md as an architecture sketch, not a literal
file map, until someone reconciles it.

**Aug 9, `0e7a7ce`.** A style pass strips em dashes out of the README and
every comment in `lib/` and `spec/`. Whatever the reasoning was, it's now
the house style for this repo: no em dashes in prose or comments here.

**Aug 12, `b5ed6dc`.** The README had said `gem install smartorganize`
since the first commit, but there was no `.gemspec` and no `Gemfile` in
the repo until this commit. Installing the gem as documented would have
failed at the `gem build` step for two straight weeks. Also touched the
AI-attribution workflow again in the same commit.

**Aug 13, `8940c33`.** `release.yml` and `prerelease.yml` land: a stable
tag (`v0.2.0`) builds and pushes to RubyGems plus cuts a GitHub Release,
an `-rc` tag (`v0.2.0-rc.1`) does the same but only shows up under
`gem install --pre`. Both refuse to run if the tag doesn't match
`lib/smartorganize/version.rb`; the stable one additionally checks the
tagged commit is actually an ancestor of `main`.

**This session.** Added `FEATURE_IDEAS.md` (18 concrete next steps, each
tied to a specific line of existing behavior) and `RELEASING.md`
(branch/version/tag conventions, matching the branch names the
AI-attribution workflow already watches). This file is the third piece.

## Where things actually stand

- `lib/smartorganize/version.rb` says `0.1.0`. Nothing has been tagged or
  pushed to RubyGems yet, the release workflows exist but haven't fired.
- `.ruby-version` pins `3.4.9`. On the machine this was written on, system
  Ruby is `2.6.10` and `3.4.9` is available separately through rbenv.
  The test suite passes on both, but CI only ever sees `.ruby-version`,
  so don't assume local `ruby -v` matches what CI runs.
- `ruby -Ilib -Ispec spec/smartorganize_spec.rb` currently reports 8 runs,
  31 assertions, 0 failures. That's grown from 5/19 at the first commit as
  flags and bug fixes picked up their own test coverage.
- No `RUBYGEMS_API_KEY` secret exists on the GitHub repo yet. Both release
  workflows will run tests and build the gem fine, then fail at the
  `gem push` step. RELEASING.md covers how to add it.
- Only `main` exists as a branch, locally and on `origin`. RELEASING.md
  describes a `dev` → `staging` → `main` flow, but `dev` and `staging`
  haven't been created. The AI-attribution workflow already watches all
  four names (`main`, `master`, `dev`, `staging`), so creating them later
  needs no CI changes.

## Rebuilding from scratch

"Zero human input" means different things depending on what's still
around. Here's both cases, and where the honest line is.

### The repo (or a mirror of it) still exists somewhere

This is the case that's fully scriptable, no prompts, no manual file
edits:

```bash
git clone git@github.com:landonkea/landonkea-smartorganize.git
cd landonkea-smartorganize

# match the pinned Ruby version instead of assuming one is already active
rbenv install --skip-existing "$(cat .ruby-version)"
rbenv local "$(cat .ruby-version)"

gem install bundler --no-document
bundle install

ruby -Ilib -Ispec spec/smartorganize_spec.rb
gem build smartorganize.gemspec
```

If `origin` is unreachable but a `git bundle` backup exists (see below for
how to make one), swap the first line for:

```bash
git clone smartorganize.bundle landonkea-smartorganize
```

Everything else in the sequence is identical, a bundle clone behaves like
a normal clone once it's on disk.

### GitHub itself is gone but the local `.git` history survives

Recreate the remote and push everything back up, still no prompts as long
as `gh` is already authenticated:

```bash
cd landonkea-smartorganize
gh repo create landonkea/landonkea-smartorganize --public \
  --source=. --remote=origin --push
git push origin --tags
git branch dev staging 2>/dev/null
git push origin dev staging
```

### True zero, no clone, no bundle, no GitHub, only this file

Here's the honest part: there isn't a scripted path back from nothing.
Every commit in the "How it got here" section above represents a real
decision (which bug got fixed, which flag got added, in what order), and
none of that is recoverable by running commands, it has to be rewritten.
This file can tell a future rebuild what the *result* should look like
(current file list, current behavior, current test count) but it can't
replay the process without a human or an agent re-deriving the code, at
which point it's a rewrite project, not a restore.

The actual fix for this scenario is to make sure it never happens:

```bash
# run this after any session that adds commits, keep the .bundle
# somewhere other than this machine
git bundle create smartorganize.bundle --all
git bundle verify smartorganize.bundle
```

A `git bundle --all` is a single file containing every branch, tag, and
commit, restorable with a plain `git clone` against it (shown above). It
costs one command and turns "true zero" into "repo still exists
somewhere," which is the scriptable case.

### The one step that can't be automated either way

Publishing to RubyGems needs a `RUBYGEMS_API_KEY` GitHub secret, and that
key has to come from a RubyGems account with publish rights. Once a human
has generated the key value, setting it is scriptable:

```bash
gh secret set RUBYGEMS_API_KEY --repo landonkea/landonkea-smartorganize
```

But generating the value itself means logging into rubygems.org with a
real account. RELEASING.md flags the same gap. No rebuild script gets
around it, and pretending otherwise would just mean the release workflows
fail at `gem push` with a confusing error instead of an expected one.
