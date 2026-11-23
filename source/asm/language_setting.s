; language_setting.s -- The King of Fighters XI (PS2, SLPS-25660 v1.03): EXTRA SETTING / LANGUAGE
;
; What it does
;   Adds an EXTRA SETTING row to GAME OPTION (row 7, just above EXIT, which becomes row 8). It
;   opens a one-row screen, LANGUAGE, whose value cycles through three choices:
;     0 = Japanese (the default), 1 = ENGLISH, 2 = ESPANOL
;   The value is the game's own language byte at 0x92F35F, in the message-file picker's own order
;   (its jump table at 0x3DEF60): choosing a value just copies it there. The choice is kept in
;   0x9BEC46 (a byte no original instruction touches), saved on the memory card in the save file's
;   unused tail and restored after a load; an old save or a new game starts in Japanese. Changing
;   only the language is enough for GAME OPTION's auto-save to save on exit.
;
;   The screen is the game's SOUND SETTING screen (main 0x333930, drawer 0x333D60, highlight
;   0x334170), copied into dead code, relocated and cut down to one row. Those three copies are
;   the game's own code and are given below only as words, with every changed word listed. The
;   small routines (lang_sync ... draw_language) and the tables are new.
;   The pictures it draws (EXTRA SETTING, its header, LANGUAGE and the three values) are new rows
;   384..511 of the labels page, entry 2 of SPR00.GRC in the disc's MENU folder, plus two palette
;   entries; that file is replaced separately and is not part of this listing.
;
; Where it is called from (patched words outside this block)
;     address   original  new       purpose
;     002FD144  0C049C48  0C045017  auto-save snapshot: its last copy goes through snap_copy (the language too)
;     002FD240  0C0C056C  0C045022  auto-save compare: its last compare goes through snap_compare
;     002FD6F8  24060006  24060007  save: last block 6 -> 7 bytes, so 0x9BEC46 goes into the file's unused tail
;     002FD9BC  0C049C48  0C045001  load: its last copy goes through load_sync (sets the language)
;     002FD9C0  24060006  24060007  load: last block 6 -> 7 bytes, so 0x9BEC46 comes back from the file
;     003317FC  28610007  28610008  GAME OPTION builds 8 rows before EXIT (EXTRA SETTING is row 7)
;     00331848  24040007  24040008  EXIT is created as row 8
;     003318E8  24050008  24050009  the cursor has 9 positions
;     00331930  24040007  24040008  a choice on row 8 is EXIT
;     003319EC  3C03003D  3C030011  launch table 0x3D1850 -> launch (high half)
;     003319F4  24631850  24633F40  launch table -> launch (low half)
;     00331A0C  3C06003D  3C060011  screen-id table 0x3D1E78 -> params (high half)
;     00331A18  24C61E78  24C63F64  screen-id table -> params (low half)
;     00331B04  24020007  24020008  the row callback's short EXIT bar is on row 8
;     00331BA8  3C02003D  3C020011  label table 0x3D1A60 -> labels (high half)
;     00331BAC  24421A60  24423ED4  label table -> labels (low half)
;     00331C54  3C02003D  3C020011  label table 0x3D1A60 -> labels (high half), second use
;     00331C58  24421A60  24423ED4  label table -> labels (low half), second use
;
;   GAME OPTION (0x331760) built its rows at y = 0xA0 + 32k for k < 7, then EXIT (k = 7); a choice
;   on row k switches to launch[k] and passes params[k] in [0x1DDE820] (the screen id); the row
;   callback draws labels[k]. Those three tables are packed in the original, so they are moved
;   here with a ninth entry. The save writes and reads its last block of settings with a byte
;   count of 6 (0x2FD6F8 / 0x2FD9C0); 7 carries 0x9BEC46 along.
;
; Where it lives
;   0x113408..0x114134 (843 words), over unreferenced library functions (dead code) of the
;   original executable.
;
; Game addresses used
;   0x92F35F  the language byte the game reads (0 Japanese, 1 English, 2 Spanish)
;   0x9BEC46  the saved LANGUAGE setting (same values)
;   0x1DDE820 the current GAME OPTION sub-screen id. It picks the texture set read at the
;             screen's init and drives GAME OPTION's background task every frame (ids 2..5 and
;             8..0xD dim the background; 0, 1 and 0xE draw the wheel). EXTRA SETTING uses SOUND's
;             id 4, except during its init, when it is 1 (GAME OPTION) so GAME OPTION's texture
;             set is loaded: slot 1 = the labels page (SPR00 entry 2), slot 2 = the words page,
;             slot 3 = page 4.
;
; Picture descriptors (12 bytes, as the game uses them): u16 u, u16 v, u16 width, u16 height (a
; rectangle of a texture page), u8 texture slot of the current screen, 3 bytes 0. The drawer's
; picture call is 0x302AE0(a0 = descriptor, a1 = x, a2 = y).
;
; Listing format: address:  word (little-endian u32 as stored)  instruction  ; comment

