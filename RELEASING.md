# Releasing smartorganize

This is a gem, not a hosted app, so there's no "server" to deploy. The
equivalent of dev/staging/prod here is **branches + version numbers**:
where code lives while it's being worked on, and what kind of version
number it gets when it ships.

## Branches

- **`dev`** — day-to-day work happens here. Commit early, commit often.
- **`staging`** — where a release candidate gets assembled and tagged for
  testing before it's trusted.
- **`main`** — stable, released code only. Anything tagged as a real
  version (`vX.Y.Z`, no suffix) has to come from `main`.

These three names aren't arbitrary: `.github/workflows/ai-attribution-check.yml`
already runs against `main`, `master`, `dev`, and `staging`, so the branching
convention just formalizes names the repo was already set up to expect.

Flow: work lands on `dev` → when it's ready to test, merge `dev` into
`staging` and cut an `-rc` tag there → once that's been checked out and
confirmed to work, merge `staging` into `main` and cut the real tag.

## Version numbers

`lib/smartorganize/version.rb` is the single source of truth for the gem's
version. Whatever tag you push has to match it exactly, or the release
workflows below will refuse to run. That mismatch is the most common way
a release goes out with the wrong code, so it's checked automatically
instead of trusted to memory.

- Stable release: version is plain semver, e.g. `0.2.0`. Tag: `v0.2.0`.
- Pre-release (release candidate): version has an `-rc` suffix, e.g.
  `0.2.0-rc.1`. Tag: `v0.2.0-rc.1`.

RubyGems understands the `-rc.1` suffix as a pre-release automatically,
it's part of how `Gem::Version` parses version strings. A gem published
with that version number won't show up for a plain `gem install
smartorganize`, only for `gem install smartorganize --pre`. That's what
makes it safe to publish an RC without it landing on anyone's machine by
accident.

## Cutting a pre-release

1. On `dev`, bump `VERSION` in `lib/smartorganize/version.rb` to something
   like `0.2.0-rc.1`. Commit it.
2. Merge `dev` into `staging`.
3. Tag the merge commit and push the tag:
   ```bash
   git tag v0.2.0-rc.1
   git push origin v0.2.0-rc.1
   ```
4. Pushing that tag triggers `.github/workflows/prerelease.yml`, which runs
   the test suite, checks the tag matches `version.rb`, builds the gem, and
   pushes it to RubyGems as a pre-release.
5. Anyone who wants to try it runs `gem install smartorganize --pre`.

If the RC has problems, fix them on `dev`, bump to `-rc.2`, and repeat.
There's no limit on how many RCs a release goes through.

## Cutting a stable release

1. Once an RC has been tested and looks good, merge `staging` into `main`.
2. Bump `VERSION` in `lib/smartorganize/version.rb` to the plain version,
   e.g. `0.2.0` (drop the `-rc.N`). Commit it on `main`.
3. Tag it and push:
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```
4. Pushing that tag triggers `.github/workflows/release.yml`, which:
   - confirms the tagged commit is actually on `main`
   - runs the test suite
   - confirms the tag matches `version.rb` and isn't a pre-release version
   - builds the gem and pushes it to RubyGems (the real, non-`--pre` index)
   - creates a GitHub Release with auto-generated notes and the built
     `.gem` file attached

## The RubyGems API key

Both workflows need a RubyGems API key to run `gem push`, and neither
workflow can generate one. That has to come from a human with publish
rights on the `smartorganize` gem.

1. Log in at rubygems.org, go to your account's API keys page, and create
   a key scoped to "Push rubygem" (and ideally scoped to just this gem
   once it exists on RubyGems).
2. In the GitHub repo, go to **Settings → Secrets and variables → Actions**
   and add a secret named `RUBYGEMS_API_KEY` with that value.

Until that secret exists, both workflows will fail at the `gem push` step.
Everything before it (tests, version checks, build) still runs fine, so
you'll get a clear error rather than a silent no-op.

## Manual release (no CI)

If you ever need to publish without GitHub Actions:

```bash
bundle install
ruby -Ilib -Ispec spec/smartorganize_spec.rb   # tests should pass
gem build smartorganize.gemspec
gem push smartorganize-<version>.gem
```

`gem push` will prompt for RubyGems credentials interactively if you
haven't configured `~/.gem/credentials` already.
