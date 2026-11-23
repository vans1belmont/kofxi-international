# What the patch changes

Every change, by feature. Addresses are the executable's (SLPS_256.60, v1.03, loaded at 0x100000); words are
the 32-bit values as a disassembler shows them. `asm/` has the commented listings of the three new blocks.

## HOW TO PLAY restored

The arcade shows a HOW TO PLAY demonstration before character select. The port keeps the code, switched off, and lacks the pictures and movies. The patch adds them and turns it on.

| address | original | patched | purpose |
|---|---|---|---|
| `0x130E9C` | `10400007` | `00000000` | the settings gate: [0x92F364] & 0x40 (the operator's How-to-Play bit, which the default settings at 0x154A38 never set) chooses HOW TO PLAY init 0x329840 over character select 0x130EE0; falling through takes the HOW TO PLAY path before every arcade character select, as the arcade does |
| `0x329BC4` | `0C067CD8` | `AC850008` | the texture register 0x19F360 is a stub (`jr ra`) in the port, so the director's nine texture entries stayed empty; GAME OVER (0x329020) stores the loaded buffer at entry + 8 in place, and this does the same |
| `0x329C44` | `0C063D08` | `00000000` | director state 0x22 frees the nine load buffers (the arcade had copied them to texture memory); drawn from those buffers, the .Mdp load (state 0x30) reused sheet 1's block and Ash's first sheet vanished. Character select resets the heap first thing (0x130EEC -> 0x1A4B00), so nothing is kept past the movie |

File-table slots (the game finds every file through a static table in the executable; these slots
named network modules no lookup can ask for):

| slot | was | now | first sector | sectors |
|---|---|---|---|---|
| 873 | `\NF\MODULES\ATAD.IRX;1` | `\DATA\HOW_000.LZ;1` | 1230094 | 224 |
| 874 | `\NF\MODULES\AVEDHCP.IRX;1` | `\DATA\HOW_001.LZ;1` | 1230318 | 239 |
| 875 | `\NF\MODULES\AVEPPP.IRX;1` | `\DATA\HOW_002.LZ;1` | 1230557 | 238 |
| 876 | `\NF\MODULES\AVETCP.IRX;1` | `\DATA\HOW_ASH_000.LZ;1` | 1230795 | 23 |
| 877 | `\NF\MODULES\DEV9.IRX;1` | `\DATA\HOW_ASH_001.LZ;1` | 1230818 | 22 |
| 878 | `\NF\MODULES\DEVGLUE.IRX;1` | `\DATA\HOW_ASH_002.LZ;1` | 1230840 | 9 |
| 879 | `\NF\MODULES\DNAS300.IMG;1` | `\DATA\HOW_EL_000.LZ;1` | 1230849 | 26 |
| 880 | `\NF\MODULES\FFSOUND.IRX;1` | `\DATA\HOW_EL_001.LZ;1` | 1230875 | 21 |
| 881 | `\NF\MODULES\HDD.IRX;1` | `\DATA\HOW_EL_002.LZ;1` | 1230896 | 37 |
| 882 | `\NF\MODULES\IOPINT.IRX;1` | `\DATA\HOW_OZ_000.LZ;1` | 1230933 | 140 |
| 883 | `\NF\MODULES\LIBSD.IRX;1` | `\DATA\HOW_EFC_000_16.LZ;1` | 1231073 | 12 |
| 884 | `\NF\MODULES\MCMAN.IRX;1` | `\DATA\HowToPlay_J_Movie.Mdp;1` | 1231085 | 26 |
| 885 | `\NF\MODULES\MCSERV.IRX;1` | `\DATA\HowToPlay_E_Movie.Mdp;1` | 1231111 | 27 |
| 886 | `\NF\MODULES\NETCNF.IRX;1` | `\DATA\HowToPlay_S_Movie.Mdp;1` | 1231138 | 27 |

Files added to the disc:

| file | bytes | first sector | what |
|---|---|---|---|
| `\DATA\HOW_000.LZ;1` | 457,522 | 1230094 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_001.LZ;1` | 489,108 | 1230318 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_002.LZ;1` | 486,019 | 1230557 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_ASH_000.LZ;1` | 46,016 | 1230795 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_ASH_001.LZ;1` | 44,396 | 1230818 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_ASH_002.LZ;1` | 17,293 | 1230840 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_EL_000.LZ;1` | 52,333 | 1230849 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_EL_001.LZ;1` | 42,364 | 1230875 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_EL_002.LZ;1` | 74,128 | 1230896 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_OZ_000.LZ;1` | 284,794 | 1230933 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HOW_EFC_000_16.LZ;1` | 23,163 | 1231073 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HowToPlay_J_Movie.Mdp;1` | 53,066 | 1231085 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HowToPlay_E_Movie.Mdp;1` | 53,610 | 1231111 | HOW TO PLAY picture or movie data, in the PS2's own layouts |
| `\DATA\HowToPlay_S_Movie.Mdp;1` | 53,642 | 1231138 | HOW TO PLAY picture or movie data, in the PS2's own layouts |

15 small edits inside the added files themselves (the mirrored skill gauge moved 2 px in each movie), already in the files above.

## Different Space: the gap at the mirrored half

Two stages draw a mirrored half of a layer one pixel off, leaving a bare column. The five stores that move it are removed.

| address | original | patched | purpose |
|---|---|---|---|
| `0x151748` | `A44300A4` | `00000000` | stage 7, tag 0x41: `if x == 0x600: x := 0x5FF` moved the sky's mirrored half (record 33) 1 px left so the mirror line's column drew once, and left the half's far edge (x 1535) bare; the arcade shows no gap. The store is nopped: the half keeps the data's anchor 1536 |
| `0x151774` | `A44300A4` | `00000000` | stage 7, tag 0x42: `if x == 0x400: x := 0x3FF` on the sky's other mirrored half (record 34, anchor 1024). Nopped: the delay slot of `b 0x1517F8`, the branch is still taken |
| `0x1517A4` | `A44300A4` | `00000000` | stage 8, tag 3: `if x == 0x400: x := 0x3FF` moved the plate's mirrored half (record 13, 304 rows) 1 px left and left plate column 1023 bare, the lava behind showing through. Nopped: the half keeps the data's anchor 1024, flush with record 10 |
| `0x1517CC` | `A44300A4` | `00000000` | stage 8, tag 4: the same rule; no stage-8 record reaches it (tag 4's mirrored copy, record 14, sits at 1536). Nopped with the others so the routine carries no x rule |
| `0x1517F4` | `A44300A4` | `00000000` | stage 8, tag 6: `if x == 0x400: x := 0x3FF` on record 16 (40 rows, the same bare column). Nopped: anchor 1024, flush with record 14 |

## Ice Festival: the ground tile

One ground tile sits one row too high. Its offset is corrected in the stage layout and in the two copies of it the disc carries.

Bytes changed in files already on the disc:

| file | offset | bytes | was -> now |
|---|---|---|---|
| `\DATA\BG\ST_03_DT.PK;1` | `0x506` | 2 | `1900` -> `1a00` |
| `\DATA\BG\BG03.BIN;1` | `0x546` | 2 | `1900` -> `1a00` |
| `\DATA\BG\BG03.BCC;1` | `0x343` | 1 | `19` -> `1a` |

## The concert stage's banner (by Keku)

The globes' banner is misspelled on the disc. Keku (@kekutougame) redrew it in the stage's own letterforms; 25 rows of one texture page, palette untouched.

Bytes changed in files already on the disc:

| file | offset | bytes |
|---|---|---|
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb0910` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb0a10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb0b10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb0c10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb0d10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb0e10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb0f10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1010` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1110` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1210` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1310` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1410` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1510` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1610` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1710` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1810` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1910` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1a10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1b10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1c10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1d10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1e10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb1f10` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb2010` | 256 |
| `\DATA\BG_BIN\KOF_07.BIN;1` | `0xb2110` | 256 |

## Spanish win quotes

The message-file picker asks for a Spanish win-quote file at language 2; the disc has none, nor the Latin font with Spanish letters. Both are added, and the font buffer's lifetime is fixed.

| address | original | patched | purpose |
|---|---|---|---|
| `0x19BCB4` | `0C06936C` | `00000000` | the Latin path's state 0x33 frees the loaded font buffer right after registering the texture (the Japanese path's state 0x23 does not); the texture entry [0x9BD530] still points into it, the cut table and the cutscene's own data are later allocated over it, and during the MIDDLE cutscene the font's CLUT went up as zeros (the page itself intact): the subtitles drew invisible. Kept, as the Japanese path keeps its buffer |
| `0x19BCCC` | `AC40D520` | `00000000` | keeps the buffer's handle in [0x9BD520], as the Japanese path does (0x19BBB8), so the release routine (0x19AD24: free [0x9BD520]) frees it when the message task ends: no leak |

File-table slots (the game finds every file through a static table in the executable; these slots
named network modules no lookup can ask for):

| slot | was | now | first sector | sectors |
|---|---|---|---|---|
| 887 | `\NF\MODULES\NETCNFIF.IRX;1` | `\DATA\MESWINS.MES;1` | 1231165 | 42 |
| 888 | `\NF\MODULES\PADMAN.IRX;1` | `\DATA\font24s.lz;1` | 1231207 | 22 |
| 889 | `\NF\MODULES\PFS.IRX;1` | `\DATA\;1` | 1231229 | 1 |

Files added to the disc:

| file | bytes | first sector | what |
|---|---|---|---|
| `\DATA\MESWINS.MES;1` | 84,928 | 1231165 | the Spanish win quotes the executable asks for at language 2 (611 entries) |
| `\DATA\FONT24S.LZ;1` | 45,012 | 1231207 | the Latin font page (the US disc's) with eight new cells: \xbf \xa1 \xc1 \xc9 \xcd \xd3 \xda \u2661 |
| `\DATA\FONTC24S.BIN;1` | 696 | 1231229 | the Latin font's cut table (the US disc's) with the eight new cells' entries appended (codes 0x6C..0x73) |

## English win quotes

At language 1 the game asks for an English win-quote file the Japanese disc lacks. It is added, and a hook draws a three-line quote 13 rows higher so it stays inside the text band.

| address | original | patched | purpose |
|---|---|---|---|
| `0x328C08` | `A6020026` | `0C04504E` | the win quote's script command (0x328B70) stores the picked entry's index here; the hook does it and lifts a three-line quote (the delay slot, lhu a0, 0xda(s4), is the next original word; the handler reloads ra from its frame) |

File-table slots (the game finds every file through a static table in the executable; these slots
named network modules no lookup can ask for):

| slot | was | now | first sector | sectors |
|---|---|---|---|---|
| 890 | `\NF\MODULES\SIO2MAN.IRX;1` | `\DATA\MESWINE.MES;1` | 1231364 | 41 |

| address | bytes | what |
|---|---|---|
| `0x114138` | 116 bytes | the three-line hook: the entry index stored as the original does, the entry's 0x2000 words counted in the message buffer [0x9bd510], and for 3 or more 13 rows off the text object's y -- over dead stdio functions, between the language-setting block and the HIT BOX block |

Files added to the disc:

| file | bytes | first sector | what |
|---|---|---|---|
| `\DATA\MESWINE.MES;1` | 83,292 | 1231364 | the English win quotes the executable asks for at language 1 (611 entries: the arcade's 507 with the 156 SNK never wrote and the corrections, and the US executable's 104) |

## The language setting (GAME OPTION > EXTRA SETTING)

A ninth row in GAME OPTION opens a new screen with one setting, LANGUAGE, saved with the options. The setting is the game's own language byte: 0 Japanese, 1 English, 2 Spanish.

| address | original | patched | purpose |
|---|---|---|---|
| `0x3317FC` | `28610007` | `28610008` | build 8 rows before EXIT (EXTRA is row 7, at y 0xA0 + 7*32) |
| `0x331848` | `24040007` | `24040008` | EXIT is created as row 8 |
| `0x3318E8` | `24050008` | `24050009` | the cursor's 9 positions |
| `0x331930` | `24040007` | `24040008` | a choice on row 8 is EXIT |
| `0x331B04` | `24020007` | `24020008` | the row callback's short EXIT bar on row 8 |
| `0x2FD6F8` | `24060006` | `24060007` | the save's last block 6 -> 7 bytes: 0x9BEC46 into the file's unwritten tail (+0x294FE) |
| `0x2FD9C0` | `24060006` | `24060007` | the load's last block 6 -> 7 bytes: 0x9BEC46 back from the file |
| `0x3319EC` | `3C03003D` | `3C030011` | GAME OPTION's launch table moved to the new block (9 entries: EXTRA at 7, EXIT at 8) |
| `0x3319F4` | `24631850` | `24633F40` | GAME OPTION's launch table moved to the new block |
| `0x331A0C` | `3C06003D` | `3C060011` | GAME OPTION's params table moved to the new block (9 entries: EXTRA at 7, EXIT at 8) |
| `0x331A18` | `24C61E78` | `24C63F64` | GAME OPTION's params table moved to the new block |
| `0x331BA8` | `3C02003D` | `3C020011` | GAME OPTION's labels table moved to the new block (9 entries: EXTRA at 7, EXIT at 8) |
| `0x331BAC` | `24421A60` | `24423ED4` | GAME OPTION's labels table moved to the new block |
| `0x331C54` | `3C02003D` | `3C020011` | GAME OPTION's labels table moved to the new block (9 entries: EXTRA at 7, EXIT at 8) |
| `0x331C58` | `24421A60` | `24423ED4` | GAME OPTION's labels table moved to the new block |
| `0x2FD9BC` | `0C049C48` | `0C045001` | the load's last copy goes through a stub that copies, then sets [0x92F35F] from 0x9BEC46 |
| `0x2FD144` | `0C049C48` | `0C045017` | GAME OPTION's settings snapshot also takes the language (0x9BEC46 -> the new block's snap byte) |
| `0x2FD240` | `0C0C056C` | `0C045022` | GAME OPTION's auto-save compare also tests the language against the snapshot: a language change alone saves |

File-table slots (the game finds every file through a static table in the executable; these slots
named network modules no lookup can ask for):

| slot | was | now | first sector | sectors |
|---|---|---|---|---|
| 353 | `\DATA\MENU\SPR00.GRC;1` | `\DATA\MENU\SPR00.GRC;1` | 1231230 | 134 |

| address | bytes | what |
|---|---|---|
| `0x113408` | 3372 bytes | the EXTRA SETTING screen (SOUND SETTING copied and cut to one row of three values, SOUND's screen id with GAME OPTION's pages), its stubs (the language byte = the setting, 0 Japanese; card load, auto-save snapshot and compare), GAME OPTION's moved tables and the descriptors, over 16 unreferenced functions of Sony's stdio library |

Files added to the disc:

| file | bytes | first sector | what |
|---|---|---|---|
| `\DATA\MENU\SPR00ES.GRC;1` | 274,221 | 1231230 | SPR00.GRC with the labels page's rows 384..511 = EXTRA SETTING / its header / LANGUAGE and ENGLISH / the other two values (SNK's letters, re-encoded), and two palette entries |

## HIT BOX in PRACTICE

A fourth SELECT BUTTON function in PRACTICE draws every live collision box of every object.

| address | original | patched | purpose |
|---|---|---|---|
| `0x1A1A6C` | `0C069F58` | `0C045070` | the main loop's last call goes through the box drawer, then on to 0x1A7D60 |
| `0x33B41C` | `10000028` | `08045142` | the SELECT handler's 'other code' exit goes through the stub: code 3 (HIT BOX) toggles the boxes |

| address | bytes | what |
|---|---|---|
| `0x1141c0` | 1520 bytes | the box drawer (training, HIT BOX selected and toggled on, not paused: every live slot 0..6 of every listed object -- hit / hurt by the game's class table with the 0x70..0x7F remap, throw, body -- outlined 2 px, sent box by box), the SELECT stub, the remap, the chain, colours, id -> kind table and the on/off byte, over the tail of the dead stdio functions |
| `0x3d2e0c` | `434f4d4d414e4400` -> `48495420424f5800` | SELECT BUTTON code 3's name: COMMAND (a cut option) -> HIT BOX |
| `0x3d2f20` | `0302020202020202020202` -> `0403030303030303030303` | SELECT BUTTON's list lengths for ACTION 0..10 + 1: code 3 offered after SKILL LIST (ACTION 11 unchanged) |

## Cutscene subtitles: the Spanish corrected

Each cutscene file carries its subtitles in three language blocks. The Spanish block is re-encoded with the corrected lines, in place, the file's size unchanged.

Bytes changed in files already on the disc:

| file | offset | bytes |
|---|---|---|
| `\DATA\DEMO\ABOSS\ABOSS00.BIN;1` | `0x12a18` | 2448 |
| `\DATA\DEMO\ABOSS\ABOSS01.BIN;1` | `0x12a20` | 2458 |
| `\DATA\DEMO\ABOSS\ABOSS02.BIN;1` | `0x12a6c` | 2510 |
| `\DATA\DEMO\ABOSS\ABOSS03.BIN;1` | `0x129a4` | 2394 |
| `\DATA\DEMO\ABOSS\ABOSS04.BIN;1` | `0x129d8` | 2386 |
| `\DATA\DEMO\ABOSS\ABOSS05.BIN;1` | `0x129f2` | 2428 |
| `\DATA\DEMO\ABOSS\ABOSS06.BIN;1` | `0x129de` | 2444 |
| `\DATA\DEMO\ABOSS\ABOSS07.BIN;1` | `0x12a2c` | 2458 |
| `\DATA\DEMO\ABOSS\ABOSS08.BIN;1` | `0x129a2` | 2378 |
| `\DATA\DEMO\ABOSS\ABOSS09.BIN;1` | `0x1298a` | 2356 |
| `\DATA\DEMO\ABOSS\ABOSS10.BIN;1` | `0x129a4` | 2372 |
| `\DATA\DEMO\ABOSS\ABOSS11.BIN;1` | `0x128ce` | 2270 |
| `\DATA\DEMO\ABOSS\ABOSS12.BIN;1` | `0x12948` | 2300 |
| `\DATA\DEMO\ABOSS\ABOSS13.BIN;1` | `0x128e8` | 2290 |
| `\DATA\DEMO\ABOSS\ABOSS16.BIN;1` | `0x12a3c` | 2508 |
| `\DATA\DEMO\BBOSS\BBOSS02.BIN;1` | `0xb210` | 1144 |
| `\DATA\DEMO\BBOSS\BBOSS12.BIN;1` | `0xb1be` | 1118 |
| `\DATA\DEMO\BBOSS\BBOSS13.BIN;1` | `0xb1be` | 1118 |
| `\DATA\DEMO\END\END00.BIN;1` | `0x2244` | 2974 |
| `\DATA\DEMO\END\END01.BIN;1` | `0x271a` | 3438 |
| `\DATA\DEMO\END\END02.BIN;1` | `0x218c` | 4006 |
| `\DATA\DEMO\END\END03.BIN;1` | `0x2b14` | 4022 |
| `\DATA\DEMO\END\END04.BIN;1` | `0x190c` | 2262 |
| `\DATA\DEMO\END\END05.BIN;1` | `0x22ee` | 2338 |
| `\DATA\DEMO\END\END06.BIN;1` | `0x2a9e` | 3916 |
| `\DATA\DEMO\END\END07.BIN;1` | `0x1e74` | 3092 |
| `\DATA\DEMO\END\END10.BIN;1` | `0x1660` | 1466 |
| `\DATA\DEMO\MBOSS\MBOSS01.BIN;1` | `0x5570` | 476 |
| `\DATA\DEMO\MBOSS\MBOSS02.BIN;1` | `0x5518` | 628 |
| `\DATA\DEMO\MBOSS\MBOSS05.BIN;1` | `0x54c2` | 582 |
| `\DATA\DEMO\MBOSS\MBOSS06.BIN;1` | `0x5508` | 634 |
| `\DATA\DEMO\MBOSS\MBOSS10.BIN;1` | `0x5580` | 570 |
| `\DATA\DEMO\MBOSS\MBOSS12.BIN;1` | `0x54c0` | 604 |
| `\DATA\DEMO\MBOSS\MBOSS16.BIN;1` | `0x557e` | 546 |
| `\DATA\DEMO\MIDDLE.BIN;1` | `0x350a` | 900 |
| `\DATA\DEMO\BBOSS\BBOSS00.BIN;1` | `0xb1fe` | 1156 |
| `\DATA\DEMO\BBOSS\BBOSS01.BIN;1` | `0xb204` | 1144 |
| `\DATA\DEMO\BBOSS\BBOSS03.BIN;1` | `0xb1e0` | 1118 |
| `\DATA\DEMO\BBOSS\BBOSS04.BIN;1` | `0xb204` | 1170 |
| `\DATA\DEMO\BBOSS\BBOSS05.BIN;1` | `0xb21e` | 1148 |
| `\DATA\DEMO\BBOSS\BBOSS06.BIN;1` | `0xb1a8` | 1086 |
| `\DATA\DEMO\BBOSS\BBOSS07.BIN;1` | `0xb1e8` | 1166 |
| `\DATA\DEMO\BBOSS\BBOSS08.BIN;1` | `0xb1ec` | 1154 |
| `\DATA\DEMO\BBOSS\BBOSS10.BIN;1` | `0xb202` | 1142 |
| `\DATA\DEMO\BBOSS\BBOSS11.BIN;1` | `0xb1b6` | 1120 |
| `\DATA\DEMO\BBOSS\BBOSS16.BIN;1` | `0xb208` | 1150 |
| `\DATA\DEMO\MBOSS\MBOSS00.BIN;1` | `0x5524` | 644 |
| `\DATA\DEMO\MBOSS\MBOSS03.BIN;1` | `0x5536` | 632 |
| `\DATA\DEMO\MBOSS\MBOSS04.BIN;1` | `0x54e8` | 632 |
| `\DATA\DEMO\MBOSS\MBOSS07.BIN;1` | `0x556e` | 670 |
| `\DATA\DEMO\MBOSS\MBOSS08.BIN;1` | `0x54e0` | 558 |
| `\DATA\DEMO\MBOSS\MBOSS09.BIN;1` | `0x5518` | 656 |
| `\DATA\DEMO\MBOSS\MBOSS11.BIN;1` | `0x54b6` | 554 |
| `\DATA\DEMO\MBOSS\MBOSS13.BIN;1` | `0x54aa` | 580 |

## Cutscene subtitles: the English of the North American release

The English block is re-encoded with the North American release's script. In four files it is longer, so the two blocks behind it move into the padding and their offsets are rewritten; there the record also carries the Spanish corrections.

Bytes changed in files already on the disc:

| file | offset | bytes |
|---|---|---|
| `\DATA\DEMO\ABOSS\ABOSS00.BIN;1` | `0x11bd2` | 2372 |
| `\DATA\DEMO\ABOSS\ABOSS01.BIN;1` | `0x11bd6` | 2410 |
| `\DATA\DEMO\ABOSS\ABOSS02.BIN;1` | `0x11bce` | 2484 |
| `\DATA\DEMO\ABOSS\ABOSS03.BIN;1` | `0x11bd6` | 2292 |
| `\DATA\DEMO\ABOSS\ABOSS04.BIN;1` | `0x11bd6` | 2336 |
| `\DATA\DEMO\ABOSS\ABOSS05.BIN;1` | `0x11bd6` | 2324 |
| `\DATA\DEMO\ABOSS\ABOSS06.BIN;1` | `0x11bd6` | 2354 |
| `\DATA\DEMO\ABOSS\ABOSS07.BIN;1` | `0x11bd6` | 2398 |
| `\DATA\DEMO\ABOSS\ABOSS08.BIN;1` | `0x11bd6` | 2308 |
| `\DATA\DEMO\ABOSS\ABOSS09.BIN;1` | `0x11bd6` | 2258 |
| `\DATA\DEMO\ABOSS\ABOSS10.BIN;1` | `0x11bd6` | 2294 |
| `\DATA\DEMO\ABOSS\ABOSS11.BIN;1` | `0x11bd6` | 2156 |
| `\DATA\DEMO\ABOSS\ABOSS12.BIN;1` | `0x11bd6` | 2258 |
| `\DATA\DEMO\ABOSS\ABOSS13.BIN;1` | `0x11bda` | 2172 |
| `\DATA\DEMO\ABOSS\ABOSS16.BIN;1` | `0x11bd6` | 2408 |
| `\DATA\DEMO\BBOSS\BBOSS00.BIN;1` | `0xaaac` | 1156 |
| `\DATA\DEMO\BBOSS\BBOSS01.BIN;1` | `0xaaac` | 1156 |
| `\DATA\DEMO\BBOSS\BBOSS02.BIN;1` | `0xaaac` | 1162 |
| `\DATA\DEMO\BBOSS\BBOSS03.BIN;1` | `0xaaac` | 1138 |
| `\DATA\DEMO\BBOSS\BBOSS04.BIN;1` | `0xaaac` | 1148 |
| `\DATA\DEMO\BBOSS\BBOSS05.BIN;1` | `0xaaac` | 1139 |
| `\DATA\DEMO\BBOSS\BBOSS06.BIN;1` | `0xaaac` | 1092 |
| `\DATA\DEMO\BBOSS\BBOSS07.BIN;1` | `0xaaac` | 1134 |
| `\DATA\DEMO\BBOSS\BBOSS08.BIN;1` | `0xaaac` | 1144 |
| `\DATA\DEMO\BBOSS\BBOSS09.BIN;1` | `0xaaa0` | 2854 |
| `\DATA\DEMO\BBOSS\BBOSS10.BIN;1` | `0xaaac` | 1166 |
| `\DATA\DEMO\BBOSS\BBOSS11.BIN;1` | `0xaaac` | 1118 |
| `\DATA\DEMO\BBOSS\BBOSS12.BIN;1` | `0xaaac` | 1128 |
| `\DATA\DEMO\BBOSS\BBOSS13.BIN;1` | `0xaaac` | 1128 |
| `\DATA\DEMO\BBOSS\BBOSS16.BIN;1` | `0xaaac` | 1164 |
| `\DATA\DEMO\END\END00.BIN;1` | `0xede` | 3104 |
| `\DATA\DEMO\END\END01.BIN;1` | `0x1102` | 3518 |
| `\DATA\DEMO\END\END02.BIN;1` | `0xa36` | 3938 |
| `\DATA\DEMO\END\END03.BIN;1` | `0x124a` | 4038 |
| `\DATA\DEMO\END\END04.BIN;1` | `0xb96` | 2236 |
| `\DATA\DEMO\END\END05.BIN;1` | `0x1506` | 2258 |
| `\DATA\DEMO\END\END06.BIN;1` | `0x10d2` | 4136 |
| `\DATA\DEMO\END\END07.BIN;1` | `0x982` | 3380 |
| `\DATA\DEMO\END\END08.BIN;1` | `0x1420` | 6360 |
| `\DATA\DEMO\END\END09.BIN;1` | `0x17ec` | 6490 |
| `\DATA\DEMO\END\END10.BIN;1` | `0xc96` | 1528 |
| `\DATA\DEMO\END\END16.BIN;1` | `0xc74` | 5066 |
| `\DATA\DEMO\MBOSS\MBOSS00.BIN;1` | `0x513e` | 648 |
| `\DATA\DEMO\MBOSS\MBOSS01.BIN;1` | `0x513e` | 638 |
| `\DATA\DEMO\MBOSS\MBOSS02.BIN;1` | `0x513e` | 658 |
| `\DATA\DEMO\MBOSS\MBOSS03.BIN;1` | `0x513e` | 674 |
| `\DATA\DEMO\MBOSS\MBOSS04.BIN;1` | `0x513e` | 598 |
| `\DATA\DEMO\MBOSS\MBOSS05.BIN;1` | `0x513e` | 582 |
| `\DATA\DEMO\MBOSS\MBOSS06.BIN;1` | `0x513e` | 646 |
| `\DATA\DEMO\MBOSS\MBOSS07.BIN;1` | `0x513e` | 706 |
| `\DATA\DEMO\MBOSS\MBOSS08.BIN;1` | `0x513e` | 606 |
| `\DATA\DEMO\MBOSS\MBOSS09.BIN;1` | `0x513e` | 652 |
| `\DATA\DEMO\MBOSS\MBOSS10.BIN;1` | `0x513e` | 664 |
| `\DATA\DEMO\MBOSS\MBOSS11.BIN;1` | `0x513c` | 598 |
| `\DATA\DEMO\MBOSS\MBOSS12.BIN;1` | `0x513e` | 620 |
| `\DATA\DEMO\MBOSS\MBOSS13.BIN;1` | `0x513c` | 600 |
| `\DATA\DEMO\MBOSS\MBOSS16.BIN;1` | `0x513e` | 664 |
| `\DATA\DEMO\MIDDLE.BIN;1` | `0x2fac` | 898 |