; --------------------------------------------------------------------------------------------------
; main_copy: the screen's main routine (SOUND SETTING's, cloned)
;
; Builds the screen through its step table (build_steps), runs the cursor over LANGUAGE and EXIT,
; cycles the language on row 0, resets it on SELECT and returns to GAME OPTION's row 7 on EXIT.
; GAME OPTION reaches it through launch[7].
; Cloned from game code 0x333930..0x333D60 (268 words), placed at 0x113408..0x113838.
; Every word is the original's except these (address here, address in the original, original word,
; new word, why):
;   00113450  00333978  0C0CBF34 -> 0C04500A  the screen's init call 0x32FCD0 -> tex_init (GAME OPTION's textures under id 1, then id 4)
;   001134B4  003339DC  3C040040 -> 3C040011  address of the build's step table: 0x404850 -> 0x113F70 (high half)
;   001134BC  003339E4  24844850 -> 24843F70  address of the build's step table: 0x404850 -> 0x113F70 (low half)
;   001134D0  003339F8  3C040033 -> 3C040011  address of the drawer: 0x333D60 -> 0x113838
;   001134D8  00333A00  24843D60 -> 24843838  address of the drawer: 0x333D60 -> 0x113838
;   00113510  00333A38  3C040033 -> 3C040011  address of the drawer: 0x333D60 -> 0x113838
;   00113518  00333A40  24843D60 -> 24843838  address of the drawer: 0x333D60 -> 0x113838
;   00113548  00333A70  3C040033 -> 3C040011  address of the drawer: 0x333D60 -> 0x113838
;   00113550  00333A78  24843D60 -> 24843838  address of the drawer: 0x333D60 -> 0x113838
;   00113580  00333AA8  3C040033 -> 3C040011  address of the drawer: 0x333D60 -> 0x113838
;   00113588  00333AB0  24843D60 -> 24843838  address of the drawer: 0x333D60 -> 0x113838
;   001135D4  00333AFC  3C040033 -> 3C040011  address of the highlight drawer: 0x334170 -> 0x113C48
;   001135E4  00333B0C  24844170 -> 24843C48  address of the highlight drawer: 0x334170 -> 0x113C48
;   00113630  00333B58  24050006 -> 24050002  cursor positions 6 -> 2 (LANGUAGE, EXIT)
;   00113658  00333B80  10830025 -> 00000000  a branch of the row dispatch (rows 1..4) -> nop
;   00113664  00333B8C  1083001E -> 00000000  a branch of the row dispatch (rows 1..4) -> nop
;   0011366C  00333B94  24050002 -> 24050003  the cycle's value count (a1 of 0x3367C0) 2 -> 3: three languages
;   00113670  00333B98  10850014 -> 00000000  a branch of the row dispatch (rows 1..4) -> nop
;   0011367C  00333BA4  1083000B -> 00000000  a branch of the row dispatch (rows 1..4) -> nop
;   00113694  00333BBC  3C02009D -> 3C02009C  row 0's setting byte 0x9CB268 -> 0x9BEC46 (high half)
;   00113698  00333BC0  0C0CD9F0 -> 0C044FF1  jal 0x3367C0 (step +1/-1 with wrap) -> jal lang_cycle
;   0011369C  00333BC4  8044B268 -> 8044EC46  row 0's setting byte 0x9CB268 -> 0x9BEC46 (low half, the load of the old value)
;   001136A0  00333BC8  3C03009D -> 3C03009C  row 0's setting byte 0x9CB268 -> 0x9BEC46 (high half)
;   001136A8  00333BD0  A062B268 -> A062EC46  row 0's setting byte 0x9CB268 -> 0x9BEC46 (low half, the store of the new value)
;   00113744  00333C6C  0C0CDB40 -> 0C044FFE  SELECT: jal 0x336D00 -> jal lang_default (the language back to 0, Japanese)
;   00113774  00333C9C  24040005 -> 24040001  EXIT is cursor position 5 -> 1
;   0011380C  00333D34  24050002 -> 24050007  on leaving, GAME OPTION's cursor goes back to row 2 -> row 7 (EXTRA SETTING)
; --------------------------------------------------------------------------------------------------
main_copy:
00113408:  27BDFFE0  .word   0x27BDFFE0
0011340C:  3C0301DE  .word   0x3C0301DE
00113410:  FFBF0010  .word   0xFFBF0010
00113414:  7FB00000  .word   0x7FB00000
00113418:  9066E818  .word   0x9066E818
0011341C:  24030003  .word   0x24030003
00113420:  10C300EC  .word   0x10C300EC
00113424:  00000000  .word   0x00000000
00113428:  24040002  .word   0x24040002
0011342C:  50C4007D  .word   0x50C4007D
00113430:  0000282D  .word   0x0000282D
00113434:  24050001  .word   0x24050001
00113438:  10C50011  .word   0x10C50011
0011343C:  00000000  .word   0x00000000
00113440:  10C00003  .word   0x10C00003
00113444:  00000000  .word   0x00000000
00113448:  100000F8  .word   0x100000F8
0011344C:  DFBF0010  .word   0xDFBF0010
00113450:  0C04500A  .word   0x0C04500A                       ; changed (see above)
00113454:  00000000  .word   0x00000000
00113458:  3C0301DE  .word   0x3C0301DE
0011345C:  3C0401DE  .word   0x3C0401DE
00113460:  8C66E800  .word   0x8C66E800
00113464:  3C0301DE  .word   0x3C0301DE
00113468:  AC86E808  .word   0xAC86E808
0011346C:  9065E818  .word   0x9065E818
00113470:  3C0301DE  .word   0x3C0301DE
00113474:  24A40001  .word   0x24A40001
00113478:  100000EB  .word   0x100000EB
0011347C:  A064E818  .word   0xA064E818
00113480:  3C0301DE  .word   0x3C0301DE
00113484:  8C63E7D0  .word   0x8C63E7D0
00113488:  30630003  .word   0x30630003
0011348C:  14600048  .word   0x14600048
00113490:  00000000  .word   0x00000000
00113494:  3C0301DE  .word   0x3C0301DE
00113498:  8C67E7C8  .word   0x8C67E7C8
0011349C:  28E10008  .word   0x28E10008
001134A0:  10200043  .word   0x10200043
001134A4:  00000000  .word   0x00000000
001134A8:  2CE10008  .word   0x2CE10008
001134AC:  10200040  .word   0x10200040
001134B0:  00000000  .word   0x00000000
001134B4:  3C040011  .word   0x3C040011                       ; changed (see above)
001134B8:  00071880  .word   0x00071880
001134BC:  24843F70  .word   0x24843F70                       ; changed (see above)
001134C0:  00641821  .word   0x00641821
001134C4:  8C630000  .word   0x8C630000
001134C8:  00600008  .word   0x00600008
001134CC:  00000000  .word   0x00000000
001134D0:  3C040011  .word   0x3C040011                       ; changed (see above)
001134D4:  0000302D  .word   0x0000302D
001134D8:  24843838  .word   0x24843838                       ; changed (see above)
001134DC:  24070280  .word   0x24070280
001134E0:  24080040  .word   0x24080040
001134E4:  0C0CBFDC  .word   0x0C0CBFDC
001134E8:  24090160  .word   0x24090160
001134EC:  3C0401DE  .word   0x3C0401DE
001134F0:  3C0301DE  .word   0x3C0301DE
001134F4:  8C84E7C8  .word   0x8C84E7C8
001134F8:  24840001  .word   0x24840001
001134FC:  1000002C  .word   0x1000002C
00113500:  AC64E7C8  .word   0xAC64E7C8
00113504:  24E2FFFF  .word   0x24E2FFFF
00113508:  0007363C  .word   0x0007363C
0011350C:  00021140  .word   0x00021140
00113510:  3C040011  .word   0x3C040011                       ; changed (see above)
00113514:  0006363F  .word   0x0006363F
00113518:  24843838  .word   0x24843838                       ; changed (see above)
0011351C:  24480090  .word   0x24480090
00113520:  0000282D  .word   0x0000282D
00113524:  2407FE00  .word   0x2407FE00
00113528:  0C0CBFDC  .word   0x0C0CBFDC
0011352C:  2409012C  .word   0x2409012C
00113530:  3C0401DE  .word   0x3C0401DE
00113534:  3C0301DE  .word   0x3C0301DE
00113538:  8C84E7C8  .word   0x8C84E7C8
0011353C:  24840001  .word   0x24840001
00113540:  1000001B  .word   0x1000001B
00113544:  AC64E7C8  .word   0xAC64E7C8
00113548:  3C040011  .word   0x3C040011                       ; changed (see above)
0011354C:  0000282D  .word   0x0000282D
00113550:  24843838  .word   0x24843838                       ; changed (see above)
00113554:  24060006  .word   0x24060006
00113558:  2407FE00  .word   0x2407FE00
0011355C:  24080190  .word   0x24080190
00113560:  0C0CC004  .word   0x0C0CC004
00113564:  240900C0  .word   0x240900C0
00113568:  3C0401DE  .word   0x3C0401DE
0011356C:  3C0301DE  .word   0x3C0301DE
00113570:  8C84E7C8  .word   0x8C84E7C8
00113574:  24840001  .word   0x24840001
00113578:  1000000D  .word   0x1000000D
0011357C:  AC64E7C8  .word   0xAC64E7C8
00113580:  3C040011  .word   0x3C040011                       ; changed (see above)
00113584:  24060007  .word   0x24060007
00113588:  24843838  .word   0x24843838                       ; changed (see above)
0011358C:  24070280  .word   0x24070280
00113590:  24080190  .word   0x24080190
00113594:  0C0CBFDC  .word   0x0C0CBFDC
00113598:  240901E0  .word   0x240901E0
0011359C:  3C0401DE  .word   0x3C0401DE
001135A0:  3C0301DE  .word   0x3C0301DE
001135A4:  8C84E7C8  .word   0x8C84E7C8
001135A8:  24840001  .word   0x24840001
001135AC:  AC64E7C8  .word   0xAC64E7C8
001135B0:  3C0301DE  .word   0x3C0301DE
001135B4:  9064E810  .word   0x9064E810
001135B8:  30830001  .word   0x30830001
001135BC:  10600013  .word   0x10600013
001135C0:  00000000  .word   0x00000000
001135C4:  30830002  .word   0x30830002
001135C8:  10600010  .word   0x10600010
001135CC:  00000000  .word   0x00000000
001135D0:  3C0201DE  .word   0x3C0201DE
001135D4:  3C040011  .word   0x3C040011                       ; changed (see above)
001135D8:  9047E818  .word   0x9047E818
001135DC:  3C050040  .word   0x3C050040
001135E0:  3C0301DE  .word   0x3C0301DE
001135E4:  24843C48  .word   0x24843C48                       ; changed (see above)
001135E8:  24A54648  .word   0x24A54648
001135EC:  0000302D  .word   0x0000302D
001135F0:  3C0201DE  .word   0x3C0201DE
001135F4:  0000402D  .word   0x0000402D
001135F8:  A040E810  .word   0xA040E810
001135FC:  24E20001  .word   0x24E20001
00113600:  0000382D  .word   0x0000382D
00113604:  0C0556D4  .word   0x0C0556D4
00113608:  A062E818  .word   0xA062E818
0011360C:  3C0401DE  .word   0x3C0401DE
00113610:  3C0301DE  .word   0x3C0301DE
00113614:  8C84E7D0  .word   0x8C84E7D0
00113618:  24840001  .word   0x24840001
0011361C:  10000082  .word   0x10000082
00113620:  AC64E7D0  .word   0xAC64E7D0
00113624:  0C068D08  .word   0x0C068D08
00113628:  0000302D  .word   0x0000302D
0011362C:  0002843C  .word   0x0002843C
00113630:  24050002  .word   0x24050002                       ; changed (see above)
00113634:  3C0201DE  .word   0x3C0201DE
00113638:  8044E808  .word   0x8044E808
0011363C:  0C0CD948  .word   0x0C0CD948
00113640:  0010843F  .word   0x0010843F
00113644:  0002263C  .word   0x0002263C
00113648:  3C0301DE  .word   0x3C0301DE
0011364C:  0004263F  .word   0x0004263F
00113650:  AC64E808  .word   0xAC64E808
00113654:  24030004  .word   0x24030004
00113658:  00000000  .word   0x00000000                       ; changed (see above)
0011365C:  00000000  .word   0x00000000
00113660:  24030003  .word   0x24030003
00113664:  00000000  .word   0x00000000                       ; changed (see above)
00113668:  00000000  .word   0x00000000
0011366C:  24050003  .word   0x24050003                       ; changed (see above)
00113670:  00000000  .word   0x00000000                       ; changed (see above)
00113674:  00000000  .word   0x00000000
00113678:  24030001  .word   0x24030001
0011367C:  00000000  .word   0x00000000                       ; changed (see above)
00113680:  00000000  .word   0x00000000
00113684:  10800003  .word   0x10800003
00113688:  00000000  .word   0x00000000
0011368C:  10000029  .word   0x10000029
00113690:  0010343C  .word   0x0010343C
00113694:  3C02009C  .word   0x3C02009C                       ; changed (see above)
00113698:  0C044FF1  .word   0x0C044FF1                       ; changed (see above)
0011369C:  8044EC46  .word   0x8044EC46                       ; changed (see above)
001136A0:  3C03009C  .word   0x3C03009C                       ; changed (see above)
001136A4:  10000022  .word   0x10000022
001136A8:  A062EC46  .word   0xA062EC46                       ; changed (see above)
001136AC:  3C02009D  .word   0x3C02009D
001136B0:  0C0CD9F0  .word   0x0C0CD9F0
001136B4:  8044B269  .word   0x8044B269
001136B8:  3C03009D  .word   0x3C03009D
001136BC:  1000001C  .word   0x1000001C
001136C0:  A062B269  .word   0xA062B269
001136C4:  3C02009D  .word   0x3C02009D
001136C8:  8044B26A  .word   0x8044B26A
001136CC:  0C0CD9F0  .word   0x0C0CD9F0
001136D0:  24050008  .word   0x24050008
001136D4:  3C03009D  .word   0x3C03009D
001136D8:  10000015  .word   0x10000015
001136DC:  A062B26A  .word   0xA062B26A
001136E0:  0C0CDA20  .word   0x0C0CDA20
001136E4:  00000000  .word   0x00000000
001136E8:  10000011  .word   0x10000011
001136EC:  00000000  .word   0x00000000
001136F0:  3C0201DE  .word   0x3C0201DE
001136F4:  8044E7F8  .word   0x8044E7F8
001136F8:  0C0CD9F0  .word   0x0C0CD9F0
001136FC:  2405002F  .word   0x2405002F
00113700:  00021E3C  .word   0x00021E3C
00113704:  24042000  .word   0x24042000
00113708:  00031E3F  .word   0x00031E3F
0011370C:  3C0201DE  .word   0x3C0201DE
00113710:  AC43E7F8  .word   0xAC43E7F8
00113714:  0C0CDA68  .word   0x0C0CDA68
00113718:  24050003  .word   0x24050003
0011371C:  10400004  .word   0x10400004
00113720:  00000000  .word   0x00000000
00113724:  3C0201DE  .word   0x3C0201DE
00113728:  0C0532BC  .word   0x0C0532BC
0011372C:  8C44E7F8  .word   0x8C44E7F8
00113730:  0010343C  .word   0x0010343C
00113734:  0006343F  .word   0x0006343F
00113738:  30C30001  .word   0x30C30001
0011373C:  5060000A  .word   0x5060000A
00113740:  30C52000  .word   0x30C52000
00113744:  0C044FFE  .word   0x0C044FFE                       ; changed (see above)
00113748:  00000000  .word   0x00000000
0011374C:  3C0201DE  .word   0x3C0201DE
00113750:  24040126  .word   0x24040126
00113754:  AC40E7F8  .word   0xAC40E7F8
00113758:  0C0538FC  .word   0x0C0538FC
0011375C:  0000282D  .word   0x0000282D
00113760:  10000031  .word   0x10000031
00113764:  00000000  .word   0x00000000
00113768:  50A00007  .word   0x50A00007
0011376C:  30C34000  .word   0x30C34000
00113770:  3C0301DE  .word   0x3C0301DE
00113774:  24040001  .word   0x24040001                       ; changed (see above)
00113778:  8C63E808  .word   0x8C63E808
0011377C:  10640004  .word   0x10640004
00113780:  00000000  .word   0x00000000
00113784:  30C34000  .word   0x30C34000
00113788:  10600027  .word   0x10600027
0011378C:  00000000  .word   0x00000000
00113790:  50A00006  .word   0x50A00006
00113794:  2404013E  .word   0x2404013E
00113798:  24040126  .word   0x24040126
0011379C:  0C0538FC  .word   0x0C0538FC
001137A0:  0000282D  .word   0x0000282D
001137A4:  10000003  .word   0x10000003
001137A8:  00000000  .word   0x00000000
001137AC:  0C0538FC  .word   0x0C0538FC
001137B0:  0000282D  .word   0x0000282D
001137B4:  0C053318  .word   0x0C053318
001137B8:  00000000  .word   0x00000000
001137BC:  3C0401DE  .word   0x3C0401DE
001137C0:  3C0301DE  .word   0x3C0301DE
001137C4:  9084E818  .word   0x9084E818
001137C8:  24840001  .word   0x24840001
001137CC:  10000016  .word   0x10000016
001137D0:  A064E818  .word   0xA064E818
001137D4:  3C0301DE  .word   0x3C0301DE
001137D8:  9064E810  .word   0x9064E810
001137DC:  30830001  .word   0x30830001
001137E0:  10600011  .word   0x10600011
001137E4:  00000000  .word   0x00000000
001137E8:  30830002  .word   0x30830002
001137EC:  1060000E  .word   0x1060000E
001137F0:  00000000  .word   0x00000000
001137F4:  3C040033  .word   0x3C040033
001137F8:  0C0558E0  .word   0x0C0558E0
001137FC:  24841760  .word   0x24841760
00113800:  24040001  .word   0x24040001
00113804:  3C0301DE  .word   0x3C0301DE
00113808:  A064E820  .word   0xA064E820
0011380C:  24050007  .word   0x24050007                       ; changed (see above)
00113810:  3C0301DE  .word   0x3C0301DE
00113814:  3C0401DE  .word   0x3C0401DE
00113818:  AC65E800  .word   0xAC65E800
0011381C:  3C0301DE  .word   0x3C0301DE
00113820:  AC80E7F8  .word   0xAC80E7F8
00113824:  A060E818  .word   0xA060E818
00113828:  DFBF0010  .word   0xDFBF0010
0011382C:  7BB00000  .word   0x7BB00000
00113830:  03E00008  .word   0x03E00008
00113834:  27BD0020  .word   0x27BD0020

