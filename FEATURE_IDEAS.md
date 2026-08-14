# Feature ideas

Things smartorganize could grow into, roughly ordered from "small, obvious
next step" to "bigger change." Every idea here builds on what the tool
already does (scan/organize/undo/stats on a folder, extension-based
categories, a YAML config, a JSON move log for undo) rather than bolting
on something unrelated.

1. **Date-based organization.** The README already advertises "by type,
   date, or custom rules," but the code only does type. Add a config mode
   (or a `--by date` flag) that files things into `2026/08/` style folders
   using `File.mtime`, either instead of or nested under the type
   category.

2. **Custom filename rules.** The other half of that README promise.
   Let `.smartorganize.yml` match on filename patterns, not just
   extensions, e.g. routing anything starting with `invoice_` to an
   `Invoices` folder regardless of whether it's a PDF or a PNG.

3. **Real duplicate detection.** Right now, if a same-named file already
   exists at the destination, `organize` just skips it (`Errno::EEXIST`
   in `organizer.rb`). That conflates "this is the same file" with "this
   is an unrelated file that happens to share a name." Hash both files
   (`Digest::SHA256`) and only skip on an actual content match; otherwise
   rename the incoming file (`photo (1).jpg`) instead of silently
   dropping it.

4. **Configurable conflict handling.** Once duplicate detection exists,
   let the user choose the behavior: `--on-conflict=skip|rename|overwrite`.
   Skip should stay the default so nothing destructive happens without
   asking.

5. **An ignore list.** A `.smartorganizeignore` file (or an `ignore:` key
   in the YAML config) for patterns that should never move: `*.crdownload`,
   `*.part`, `.DS_Store` variants, or a whole subfolder like `Screenshots`
   someone wants left alone.

6. **Minimum file age before organizing.** A `--min-age 1h` style flag so
   `organize` skips anything still being written to or actively in use,
   useful if this ever runs unattended against an active Downloads folder.

7. **Deeper undo history.** `undo` currently reads one `.smartorganize.log`
   file and deletes it once used, so you get exactly one level of undo.
   Move history into a `.smartorganize/history/<timestamp>.json` directory
   and let `undo` take an optional `--steps N` or list past operations to
   pick from.

8. **A watch mode.** `smartorganize watch ~/Downloads` that polls (or uses
   a filesystem-events gem) and organizes new files as they land, instead
   of requiring someone to remember to run the command.

9. **JSON output for scripting.** `--json` on `scan` and `stats` so the
   output can be piped into another tool instead of parsed out of colored
   terminal text.

10. **Per-directory config, not just per-user.** Config currently only
    loads from `~/.smartorganize.yml`. Also check for a `.smartorganize.yml`
    inside the target directory itself and let it override the home one,
    so Downloads and a project folder can have different rules.

11. **Config validation command.** `smartorganize config check` that lints
    the YAML: flags an extension listed under two categories at once
    (currently `Config#extension_for` just returns whichever comes first
    in Ruby's hash-iteration order, silently), and flags unknown YAML keys
    as typos rather than ignoring them.

12. **Explicit category priority.** Related to #11: when an extension
    genuinely belongs in two categories on purpose (say `.json` in both
    `Data` and `Code`), let the config specify which one wins instead of
    relying on hash order.

13. **A size-based catch-all.** Files above a configurable size (say 1 GB)
    go into a `Large` category regardless of extension, useful for ISOs
    and video exports that would otherwise clutter `Videos` or `Archives`.

14. **Empty folder cleanup.** After `undo`, any category folder left empty
    by the restore should be removed rather than left behind as clutter.

15. **A dry-run diff for undo.** `undo --dry-run` that shows what would
    move back without doing it, matching how `organize --dry-run` already
    works, instead of undo being the one command with no preview.

16. **Symlink handling.** `File.file?` in `scan_directory`/`scan_recursive`
    currently follows symlinks without saying so. Decide the intended
    behavior explicitly (skip symlinks by default, `--follow-symlinks` to
    include them) and handle broken symlinks without crashing.

17. **A scheduling helper.** `smartorganize schedule ~/Downloads --daily`
    that installs a cron entry or macOS launchd plist to run `organize`
    automatically, so recurring cleanup doesn't depend on remembering to
    run the command by hand.

18. **Nested sub-categories by pattern.** Split `Images` into
    `Images/Screenshots` vs `Images/Photos` using filename heuristics
    (`Screenshot 2026-...` vs `IMG_1234.jpg`), configurable the same way
    top-level categories are today.
