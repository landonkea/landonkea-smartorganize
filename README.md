# smartorganize

A Ruby CLI tool that automatically organizes files in any folder by type, date, or custom rules.

## What it does

Ever have a Downloads folder full of random files? `smartorganize` fixes that.
It scans a folder, figures out what each file is, and moves it into the right subfolder.

```bash
# See what would be moved (dry run)
smartorganize scan ~/Downloads

# Actually organize the files
smartorganize organize ~/Downloads

# Undo the last organization
smartorganize undo ~/Downloads

# Show statistics
smartorganize stats ~/Downloads
```

## Installation

```bash
gem install smartorganize
```

## How it works

1. Scans every file in the target folder
2. Looks at each file's extension to determine its type
3. Moves files into categorized subfolders (Documents, Images, Videos, etc.)
4. Keeps a log so you can undo if needed

## Configuration

Create a `.smartorganize.yml` in your home folder:

```yaml
categories:
  Documents:
    - pdf, doc, docx, txt, md
  Images:
    - jpg, jpeg, png, gif, svg, webp
  Videos:
    - mp4, mov, avi, mkv, webm
  Audio:
    - mp3, wav, flac, aac, ogg
  Archives:
    - zip, tar, gz, rar, 7z
  Code:
    - rb, py, js, ts, go, java, cs
```

## License

MIT