; --------------------------------------------------------------------------------------------------
; drawer_copy: the screen's item drawer (SOUND SETTING's, cloned)
;
; Draws one item of the screen by its case number through draw_cases. Inside it s0 = descs,
; s1 = y, s2 = x. Cases 0 and 1 are the new draw_header / draw_language; cases 6 and 7 (the
; footer and the EXIT bar) are the original's own case code at 0x113C20 and 0x113B88. Six other
; address pairs in it (four of 0x3D1E58, two of 0x3D1E68) still point at the game's own tables.
; Cloned from game code 0x333D60..0x334170 (260 words), placed at 0x113838..0x113C48.
; Every word is the original's except these (address here, address in the original, original word,
; new word, why):
;   00113850  00333D78  3C10003D -> 3C100011  address of the descriptor table: 0x3D1B10 -> 0x113DA8 (s0, high half)
;   00113858  00333D80  26101B10 -> 26103DA8  address of the descriptor table: 0x3D1B10 -> 0x113DA8 (low half)
;   00113878  00333DA0  3C040040 -> 3C040011  address of the drawer's case table: 0x404870 -> 0x113F90 (high half)
;   00113880  00333DA8  24844870 -> 24843F90  address of the drawer's case table: 0x404870 -> 0x113F90 (low half)
;   00113B98  003340C0  3C04003D -> 3C040011  address of an EXIT bar piece: 0x3D1CE4 -> 0x113E2C (high half)
;   00113BA0  003340C8  24841CE4 -> 24843E2C  address of an EXIT bar piece: 0x3D1CE4 -> 0x113E2C (low half)
;   00113BB4  003340DC  3C0B003D -> 3C0B0011  address of an EXIT bar piece: 0x3D1CF0 -> 0x113E38 (high half)
;   00113BBC  003340E4  256B1CF0 -> 256B3E38  address of an EXIT bar piece: 0x3D1CF0 -> 0x113E38 (low half)
;   00113BC0  003340E8  24020001 -> 24020002  the EXIT bar's stretched middle: texture slot literal 1 -> 2 (the words page)
;   00113BFC  00334124  3C04003D -> 3C040011  address of an EXIT bar piece: 0x3D1CFC -> 0x113E44 (high half)
;   00113C08  00334130  24841CFC -> 24843E44  address of an EXIT bar piece: 0x3D1CFC -> 0x113E44 (low half)
; --------------------------------------------------------------------------------------------------
drawer_copy:
00113838:  27BDFFA0  .word   0x27BDFFA0
0011383C:  FFBF0050  .word   0xFFBF0050
00113840:  7FB20040  .word   0x7FB20040
00113844:  7FB10030  .word   0x7FB10030
00113848:  7FB00020  .word   0x7FB00020
0011384C:  0080882D  .word   0x0080882D
00113850:  3C100011  .word   0x3C100011                       ; changed (see above)
00113854:  0C0CC088  .word   0x0C0CC088
00113858:  26103DA8  .word   0x26103DA8                       ; changed (see above)
0011385C:  8E230010  .word   0x8E230010
00113860:  84720002  .word   0x84720002
00113864:  84710004  .word   0x84710004
00113868:  80630000  .word   0x80630000
0011386C:  2C610008  .word   0x2C610008
00113870:  502000F0  .word   0x502000F0
00113874:  DFBF0050  .word   0xDFBF0050
00113878:  3C040011  .word   0x3C040011                       ; changed (see above)
0011387C:  00031880  .word   0x00031880
00113880:  24843F90  .word   0x24843F90                       ; changed (see above)
00113884:  00641821  .word   0x00641821
00113888:  8C630000  .word   0x8C630000
0011388C:  00600008  .word   0x00600008
00113890:  00000000  .word   0x00000000
00113894:  260401F8  .word   0x260401F8
00113898:  0240282D  .word   0x0240282D
0011389C:  0C0C0AB8  .word   0x0C0C0AB8
001138A0:  0220302D  .word   0x0220302D
001138A4:  100000E2  .word   0x100000E2
001138A8:  00000000  .word   0x00000000
001138AC:  2645FF80  .word   0x2645FF80
001138B0:  26040204  .word   0x26040204
001138B4:  0C0C0AB8  .word   0x0C0C0AB8
001138B8:  0220302D  .word   0x0220302D
001138BC:  26040060  .word   0x26040060
001138C0:  0240282D  .word   0x0240282D
001138C4:  0C0C0AB8  .word   0x0C0C0AB8
001138C8:  0220302D  .word   0x0220302D
001138CC:  3C02009D  .word   0x3C02009D
001138D0:  9042B268  .word   0x9042B268
001138D4:  50400007  .word   0x50400007
001138D8:  26450020  .word   0x26450020
001138DC:  26450020  .word   0x26450020
001138E0:  26040234  .word   0x26040234
001138E4:  0C0C0AB8  .word   0x0C0C0AB8
001138E8:  0220302D  .word   0x0220302D
001138EC:  100000D0  .word   0x100000D0
001138F0:  00000000  .word   0x00000000
001138F4:  26040240  .word   0x26040240
001138F8:  0C0C0AB8  .word   0x0C0C0AB8
001138FC:  0220302D  .word   0x0220302D
00113900:  100000CB  .word   0x100000CB
00113904:  00000000  .word   0x00000000
00113908:  2645FFC0  .word   0x2645FFC0
0011390C:  2604024C  .word   0x2604024C
00113910:  0C0C0AB8  .word   0x0C0C0AB8
00113914:  0220302D  .word   0x0220302D
00113918:  26040060  .word   0x26040060
0011391C:  0240282D  .word   0x0240282D
00113920:  0C0C0AB8  .word   0x0C0C0AB8
00113924:  0220302D  .word   0x0220302D
00113928:  3C02009D  .word   0x3C02009D
0011392C:  9042B269  .word   0x9042B269
00113930:  50400007  .word   0x50400007
00113934:  26450020  .word   0x26450020
00113938:  26450020  .word   0x26450020
0011393C:  26040258  .word   0x26040258
00113940:  0C0C0AB8  .word   0x0C0C0AB8
00113944:  0220302D  .word   0x0220302D
00113948:  100000B9  .word   0x100000B9
0011394C:  00000000  .word   0x00000000
00113950:  26040264  .word   0x26040264
00113954:  0C0C0AB8  .word   0x0C0C0AB8
00113958:  0220302D  .word   0x0220302D
0011395C:  100000B4  .word   0x100000B4
00113960:  00000000  .word   0x00000000
00113964:  2645FF60  .word   0x2645FF60
00113968:  26040210  .word   0x26040210
0011396C:  0C0C0AB8  .word   0x0C0C0AB8
00113970:  0220302D  .word   0x0220302D
00113974:  26040060  .word   0x26040060
00113978:  0240282D  .word   0x0240282D
0011397C:  0C0C0AB8  .word   0x0C0C0AB8
00113980:  0220302D  .word   0x0220302D
00113984:  3C02009D  .word   0x3C02009D
00113988:  3C03003D  .word   0x3C03003D
0011398C:  9042B26A  .word   0x9042B26A
00113990:  24631E58  .word   0x24631E58
00113994:  26450020  .word   0x26450020
00113998:  0220302D  .word   0x0220302D
0011399C:  00621021  .word   0x00621021
001139A0:  90430000  .word   0x90430000
001139A4:  00031040  .word   0x00031040
001139A8:  00431021  .word   0x00431021
001139AC:  00021080  .word   0x00021080
001139B0:  0C0C0AB8  .word   0x0C0C0AB8
001139B4:  02022021  .word   0x02022021
001139B8:  1000009D  .word   0x1000009D
001139BC:  00000000  .word   0x00000000
001139C0:  2645FF80  .word   0x2645FF80
001139C4:  2604021C  .word   0x2604021C
001139C8:  0C0C0AB8  .word   0x0C0C0AB8
001139CC:  0220302D  .word   0x0220302D
001139D0:  26040060  .word   0x26040060
001139D4:  0240282D  .word   0x0240282D
001139D8:  0C0C0AB8  .word   0x0C0C0AB8
001139DC:  0220302D  .word   0x0220302D
001139E0:  3C02009D  .word   0x3C02009D
001139E4:  3C03003D  .word   0x3C03003D
001139E8:  9042B26B  .word   0x9042B26B
001139EC:  24631E58  .word   0x24631E58
001139F0:  26450020  .word   0x26450020
001139F4:  0220302D  .word   0x0220302D
001139F8:  00621021  .word   0x00621021
001139FC:  90430000  .word   0x90430000
00113A00:  00031040  .word   0x00031040
00113A04:  00431021  .word   0x00431021
00113A08:  00021080  .word   0x00021080
00113A0C:  0C0C0AB8  .word   0x0C0C0AB8
00113A10:  02022021  .word   0x02022021
00113A14:  10000086  .word   0x10000086
00113A18:  00000000  .word   0x00000000
00113A1C:  2645FF60  .word   0x2645FF60
00113A20:  26040228  .word   0x26040228
00113A24:  0C0C0AB8  .word   0x0C0C0AB8
00113A28:  0220302D  .word   0x0220302D
00113A2C:  26040060  .word   0x26040060
00113A30:  0240282D  .word   0x0240282D
00113A34:  0C0C0AB8  .word   0x0C0C0AB8
00113A38:  0220302D  .word   0x0220302D
00113A3C:  3C0301DE  .word   0x3C0301DE
00113A40:  3C020036  .word   0x3C020036
00113A44:  8C63E7F8  .word   0x8C63E7F8
00113A48:  9042E068  .word   0x9042E068
00113A4C:  50620028  .word   0x50620028
00113A50:  3C026666  .word   0x3C026666
00113A54:  3C026666  .word   0x3C026666
00113A58:  24630001  .word   0x24630001
00113A5C:  34426667  .word   0x34426667
00113A60:  000327C2  .word   0x000327C2
00113A64:  00430018  .word   0x00430018
00113A68:  26450020  .word   0x26450020
00113A6C:  0220302D  .word   0x0220302D
00113A70:  00001810  .word   0x00001810
00113A74:  3C02003D  .word   0x3C02003D
00113A78:  00031883  .word   0x00031883
00113A7C:  24421E58  .word   0x24421E58
00113A80:  00641821  .word   0x00641821
00113A84:  00431021  .word   0x00431021
00113A88:  90430000  .word   0x90430000
00113A8C:  00031040  .word   0x00031040
00113A90:  00431021  .word   0x00431021
00113A94:  00021080  .word   0x00021080
00113A98:  0C0C0AB8  .word   0x0C0C0AB8
00113A9C:  02022021  .word   0x02022021
00113AA0:  3C0201DE  .word   0x3C0201DE
00113AA4:  2403000A  .word   0x2403000A
00113AA8:  8C44E7F8  .word   0x8C44E7F8
00113AAC:  26450034  .word   0x26450034
00113AB0:  0220302D  .word   0x0220302D
00113AB4:  24840001  .word   0x24840001
00113AB8:  3C02003D  .word   0x3C02003D
00113ABC:  0083001A  .word   0x0083001A
00113AC0:  24421E58  .word   0x24421E58
00113AC4:  00000000  .word   0x00000000
00113AC8:  00001810  .word   0x00001810
00113ACC:  00431021  .word   0x00431021
00113AD0:  90430000  .word   0x90430000
00113AD4:  00031040  .word   0x00031040
00113AD8:  00431021  .word   0x00431021
00113ADC:  00021080  .word   0x00021080
00113AE0:  0C0C0AB8  .word   0x0C0C0AB8
00113AE4:  02022021  .word   0x02022021
00113AE8:  10000051  .word   0x10000051
00113AEC:  00000000  .word   0x00000000
00113AF0:  24630001  .word   0x24630001
00113AF4:  34426667  .word   0x34426667
00113AF8:  000327C2  .word   0x000327C2
00113AFC:  00430018  .word   0x00430018
00113B00:  26450020  .word   0x26450020
00113B04:  0220302D  .word   0x0220302D
00113B08:  00001810  .word   0x00001810
00113B0C:  3C02003D  .word   0x3C02003D
00113B10:  00031883  .word   0x00031883
00113B14:  24421E68  .word   0x24421E68
00113B18:  00641821  .word   0x00641821
00113B1C:  00431021  .word   0x00431021
00113B20:  90430000  .word   0x90430000
00113B24:  00031040  .word   0x00031040
00113B28:  00431021  .word   0x00431021
00113B2C:  00021080  .word   0x00021080
00113B30:  0C0C0AB8  .word   0x0C0C0AB8
00113B34:  02022021  .word   0x02022021
00113B38:  3C0201DE  .word   0x3C0201DE
00113B3C:  2403000A  .word   0x2403000A
00113B40:  8C44E7F8  .word   0x8C44E7F8
00113B44:  26450034  .word   0x26450034
00113B48:  0220302D  .word   0x0220302D
00113B4C:  24840001  .word   0x24840001
00113B50:  3C02003D  .word   0x3C02003D
00113B54:  0083001A  .word   0x0083001A
00113B58:  24421E68  .word   0x24421E68
00113B5C:  00000000  .word   0x00000000
00113B60:  00001810  .word   0x00001810
00113B64:  00431021  .word   0x00431021
00113B68:  90430000  .word   0x90430000
00113B6C:  00031040  .word   0x00031040
00113B70:  00431021  .word   0x00431021
00113B74:  00021080  .word   0x00021080
00113B78:  0C0C0AB8  .word   0x0C0C0AB8
00113B7C:  02022021  .word   0x02022021
00113B80:  1000002B  .word   0x1000002B
00113B84:  00000000  .word   0x00000000
00113B88:  2604006C  .word   0x2604006C                       ; case 7 starts here (original 0x3340B0)
00113B8C:  0240282D  .word   0x0240282D
00113B90:  0C0C0AB8  .word   0x0C0C0AB8
00113B94:  0220302D  .word   0x0220302D
00113B98:  3C040011  .word   0x3C040011                       ; changed (see above)
00113B9C:  0240282D  .word   0x0240282D
00113BA0:  24843E2C  .word   0x24843E2C                       ; changed (see above)
00113BA4:  0220302D  .word   0x0220302D
00113BA8:  2407A828  .word   0x2407A828
00113BAC:  0C0C0B2C  .word   0x0C0C0B2C
00113BB0:  240800A0  .word   0x240800A0
00113BB4:  3C0B0011  .word   0x3C0B0011                       ; changed (see above)
00113BB8:  240300A0  .word   0x240300A0
00113BBC:  256B3E38  .word   0x256B3E38                       ; changed (see above)
00113BC0:  24020002  .word   0x24020002                       ; changed (see above)
00113BC4:  95680006  .word   0x95680006
00113BC8:  26440020  .word   0x26440020
00113BCC:  2625FFF0  .word   0x2625FFF0
00113BD0:  2406A828  .word   0x2406A828
00113BD4:  24070040  .word   0x24070040
00113BD8:  FFA80000  .word   0xFFA80000
00113BDC:  FFA30008  .word   0xFFA30008
00113BE0:  FFA00010  .word   0xFFA00010
00113BE4:  FFA20018  .word   0xFFA20018
00113BE8:  95690000  .word   0x95690000
00113BEC:  956A0002  .word   0x956A0002
00113BF0:  956B0004  .word   0x956B0004
00113BF4:  0C0C0BA8  .word   0x0C0C0BA8
00113BF8:  24080020  .word   0x24080020
00113BFC:  3C040011  .word   0x3C040011                       ; changed (see above)
00113C00:  26450060  .word   0x26450060
00113C04:  0220302D  .word   0x0220302D
00113C08:  24843E44  .word   0x24843E44                       ; changed (see above)
00113C0C:  2407A828  .word   0x2407A828
00113C10:  0C0C0B2C  .word   0x0C0C0B2C
00113C14:  240800A0  .word   0x240800A0
00113C18:  10000005  .word   0x10000005
00113C1C:  00000000  .word   0x00000000
00113C20:  26040078  .word   0x26040078                       ; case 6 starts here (original 0x334148)
00113C24:  0240282D  .word   0x0240282D
00113C28:  0C0C0AB8  .word   0x0C0C0AB8
00113C2C:  0220302D  .word   0x0220302D
drawer_epilogue:
00113C30:  DFBF0050  .word   0xDFBF0050                       ; the drawer's epilogue (original 0x334158)
00113C34:  7BB20040  .word   0x7BB20040
00113C38:  7BB10030  .word   0x7BB10030
00113C3C:  7BB00020  .word   0x7BB00020
00113C40:  03E00008  .word   0x03E00008
00113C44:  27BD0060  .word   0x27BD0060

