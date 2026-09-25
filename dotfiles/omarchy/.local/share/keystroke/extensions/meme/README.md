# Meme Maker

Captions [meme-maker](https://github.com/kartikkabadi/meme-maker) templates from
the palette. `meme drake` (or the Omarchy menu's Meme Maker row, which opens the
Memes screen) lists every template, fuzzy-matched on its name and id and by word
on its tags and category, with its thumbnail in the preview pane. `↵` runs
`bin/meme-menu <template>`, which asks for each text slot, saves the meme in the
**Save folder** setting (`~/Pictures/memes` by default) and copies it to the
clipboard. Without Keystroke, `bin/meme-menu` picks the template from a plain
Omarchy menu list instead.

Needs the `meme` CLI and its templates in `$MEME_MAKER_HOME` (default
`~/.meme-maker`), from meme-maker's own installer.
