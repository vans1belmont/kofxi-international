; three_line_quotes.s -- The King of Fighters XI (PS2, SLPS-25660 v1.03): the three-line win quote hook
;
; What it does
;   The game draws every win quote at one Y position, which is right for quotes of one or two lines
;   (lines 26 rows apart, centred in the text band). A quote of three lines ran past the lower edge
;   of the band. This hook counts the lines of the quote being shown and, for three or more lines,
;   moves the text object 13 rows up (half the line pitch). Quotes of one or two lines are left
;   exactly where the game puts them, in every language.
;
; Where it is called from
;   The scene-script command that shows a win quote (handler 0x328B70) creates the text task,
;   stores x / y at +0x00 / +0x02 of the text object (s0), calls the message picker 0x15EAA0 and
;   then stores the picked entry index (v0) at +0x26 of the object, at 0x328C08. That store is
;   replaced by a jal to this hook; the hook performs the store itself first. The jal's delay
;   slot is the next original word (lhu a0, 0xda(s4)), which still runs; the handler reloads ra
;   from its own stack frame afterwards.
;
;     address   original  new       purpose
;     00328C08  A6020026  0C04504E  the win-quote command stores the entry index via the hook
;
; Where it lives
;   29 words at 0x114138..0x1141AC, over unreferenced library functions (dead code) of the
;   original executable.
;
; Registers
;   In:   s0 = the text object, v0 = the message entry index.
;   Uses: t0..t6 only (a leaf routine: no stack, no calls). a0 is not touched.
;
; Game data it reads
;   [0x9BD510]  pointer to the loaded win-quote message file (0 when none is loaded).
;               The file starts with a table of u32 offsets, one per entry, from the file start;
;               bit 0 of an offset is cleared before use, as the game's own text task (0x19AED0)
;               does at 0x19AF78. An entry is a run of u16 codes; the code's top nibble 0x1000
;               ends the entry and 0x2000 marks a line. The hook counts the 0x2000 codes.
;
; Listing format: address:  word (little-endian u32 as stored)  instruction  ; comment

; --------------------------------------------------------------------------------------------------
; line_hook: store the index, count the lines, lift a three-line quote
;
; t0 = message file, t1 = walking pointer, t2 = line count, t3 = code, t4 = scratch,
; t5 = 0x1000 (END nibble), t6 = 0x2000 (LINE nibble)
; --------------------------------------------------------------------------------------------------
line_hook:
00114138:  A6020026  sh      v0, 0x26(s0)                     ; the displaced original word: [s0+0x26] = entry index
0011413C:  3C08009C  lui     t0, 0x9c                         ; t0 = 0x9C0000
00114140:  8D08D510  lw      t0, -0x2af0(t0)                  ; t0 = [0x9BD510], the message file
00114144:  11000017  beq     t0, zero, out                    ; no file loaded: nothing more to do
00114148:  00024880  sll     t1, v0, 2                        ; (delay) t1 = index * 4
0011414C:  01094821  addu    t1, t0, t1                       ; t1 = &offset[index]
00114150:  8D290000  lw      t1, 0x0(t1)                      ; t1 = the entry's offset
00114154:  00094842  srl     t1, t1, 1                        ; clear bit 0 of the offset ...
00114158:  00094840  sll     t1, t1, 1                        ; ... (as the game's text task does)
0011415C:  01094821  addu    t1, t0, t1                       ; t1 = the entry's first code
00114160:  240A0000  addiu   t2, zero, 0x0                    ; t2 = 0 lines counted
00114164:  240D1000  addiu   t5, zero, 0x1000                 ; t5 = 0x1000 (END)
00114168:  240E2000  addiu   t6, zero, 0x2000                 ; t6 = 0x2000 (LINE)
count_loop:
0011416C:  952B0000  lhu     t3, 0x0(t1)                      ; t3 = the next u16 code
00114170:  316CF000  andi    t4, t3, 0xf000                   ; t4 = its top nibble
00114174:  118D0005  beq     t4, t5, counted                  ; END: stop counting
00114178:  25290002  addiu   t1, t1, 0x2                      ; (delay, both ways) t1 += 2
0011417C:  158EFFFB  bne     t4, t6, count_loop               ; not a LINE code: next code
00114180:  00000000  nop                                      ; (delay)
00114184:  1000FFF9  beq     zero, zero, count_loop           ; a LINE code: loop again (b, always taken) ...
00114188:  254A0001  addiu   t2, t2, 0x1                      ; (delay) ... with t2 += 1
counted:
0011418C:  294C0003  slti    t4, t2, 0x3                      ; t4 = (lines < 3)
00114190:  15800004  bne     t4, zero, out                    ; one or two lines: leave the object alone
00114194:  00000000  nop                                      ; (delay)
00114198:  860C0002  lh      t4, 0x2(s0)                      ; t4 = the object's y (s16 at +0x02)
0011419C:  258CFFF3  addiu   t4, t4, -0xd                     ; t4 = y - 13
001141A0:  A60C0002  sh      t4, 0x2(s0)                      ; the object's y moved up 13 rows
out:
001141A4:  03E00008  jr      ra                               ; return to the script command
001141A8:  00000000  nop                                      ; (delay)

; end of listing