; --------------------------------------------------------------------------------------------------
; hilite_copy: the cursor highlight drawer (SOUND SETTING's, cloned)
;
; Draws the highlight on the row under the cursor (the pill) or on EXIT.
; Cloned from game code 0x334170..0x3342C4 (85 words), placed at 0x113C48..0x113D9C.
; Every word is the original's except these (address here, address in the original, original word,
; new word, why):
;   00113C54  0033417C  24030005 -> 24030001  the EXIT highlight is at cursor position 5 -> 1
;   00113C74  0033419C  3C04003D -> 3C040011  address of an EXIT highlight piece: 0x3D1CC0 -> 0x113E50 (high half)
;   00113C7C  003341A4  24841CC0 -> 24843E50  address of an EXIT highlight piece: 0x3D1CC0 -> 0x113E50 (low half)
;   00113C8C  003341B4  3C0B003D -> 3C0B0011  address of an EXIT highlight piece: 0x3D1CCC -> 0x113E5C (high half)
;   00113C94  003341BC  256B1CCC -> 256B3E5C  address of an EXIT highlight piece: 0x3D1CCC -> 0x113E5C (low half)
;   00113C98  003341C0  24020001 -> 24020002  the EXIT highlight's stretched middle: texture slot literal 1 -> 2 (the words page)
;   00113CD4  003341FC  3C04003D -> 3C040011  address of an EXIT highlight piece: 0x3D1CD8 -> 0x113E68 (high half)
;   00113CDC  00334204  24841CD8 -> 24843E68  address of an EXIT highlight piece: 0x3D1CD8 -> 0x113E68 (low half)
;   00113CF4  0033421C  3C04003D -> 3C040011  address of a row-highlight pill piece: 0x3D1E04 -> 0x113E74 (high half)
;   00113CFC  00334224  24841E04 -> 24843E74  address of a row-highlight pill piece: 0x3D1E04 -> 0x113E74 (low half)
;   00113D0C  00334234  3C0B003D -> 3C0B0011  address of a row-highlight pill piece: 0x3D1E10 -> 0x113E80 (high half)
;   00113D14  0033423C  256B1E10 -> 256B3E80  address of a row-highlight pill piece: 0x3D1E10 -> 0x113E80 (low half)
;   00113D54  0033427C  3C04003D -> 3C040011  address of a row-highlight pill piece: 0x3D1E1C -> 0x113E8C (high half)
;   00113D5C  00334284  24841E1C -> 24843E8C  address of a row-highlight pill piece: 0x3D1E1C -> 0x113E8C (low half)
; --------------------------------------------------------------------------------------------------
hilite_copy:
00113C48:  27BDFFB0  .word   0x27BDFFB0
00113C4C:  3C0201DE  .word   0x3C0201DE
00113C50:  FFBF0040  .word   0xFFBF0040
00113C54:  24030001  .word   0x24030001                       ; changed (see above)
00113C58:  7FB10030  .word   0x7FB10030
00113C5C:  7FB00020  .word   0x7FB00020
00113C60:  0080882D  .word   0x0080882D
00113C64:  8C44E808  .word   0x8C44E808
00113C68:  00041140  .word   0x00041140
00113C6C:  14830021  .word   0x14830021
00113C70:  24500090  .word   0x24500090
00113C74:  3C040011  .word   0x3C040011                       ; changed (see above)
00113C78:  240501E0  .word   0x240501E0
00113C7C:  24843E50  .word   0x24843E50                       ; changed (see above)
00113C80:  24060190  .word   0x24060190
00113C84:  0C0C0B14  .word   0x0C0C0B14
00113C88:  2407A829  .word   0x2407A829
00113C8C:  3C0B0011  .word   0x3C0B0011                       ; changed (see above)
00113C90:  240300FF  .word   0x240300FF
00113C94:  256B3E5C  .word   0x256B3E5C                       ; changed (see above)
00113C98:  24020002  .word   0x24020002                       ; changed (see above)
00113C9C:  95680006  .word   0x95680006
00113CA0:  24040200  .word   0x24040200
00113CA4:  24050180  .word   0x24050180
00113CA8:  2406A829  .word   0x2406A829
00113CAC:  24070040  .word   0x24070040
00113CB0:  FFA80000  .word   0xFFA80000
00113CB4:  FFA30008  .word   0xFFA30008
00113CB8:  FFA00010  .word   0xFFA00010
00113CBC:  FFA20018  .word   0xFFA20018
00113CC0:  95690000  .word   0x95690000
00113CC4:  956A0002  .word   0x956A0002
00113CC8:  956B0004  .word   0x956B0004
00113CCC:  0C0C0BA8  .word   0x0C0C0BA8
00113CD0:  24080020  .word   0x24080020
00113CD4:  3C040011  .word   0x3C040011                       ; changed (see above)
00113CD8:  24050240  .word   0x24050240
00113CDC:  24843E68  .word   0x24843E68                       ; changed (see above)
00113CE0:  24060190  .word   0x24060190
00113CE4:  0C0C0B14  .word   0x0C0C0B14
00113CE8:  2407A829  .word   0x2407A829
00113CEC:  1000001F  .word   0x1000001F
00113CF0:  00000000  .word   0x00000000
00113CF4:  3C040011  .word   0x3C040011                       ; changed (see above)
00113CF8:  24050080  .word   0x24050080
00113CFC:  24843E74  .word   0x24843E74                       ; changed (see above)
00113D00:  0200302D  .word   0x0200302D
00113D04:  0C0C0B14  .word   0x0C0C0B14
00113D08:  2407A829  .word   0x2407A829
00113D0C:  3C0B0011  .word   0x3C0B0011                       ; changed (see above)
00113D10:  240300FF  .word   0x240300FF
00113D14:  256B3E80  .word   0x256B3E80                       ; changed (see above)
00113D18:  24020003  .word   0x24020003
00113D1C:  95680006  .word   0x95680006
00113D20:  2605FFF0  .word   0x2605FFF0
00113D24:  240400A0  .word   0x240400A0
00113D28:  2406A829  .word   0x2406A829
00113D2C:  24070140  .word   0x24070140
00113D30:  FFA80000  .word   0xFFA80000
00113D34:  FFA30008  .word   0xFFA30008
00113D38:  FFA00010  .word   0xFFA00010
00113D3C:  FFA20018  .word   0xFFA20018
00113D40:  95690000  .word   0x95690000
00113D44:  956A0002  .word   0x956A0002
00113D48:  956B0004  .word   0x956B0004
00113D4C:  0C0C0BA8  .word   0x0C0C0BA8
00113D50:  24080020  .word   0x24080020
00113D54:  3C040011  .word   0x3C040011                       ; changed (see above)
00113D58:  0200302D  .word   0x0200302D
00113D5C:  24843E8C  .word   0x24843E8C                       ; changed (see above)
00113D60:  240501E0  .word   0x240501E0
00113D64:  0C0C0B14  .word   0x0C0C0B14
00113D68:  2407A829  .word   0x2407A829
00113D6C:  3C0301DE  .word   0x3C0301DE
00113D70:  9063E818  .word   0x9063E818
00113D74:  28630003  .word   0x28630003
00113D78:  54600004  .word   0x54600004
00113D7C:  DFBF0040  .word   0xDFBF0040
00113D80:  0C055728  .word   0x0C055728
00113D84:  0220202D  .word   0x0220202D
00113D88:  DFBF0040  .word   0xDFBF0040
00113D8C:  7BB10030  .word   0x7BB10030
00113D90:  7BB00020  .word   0x7BB00020
00113D94:  03E00008  .word   0x03E00008
00113D98:  27BD0050  .word   0x27BD0050

