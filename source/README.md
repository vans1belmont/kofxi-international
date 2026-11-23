# The King of Fighters XI International -- source

This is the source of the patch in the sense that matters for a patch: **what it changes and why**. The patch
itself is a binary difference a player applies to their own disc image; nothing here contains any part of the
game.

| | |
|---|---|
| `CHANGES.md` | every change, by feature: the executable's patched words with their purpose, the file-table slots, the files added, the bytes changed in the disc's own files |
| `asm/` | commented assembly of the three blocks of new code: the language setting, HIT BOX, the three-line win quote hook |
| `text/win_quotes_en.txt`, `text/win_quotes_es.txt` | the win quotes this patch wrote or changed, by entry number |
| `text/cutscenes_es.txt` | the corrected Spanish subtitle lines, each with the line it replaces |
| `text/cutscenes_en.txt` | how the North American script was fitted to the disc's subtitle records |

Not included: SNK's own text and art, including the lines of SNK's that the patch keeps or brings over from
the North American release; they are named by entry number, not copied. The tools the patch was built with
are not part of this source.

The game is SNK's. This is an unofficial fan patch, not for commercial use.
