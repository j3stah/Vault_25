Just a personal website for me to play around and write stuff on. Have fun!

## Writings workflow

- Save a plain text file in `writings/` (e.g., `my-cool-writing.txt`)
- Run `scripts/build-writings.ps1` to convert all `.txt` files to formatted `.html` files
- Or run `scripts/watch-writings.ps1` to automatically convert files as you save them

The script converts each text file to a properly formatted HTML page and places it in the `writings/` folder. It also stages, commits, and pushes the new content to GitHub so the site can update automatically.