; --------------------------------------------------------------------------------------------------
; pad: alignment to the descriptor table (zeros)
; --------------------------------------------------------------------------------------------------
pad:
00113D9C:  00000000  .word   0x00000000                       ; alignment
00113DA0:  00000000  .word   0x00000000                       ; alignment
00113DA4:  00000000  .word   0x00000000                       ; alignment

; --------------------------------------------------------------------------------------------------
; descs: the drawer's descriptor table (s0 in drawer_copy)
;
; The game's 11 descriptors at 0x3D1B10 + 12k, copied with the texture slot 1 -> 2 (the words page
; of GAME OPTION's set, which this screen loads). draw_language uses entry 8 (s0 + 0x60), the colon.
; --------------------------------------------------------------------------------------------------
descs:
00113DA8:  00E00000  .hword  0x0000, 0x00E0                   ; descs[0] (from 0x3D1B10): u = 0, v = 224
00113DAC:  002000E0  .hword  0x00E0, 0x0020                   ;   width 224, height 32
00113DB0:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113DB4:  00200000  .hword  0x0000, 0x0020                   ; descs[1] (from 0x3D1B1C): u = 0, v = 32
00113DB8:  00200080  .hword  0x0080, 0x0020                   ;   width 128, height 32
00113DBC:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113DC0:  00200080  .hword  0x0080, 0x0020                   ; descs[2] (from 0x3D1B28): u = 128, v = 32
00113DC4:  00200080  .hword  0x0080, 0x0020                   ;   width 128, height 32
00113DC8:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113DCC:  00400000  .hword  0x0000, 0x0040                   ; descs[3] (from 0x3D1B34): u = 0, v = 64
00113DD0:  002000C0  .hword  0x00C0, 0x0020                   ;   width 192, height 32
00113DD4:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113DD8:  00600000  .hword  0x0000, 0x0060                   ; descs[4] (from 0x3D1B40): u = 0, v = 96
00113DDC:  002000C0  .hword  0x00C0, 0x0020                   ;   width 192, height 32
00113DE0:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113DE4:  00800000  .hword  0x0000, 0x0080                   ; descs[5] (from 0x3D1B4C): u = 0, v = 128
00113DE8:  002000A0  .hword  0x00A0, 0x0020                   ;   width 160, height 32
00113DEC:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113DF0:  000000C0  .hword  0x00C0, 0x0000                   ; descs[6] (from 0x3D1B58): u = 192, v = 0
00113DF4:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113DF8:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113DFC:  000000E0  .hword  0x00E0, 0x0000                   ; descs[7] (from 0x3D1B64): u = 224, v = 0
00113E00:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E04:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113E08:  000000A0  .hword  0x00A0, 0x0000                   ; descs[8] (from 0x3D1B70), the colon: u = 160, v = 0
00113E0C:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E10:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113E14:  00000020  .hword  0x0020, 0x0000                   ; descs[9] (from 0x3D1B7C): u = 32, v = 0
00113E18:  00200080  .hword  0x0080, 0x0020                   ;   width 128, height 32
00113E1C:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113E20:  01E00000  .hword  0x0000, 0x01E0                   ; descs[10] (from 0x3D1B88): u = 0, v = 480
00113E24:  00200200  .hword  0x0200, 0x0020                   ;   width 512, height 32
00113E28:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2

