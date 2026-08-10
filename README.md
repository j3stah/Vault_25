Just a personal website for me to play around and write stuff on. Have fun!

## Journal workflow

- Save a plain text file in `journal_entries/`
- Use a filename like `2026-08-10--my-entry-title.txt`
- Run `scripts/build-journal.ps1` to regenerate `data/journal_entries.json`
- Or run `scripts/watch-journal.ps1` to keep the JSON updated automatically while you edit

The site reads from the generated JSON, so GitHub Pages can still serve it as a normal static site.