; --------------------------------------------------------------------------------------------------
; exit_desc: EXIT bar and EXIT highlight pieces, texture slot 1 -> 2
;
; Copies of the game's descriptors, used by drawer_copy (the first three) and hilite_copy (the next
; three).
; --------------------------------------------------------------------------------------------------
exit_desc:
00113E2C:  01600000  .hword  0x0000, 0x0160                   ; copy of 0x3D1CE4: u = 0, v = 352
00113E30:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E34:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113E38:  01600020  .hword  0x0020, 0x0160                   ; copy of 0x3D1CF0: u = 32, v = 352
00113E3C:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E40:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113E44:  01600040  .hword  0x0040, 0x0160                   ; copy of 0x3D1CFC: u = 64, v = 352
00113E48:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E4C:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113E50:  01400000  .hword  0x0000, 0x0140                   ; copy of 0x3D1CC0: u = 0, v = 320
00113E54:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E58:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113E5C:  01400020  .hword  0x0020, 0x0140                   ; copy of 0x3D1CCC: u = 32, v = 320
00113E60:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E64:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2
00113E68:  01400040  .hword  0x0040, 0x0140                   ; copy of 0x3D1CD8: u = 64, v = 320
00113E6C:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E70:  00000002  .byte   0x02, 0x00, 0x00, 0x00           ;   texture slot 2

; --------------------------------------------------------------------------------------------------
; pill_desc: the row-highlight pill, three pieces, texture slot 3 (page 4)
;
; Copies of the game's descriptors at 0x3D1E04/10/1C with v = 96 -> 224 (the same pill on page 4).
; --------------------------------------------------------------------------------------------------
pill_desc:
00113E74:  00E000A0  .hword  0x00A0, 0x00E0                   ; copy of 0x3D1E04, v moved: u = 160, v = 224
00113E78:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E7C:  00000003  .byte   0x03, 0x00, 0x00, 0x00           ;   texture slot 3
00113E80:  00E000C0  .hword  0x00C0, 0x00E0                   ; copy of 0x3D1E10, v moved: u = 192, v = 224
00113E84:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E88:  00000003  .byte   0x03, 0x00, 0x00, 0x00           ;   texture slot 3
00113E8C:  00E000E0  .hword  0x00E0, 0x00E0                   ; copy of 0x3D1E1C, v moved: u = 224, v = 224
00113E90:  00200020  .hword  0x0020, 0x0020                   ;   width 32, height 32
00113E94:  00000003  .byte   0x03, 0x00, 0x00, 0x00           ;   texture slot 3

; --------------------------------------------------------------------------------------------------
; header_desc, language_desc, value_desc: the new pictures (texture slot 1, the labels page)
;
; value_desc is indexed by the setting: value_desc + 12 * setting.
; --------------------------------------------------------------------------------------------------
header_desc:
00113E98:  01A00000  .hword  0x0000, 0x01A0                   ; header_desc: the EXTRA SETTING header: u = 0, v = 416
00113E9C:  002000BA  .hword  0x00BA, 0x0020                   ;   width 186, height 32
00113EA0:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
language_desc:
00113EA4:  01C00000  .hword  0x0000, 0x01C0                   ; language_desc: LANGUAGE: u = 0, v = 448
00113EA8:  00200080  .hword  0x0080, 0x0020                   ;   width 128, height 32
00113EAC:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
value_desc:
00113EB0:  01E0006D  .hword  0x006D, 0x01E0                   ; value 0: Japanese: u = 109, v = 480
00113EB4:  0020004C  .hword  0x004C, 0x0020                   ;   width 76, height 32
00113EB8:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113EBC:  01C00082  .hword  0x0082, 0x01C0                   ; value 1: ENGLISH: u = 130, v = 448
00113EC0:  0020005C  .hword  0x005C, 0x0020                   ;   width 92, height 32
00113EC4:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113EC8:  01E00000  .hword  0x0000, 0x01E0                   ; value 2: ESPANOL: u = 0, v = 480
00113ECC:  00200065  .hword  0x0065, 0x0020                   ;   width 101, height 32
00113ED0:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1

; --------------------------------------------------------------------------------------------------
; labels: GAME OPTION's row labels, 9 entries (was 8 at 0x3D1A60)
;
; Rows 0..6 are the original seven, row 7 is the new EXTRA SETTING label, row 8 is the original
; EXIT label.
; --------------------------------------------------------------------------------------------------
labels:
00113ED4:  00200000  .hword  0x0000, 0x0020                   ; row 0: u = 0, v = 32
00113ED8:  00200100  .hword  0x0100, 0x0020                   ;   width 256, height 32
00113EDC:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113EE0:  00400000  .hword  0x0000, 0x0040                   ; row 1: u = 0, v = 64
00113EE4:  00200100  .hword  0x0100, 0x0020                   ;   width 256, height 32
00113EE8:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113EEC:  00600000  .hword  0x0000, 0x0060                   ; row 2: u = 0, v = 96
00113EF0:  00200100  .hword  0x0100, 0x0020                   ;   width 256, height 32
00113EF4:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113EF8:  00800000  .hword  0x0000, 0x0080                   ; row 3: u = 0, v = 128
00113EFC:  00200100  .hword  0x0100, 0x0020                   ;   width 256, height 32
00113F00:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113F04:  00A00000  .hword  0x0000, 0x00A0                   ; row 4: u = 0, v = 160
00113F08:  00200100  .hword  0x0100, 0x0020                   ;   width 256, height 32
00113F0C:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113F10:  00C00000  .hword  0x0000, 0x00C0                   ; row 5: u = 0, v = 192
00113F14:  00200100  .hword  0x0100, 0x0020                   ;   width 256, height 32
00113F18:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113F1C:  00E00000  .hword  0x0000, 0x00E0                   ; row 6: u = 0, v = 224
00113F20:  00200100  .hword  0x0100, 0x0020                   ;   width 256, height 32
00113F24:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113F28:  01800000  .hword  0x0000, 0x0180                   ; row 7: EXTRA SETTING (new): u = 0, v = 384
00113F2C:  00200100  .hword  0x0100, 0x0020                   ;   width 256, height 32
00113F30:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1
00113F34:  01600000  .hword  0x0000, 0x0160                   ; row 8: EXIT: u = 0, v = 352
00113F38:  00200100  .hword  0x0100, 0x0020                   ;   width 256, height 32
00113F3C:  00000001  .byte   0x01, 0x00, 0x00, 0x00           ;   texture slot 1

; --------------------------------------------------------------------------------------------------
; launch: GAME OPTION's row -> routine table, 9 entries (was 8 at 0x3D1850)
; --------------------------------------------------------------------------------------------------
launch:
00113F40:  00331CA0  .word   0x00331CA0                       ; row 0: 0x331CA0
00113F44:  00332980  .word   0x00332980                       ; row 1: 0x332980
00113F48:  00333930  .word   0x00333930                       ; row 2: 0x333930 (SOUND SETTING)
00113F4C:  003342D0  .word   0x003342D0                       ; row 3: 0x3342D0
00113F50:  00336500  .word   0x00336500                       ; row 4: 0x336500
00113F54:  00334F60  .word   0x00334F60                       ; row 5: 0x334F60
00113F58:  00335D70  .word   0x00335D70                       ; row 6: 0x335D70
00113F5C:  00113408  .word   0x00113408                       ; row 7: 0x113408 = main_copy, EXTRA SETTING (new)
00113F60:  003303D0  .word   0x003303D0                       ; row 8: 0x3303D0 (EXIT, the original last entry)

; --------------------------------------------------------------------------------------------------
; params: GAME OPTION's row -> screen id bytes, 9 entries (was 8 at 0x3D1E78), then padding
;
; Row 7 passes 4, SOUND SETTING's id (background dimmed, no wheel).
; --------------------------------------------------------------------------------------------------
params:
00113F64:  05040302  .byte   0x02, 0x03, 0x04, 0x05           ; rows 0..3
00113F68:  040D0706  .byte   0x06, 0x07, 0x0D, 0x04           ; rows 4..7 (row 7 = 4, new)
00113F6C:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; row 8 (EXIT), then 3 bytes of padding

; --------------------------------------------------------------------------------------------------
; build_steps: the screen build's step table, 8 entries (used by main_copy; was 0x404850)
;
; Entries 0, 1, 6, 7 point to the same steps as the original's (in the copy); entries 2..5, which
; the original sends to its 0x333A2C, go to the copy of 0x333A14 instead, so steps 2..5 of the
; build are skipped.
; --------------------------------------------------------------------------------------------------
build_steps:
00113F70:  001134D0  .word   0x001134D0                       ; step 0: 0x1134D0 = copy of 0x3339F8 (original entry 0x3339F8)
00113F74:  00113504  .word   0x00113504                       ; step 1: 0x113504 = copy of 0x333A2C (original entry 0x333A2C)
00113F78:  001134EC  .word   0x001134EC                       ; step 2: 0x1134EC = copy of 0x333A14 (original entry 0x333A2C)
00113F7C:  001134EC  .word   0x001134EC                       ; step 3: 0x1134EC = copy of 0x333A14 (original entry 0x333A2C)
00113F80:  001134EC  .word   0x001134EC                       ; step 4: 0x1134EC = copy of 0x333A14 (original entry 0x333A2C)
00113F84:  001134EC  .word   0x001134EC                       ; step 5: 0x1134EC = copy of 0x333A14 (original entry 0x333A2C)
00113F88:  00113548  .word   0x00113548                       ; step 6: 0x113548 = copy of 0x333A70 (original entry 0x333A70)
00113F8C:  00113580  .word   0x00113580                       ; step 7: 0x113580 = copy of 0x333AA8 (original entry 0x333AA8)

; --------------------------------------------------------------------------------------------------
; draw_cases: the drawer's case table, 8 entries (used by drawer_copy; was 0x404870)
; --------------------------------------------------------------------------------------------------
draw_cases:
00113F90:  001140C0  .word   0x001140C0                       ; case 0: 0x1140C0 = draw_header (new) (original entry 0x333DBC)
00113F94:  001140DC  .word   0x001140DC                       ; case 1: 0x1140DC = draw_language (new) (original entry 0x333DD4)
00113F98:  00113C30  .word   0x00113C30                       ; case 2: 0x113C30 = drawer_epilogue (nothing drawn) (original entry 0x333E30)
00113F9C:  00113C30  .word   0x00113C30                       ; case 3: 0x113C30 = drawer_epilogue (nothing drawn) (original entry 0x333E8C)
00113FA0:  00113C30  .word   0x00113C30                       ; case 4: 0x113C30 = drawer_epilogue (nothing drawn) (original entry 0x333EE8)
00113FA4:  00113C30  .word   0x00113C30                       ; case 5: 0x113C30 = drawer_epilogue (nothing drawn) (original entry 0x333F44)
00113FA8:  00113C20  .word   0x00113C20                       ; case 6: 0x113C20 = copy of 0x334148 (original entry 0x334148)
00113FAC:  00113B88  .word   0x00113B88                       ; case 7: 0x113B88 = copy of 0x3340B0 (original entry 0x3340B0)

; --------------------------------------------------------------------------------------------------
; lang_sync: the language byte = the setting
;
; Leaf; uses t0, t1. [0x92F35F] = [0x9BEC46]. Called by lang_cycle, lang_default and load_sync.
; --------------------------------------------------------------------------------------------------
lang_sync:
00113FB0:  3C08009C  lui     t0, 0x9c                         ; t0 = 0x9C0000
00113FB4:  9109EC46  lbu     t1, -0x13ba(t0)                  ; t1 = [0x9BEC46], the setting
00113FB8:  3C080093  lui     t0, 0x93                         ; t0 = 0x930000
00113FBC:  03E00008  jr      ra                               ; return
00113FC0:  A109F35F  sb      t1, -0xca1(t0)                   ; (delay) [0x92F35F] = t1, the language byte

; --------------------------------------------------------------------------------------------------
; lang_cycle: row 0's value step, called by main_copy in place of 0x3367C0
;
; In: a0 = the current value, a1 = 3 (the count). 0x3367C0 steps the value +1 / -1 and wraps it
; inside 0..a1-1, returning it in v0. This stub stores the new value in 0x9BEC46, copies it to the
; language byte and returns it in v0 (main_copy stores it in 0x9BEC46 again).
; --------------------------------------------------------------------------------------------------
lang_cycle:
00113FC4:  27BDFFF0  addiu   sp, sp, -0x10                    ; frame of 16 bytes
00113FC8:  FFBF0000  sd      ra, 0x0(sp)                      ; save ra
00113FCC:  0C0CD9F0  jal     0x3367c0                         ; v0 = the next value (0..2)
00113FD0:  00000000  nop                                      ; (delay)
00113FD4:  3C08009C  lui     t0, 0x9c                         ; t0 = 0x9C0000
00113FD8:  A102EC46  sb      v0, -0x13ba(t0)                  ; [0x9BEC46] = v0
00113FDC:  FFA20008  sd      v0, 0x8(sp)                      ; keep v0 across the call
00113FE0:  0C044FEC  jal     lang_sync                        ; the language byte = the setting
00113FE4:  00000000  nop                                      ; (delay)
00113FE8:  DFA20008  ld      v0, 0x8(sp)                      ; v0 back
00113FEC:  DFBF0000  ld      ra, 0x0(sp)                      ; ra back
00113FF0:  03E00008  jr      ra                               ; return v0
00113FF4:  27BD0010  addiu   sp, sp, 0x10                     ; (delay) free the frame

; --------------------------------------------------------------------------------------------------
; lang_default: SELECT on this screen, called by main_copy in place of 0x336D00
;
; The setting = 0 (Japanese), then lang_sync (a tail jump: lang_sync returns to the caller).
; --------------------------------------------------------------------------------------------------
lang_default:
00113FF8:  3C08009C  lui     t0, 0x9c                         ; t0 = 0x9C0000
00113FFC:  08044FEC  j       lang_sync                        ; tail jump to lang_sync
00114000:  A100EC46  sb      zero, -0x13ba(t0)                ; (delay) [0x9BEC46] = 0

; --------------------------------------------------------------------------------------------------
; load_sync: the card load's last copy (called from 0x2FD9BC in place of 0x127120)
;
; Does the copy with the caller's arguments (the last block, 7 bytes, now including 0x9BEC46),
; then sets the language byte from the restored setting.
; --------------------------------------------------------------------------------------------------
load_sync:
00114004:  27BDFFF0  addiu   sp, sp, -0x10                    ; frame of 16 bytes
00114008:  FFBF0000  sd      ra, 0x0(sp)                      ; save ra
0011400C:  0C049C48  jal     0x127120                         ; the original copy
00114010:  00000000  nop                                      ; (delay)
00114014:  0C044FEC  jal     lang_sync                        ; the language byte = the setting
00114018:  00000000  nop                                      ; (delay)
0011401C:  DFBF0000  ld      ra, 0x0(sp)                      ; ra back
00114020:  03E00008  jr      ra                               ; return
00114024:  27BD0010  addiu   sp, sp, 0x10                     ; (delay) free the frame

; --------------------------------------------------------------------------------------------------
; tex_init: the screen's init, called by main_copy in place of 0x32FCD0
;
; Sets the screen id [0x1DDE820] to 1 (GAME OPTION) for the init call, so GAME OPTION's texture
; set is loaded, then back to 4 (SOUND's id: the background dimmed, no wheel).
; --------------------------------------------------------------------------------------------------
tex_init:
00114028:  27BDFFF0  addiu   sp, sp, -0x10                    ; frame of 16 bytes
0011402C:  FFBF0000  sd      ra, 0x0(sp)                      ; save ra
00114030:  3C0801DE  lui     t0, 0x1de                        ; t0 = 0x1DE0000
00114034:  24090001  addiu   t1, zero, 0x1                    ; t1 = 1, GAME OPTION's id
00114038:  0C0CBF34  jal     0x32fcd0                         ; the screen's init (loads the textures by the id)
0011403C:  A109E820  sb      t1, -0x17e0(t0)                  ; (delay) [0x1DDE820] = 1
00114040:  3C0801DE  lui     t0, 0x1de                        ; t0 = 0x1DE0000
00114044:  24090004  addiu   t1, zero, 0x4                    ; t1 = 4, SOUND SETTING's id
00114048:  A109E820  sb      t1, -0x17e0(t0)                  ; [0x1DDE820] = 4
0011404C:  DFBF0000  ld      ra, 0x0(sp)                      ; ra back
00114050:  03E00008  jr      ra                               ; return
00114054:  27BD0010  addiu   sp, sp, 0x10                     ; (delay) free the frame

; --------------------------------------------------------------------------------------------------
; snap: the language when GAME OPTION was entered (byte 0; written by snap_copy)
; --------------------------------------------------------------------------------------------------
snap:
00114058:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; byte 0: the snapshot, bytes 1..3 unused

; --------------------------------------------------------------------------------------------------
; snap_copy: the settings snapshot's last copy (called from 0x2FD144 in place of 0x127120)
;
; Entering GAME OPTION copies the settings aside (0x2FD0B0) so its EXIT can tell whether to save.
; This does that copy, then also keeps [0x9BEC46] in snap.
; --------------------------------------------------------------------------------------------------
snap_copy:
0011405C:  27BDFFF0  addiu   sp, sp, -0x10                    ; frame of 16 bytes
00114060:  FFBF0000  sd      ra, 0x0(sp)                      ; save ra
00114064:  0C049C48  jal     0x127120                         ; the original copy
00114068:  00000000  nop                                      ; (delay)
0011406C:  3C08009C  lui     t0, 0x9c                         ; t0 = 0x9C0000
00114070:  9109EC46  lbu     t1, -0x13ba(t0)                  ; t1 = [0x9BEC46], the setting
00114074:  3C080011  lui     t0, 0x11                         ; t0 = 0x110000
00114078:  A1094058  sb      t1, 0x4058(t0)                   ; [snap] = t1
0011407C:  DFBF0000  ld      ra, 0x0(sp)                      ; ra back
00114080:  03E00008  jr      ra                               ; return
00114084:  27BD0010  addiu   sp, sp, 0x10                     ; (delay) free the frame

; --------------------------------------------------------------------------------------------------
; snap_compare: the auto-save's last compare (called from 0x2FD240 in place of 0x3015B0)
;
; GAME OPTION's EXIT compares the settings with the snapshot (0x2FD160) and saves on a difference.
; This runs the original compare; when it finds no difference (v0 = 0), v0 = setting XOR snap,
; so a change of the language alone also makes it save.
; --------------------------------------------------------------------------------------------------
snap_compare:
00114088:  27BDFFF0  addiu   sp, sp, -0x10                    ; frame of 16 bytes
0011408C:  FFBF0000  sd      ra, 0x0(sp)                      ; save ra
00114090:  0C0C056C  jal     0x3015b0                         ; v0 = the original compare
00114094:  00000000  nop                                      ; (delay)
00114098:  14400006  bne     v0, zero, snap_compare_out       ; already different: return v0 as it is
0011409C:  00000000  nop                                      ; (delay)
001140A0:  3C08009C  lui     t0, 0x9c                         ; t0 = 0x9C0000
001140A4:  9109EC46  lbu     t1, -0x13ba(t0)                  ; t1 = [0x9BEC46], the setting
001140A8:  3C080011  lui     t0, 0x11                         ; t0 = 0x110000
001140AC:  910A4058  lbu     t2, 0x4058(t0)                   ; t2 = [snap]
001140B0:  012A1026  xor     v0, t1, t2                       ; v0 = setting XOR snapshot: non-zero when the language changed
snap_compare_out:
001140B4:  DFBF0000  ld      ra, 0x0(sp)                      ; ra back
001140B8:  03E00008  jr      ra                               ; return v0
001140BC:  27BD0010  addiu   sp, sp, 0x10                     ; (delay) free the frame

; --------------------------------------------------------------------------------------------------
; draw_header: drawer case 0, the EXTRA SETTING header
;
; Runs inside drawer_copy's frame: s0 = descs, s1 = y, s2 = x. Ends by jumping to the drawer's
; epilogue.
; --------------------------------------------------------------------------------------------------
draw_header:
001140C0:  3C040011  lui     a0, 0x11                         ; a0 = 0x110000 ...
001140C4:  24843E98  addiu   a0, a0, 0x3e98                   ; ... + 0x3E98 = header_desc
001140C8:  0240282D  daddu   a1, s2, zero                     ; a1 = x
001140CC:  0C0C0AB8  jal     0x302ae0                         ; draw the picture
001140D0:  0220302D  daddu   a2, s1, zero                     ; (delay) a2 = y
001140D4:  08044F0C  j       drawer_epilogue                  ; to the drawer's epilogue
001140D8:  00000000  nop                                      ; (delay)

; --------------------------------------------------------------------------------------------------
; draw_language: drawer case 1, the LANGUAGE row
;
; LANGUAGE at x - 0x80, the colon at x, the current value at x + 0x20; the value's picture is
; value_desc + 12 * [0x9BEC46]. Same frame as draw_header.
; --------------------------------------------------------------------------------------------------
draw_language:
001140DC:  3C040011  lui     a0, 0x11                         ; a0 = 0x110000 ...
001140E0:  24843EA4  addiu   a0, a0, 0x3ea4                   ; ... + 0x3EA4 = language_desc
001140E4:  2645FF80  addiu   a1, s2, -0x80                    ; a1 = x - 0x80
001140E8:  0C0C0AB8  jal     0x302ae0                         ; draw LANGUAGE
001140EC:  0220302D  daddu   a2, s1, zero                     ; (delay) a2 = y
001140F0:  26040060  addiu   a0, s0, 0x60                     ; a0 = s0 + 0x60 = descs[8], the colon
001140F4:  0240282D  daddu   a1, s2, zero                     ; a1 = x
001140F8:  0C0C0AB8  jal     0x302ae0                         ; draw the colon
001140FC:  0220302D  daddu   a2, s1, zero                     ; (delay) a2 = y
00114100:  3C02009C  lui     v0, 0x9c                         ; v0 = 0x9C0000
00114104:  9042EC46  lbu     v0, -0x13ba(v0)                  ; v0 = [0x9BEC46], the setting
00114108:  00021840  sll     v1, v0, 1                        ; v1 = setting * 2
0011410C:  00621821  addu    v1, v1, v0                       ; v1 = setting * 3
00114110:  00031880  sll     v1, v1, 2                        ; v1 = setting * 12
00114114:  3C040011  lui     a0, 0x11                         ; a0 = 0x110000 ...
00114118:  24843EB0  addiu   a0, a0, 0x3eb0                   ; ... + 0x3EB0 = value_desc
0011411C:  00832021  addu    a0, a0, v1                       ; a0 = value_desc + 12 * setting
00114120:  26450020  addiu   a1, s2, 0x20                     ; a1 = x + 0x20
00114124:  0C0C0AB8  jal     0x302ae0                         ; draw the value
00114128:  0220302D  daddu   a2, s1, zero                     ; (delay) a2 = y
0011412C:  08044F0C  j       drawer_epilogue                  ; to the drawer's epilogue
00114130:  00000000  nop                                      ; (delay)

; end of listing
