; hit_box.s -- The King of Fighters XI (PS2, SLPS-25660 v1.03): the collision-box display (HIT BOX)
;
; What it does
;   In PRACTICE mode, draws every live collision box of every object on top of the fight, each
;   outlined 2 px wide in the colour of its type, plus a white cross on each drawn object's origin.
;   It is switched by HIT BOX, a fourth function of the PRACTICE menu's SELECT BUTTON setting:
;   with SELECT BUTTON set to HIT BOX, pressing SELECT toggles the boxes on and off.
;   It draws only when all of these hold: game mode [0x9E9780] == 8 (training), the pause flag
;   [0x9E9738] == 0 (no menu open), SELECT BUTTON code [0x9CB24A] == 3 (HIT BOX), and the
;   on/off byte (flag, below) is set.
;
; Where it is called from
;   * 0x1A1A6C: the main loop's last draw call, jal 0x1A7D60 (a frame-buffer copy that runs only
;     when the option byte [0x9CB282] is set; its a0 is set in the delay slot). It now calls
;     box_drawer, which draws after everything else of the frame has been sent and then jumps on
;     to 0x1A7D60 with a0 and ra as they were.
;   * 0x33B41C: the SELECT handler's exit for SELECT BUTTON codes other than 0..2 (originally
;     b 0x33B4C0). It now jumps to select_stub, which toggles the on/off byte for code 3 and
;     continues at 0x33B4C0.
;
;     address   original  new       purpose
;     001A1A6C  0C069F58  0C045070  the main loop's last call goes through the box drawer, which then jumps on to 0x1A7D60
;     0033B41C  10000028  08045142  PRACTICE's SELECT BUTTON handler, exit for codes other than 0..2: through the select stub
;
;   Two data patches go with it (not in this listing): the SELECT BUTTON name of code 3 at
;   0x3D2E0C, "COMMAND" -> "HIT BOX" (code 3 is an option the original menu never offers), and
;   the list lengths at 0x3D2F20 for ACTION 0..10, each + 1, so code 3 is offered after the others.
;
; Where it lives
;   0x1141C0..0x1147B0 (380 words: 232 of code, then data), over unreferenced library functions
;   (dead code) of the original executable.
;
; Game data it reads
;   0x9B6BC0  the frame's object work list: u32 pointers, filled from index 0 each frame; the
;             count at 0x9B6DC0 is back to 0 when the drawer runs but the entries stay. Entries
;             0..5 are the fighters. The drawer walks it to the first null entry (128 at most),
;             then zeroes the entries it walked, so a stale entry left past the game's count is
;             never drawn on a later frame.
;   0x9BDB20  camera x, 0x9BDB22 camera y (s16).
;   An object (pointer kept only when inside 0x900000..0x9AFFFF):
;     +0x000 s16 x, +0x002 s16 y  the origin the box offsets are measured from
;     +0x08A, +0x08B  u8: slot 5 is live when ([+0x8A] & [+0x8B] & 0x20)
;     +0x08C  u8 flags: bit 1 = x direction, bit 0 = y direction (0 = offset negated),
;             bit 2 = skip (set on the benched team members)
;     +0x090, +0x094  float x scale, y scale
;     +0x0EA  u16 the character (for the id remap)
;     +0x314  seven box slots of 10 bytes: s16 x, s16 y (offsets from the origin), u8 id at +4,
;             u8 half-width at +7, u8 half-height at +8
;     +0x39E, +0x39F  u8 masks: slots 0..4 live where ([+0x39E] & [+0x39F]) has the bit
;   Slots 0..3 are coloured by the box id's type (the kinds table below, built from the game's
;   own id -> class table at 0x365BC0); an id 0x70..0x7F is first remapped through the
;   character's table as the game's handler 0x194D80 does. Slots 4 and 5 are throw boxes, slot 6
;   the body box; slot 6 is drawn for work-list entries 0..5 without the skip bit.
;
; The box on screen
;   centre x = X + (flags & 2 ? x : -x) * xscale,   half width  = w * xscale
;   centre y = Y + (flags & 1 ? y : -y) * yscale,   half height = h * yscale
;   (products truncated to integers). Screen pixel = position - camera, with 24 rows subtracted
;   from y. The GS offset is (1728, 1824), so a pixel (x, y) is sent as X = (1728 + x) * 16,
;   Y = (1824 + y) * 16. The packet sets only PRIM (in its GIF tag); the rest of the GS state
;   (alpha, depth test always, scissor 640 x 448) is what the game left set for the frame.
;
; Listing format: address:  word (little-endian u32 as stored)  instruction  ; comment

; --------------------------------------------------------------------------------------------------
; box_drawer: entry, saves, and the four conditions
;
; Called in place of jal 0x1A7D60; a0 holds that routine's argument and must survive.
; Stack frame 0xA0: ra at 0, a0 at 8, s0..s7 as 128-bit quadwords at 0x10..0x80, and 0x90 is
; where rect keeps its own ra. Any failed condition goes straight to done.
; --------------------------------------------------------------------------------------------------
box_drawer:
001141C0:  27BDFF60  addiu   sp, sp, -0xa0                    ; frame of 0xA0 bytes
001141C4:  FFBF0000  sd      ra, 0x0(sp)                      ; save ra
001141C8:  FFA40008  sd      a0, 0x8(sp)                      ; save a0 (0x1A7D60's argument)
001141CC:  7FB00010  sq      s0, 0x10(sp)                     ; save s0 (full 128-bit register)
001141D0:  7FB10020  sq      s1, 0x20(sp)                     ; save s1
001141D4:  7FB20030  sq      s2, 0x30(sp)                     ; save s2
001141D8:  7FB30040  sq      s3, 0x40(sp)                     ; save s3
001141DC:  7FB40050  sq      s4, 0x50(sp)                     ; save s4
001141E0:  7FB50060  sq      s5, 0x60(sp)                     ; save s5
001141E4:  7FB60070  sq      s6, 0x70(sp)                     ; save s6
001141E8:  7FB70080  sq      s7, 0x80(sp)                     ; save s7
001141EC:  3C08009F  lui     t0, 0x9f                         ; t0 = 0x9F0000
001141F0:  91099780  lbu     t1, -0x6880(t0)                  ; t1 = [0x9E9780], the game mode
001141F4:  910A9738  lbu     t2, -0x68c8(t0)                  ; t2 = [0x9E9738], the pause flag
001141F8:  240B0008  addiu   t3, zero, 0x8                    ; t3 = 8 (training)
001141FC:  152B008D  bne     t1, t3, done                     ; not training: done
00114200:  3C08009D  lui     t0, 0x9d                         ; (delay) t0 = 0x9D0000
00114204:  1540008B  bne     t2, zero, done                   ; paused (a menu open): done
00114208:  9109B24A  lbu     t1, -0x4db6(t0)                  ; (delay) t1 = [0x9CB24A], the SELECT BUTTON code
0011420C:  240B0003  addiu   t3, zero, 0x3                    ; t3 = 3 (HIT BOX)
00114210:  152B0088  bne     t1, t3, done                     ; SELECT BUTTON is not HIT BOX: done
00114214:  3C080011  lui     t0, 0x11                         ; (delay) t0 = 0x110000
00114218:  91094628  lbu     t1, 0x4628(t0)                   ; t1 = [flag], the on/off byte
0011421C:  11200085  beq     t1, zero, done                   ; off: done
00114220:  3C08009C  lui     t0, 0x9c                         ; (delay) t0 = 0x9C0000

; --------------------------------------------------------------------------------------------------
; setup
;
; s6 = camera x, s7 = camera y, s0 = current work-list entry, s1 = end of the list
; (0x9B6BC0 + 128 * 4), s3 = the DMA chain, s2 = the current object pointer
; --------------------------------------------------------------------------------------------------
00114224:  8516DB20  lh      s6, -0x24e0(t0)                  ; s6 = [0x9BDB20], camera x
00114228:  8517DB22  lh      s7, -0x24de(t0)                  ; s7 = [0x9BDB22], camera y
0011422C:  3C10009B  lui     s0, 0x9b                         ; s0 = 0x9B0000 ...
00114230:  26106BC0  addiu   s0, s0, 0x6bc0                   ; ... + 0x6BC0 = 0x9B6BC0, the work list
00114234:  26110200  addiu   s1, s0, 0x200                    ; s1 = 0x9B6DC0, 128 entries on
00114238:  3C130011  lui     s3, 0x11                         ; s3 = 0x110000 ...
0011423C:  26734560  addiu   s3, s3, 0x4560                   ; ... + 0x4560 = chain
00114240:  8E120000  lw      s2, 0x0(s0)                      ; s2 = the first entry

; --------------------------------------------------------------------------------------------------
; obj_loop: one work-list entry
;
; Stops at a null entry; skips pointers outside 0x900000..0x9AFFFF and objects with no slot to draw.
; Builds s4 = the mask of slots to draw, bit k = slot k:
;   bits 0..4  [+0x39E] & [+0x39F] & 0x1F
;   bit 5      [+0x8A] & [+0x8B] & 0x20                 (slot 5, as the game tests it)
;   bit 6      entry index < 6 and not ([+0x8C] & 4)    (slot 6, the body box)
; s5 = the first slot (+0x314).
; --------------------------------------------------------------------------------------------------
obj_loop:
00114244:  12400074  beq     s2, zero, clear                  ; a null entry: the walk is over
00114248:  3C080090  lui     t0, 0x90                         ; (delay) t0 = 0x900000
0011424C:  0248482B  sltu    t1, s2, t0                       ; t1 = (object < 0x900000)
00114250:  1520006E  bne     t1, zero, next_obj               ; below 0x900000: skip it
00114254:  3C08009B  lui     t0, 0x9b                         ; (delay) t0 = 0x9B0000
00114258:  0248482B  sltu    t1, s2, t0                       ; t1 = (object < 0x9B0000)
0011425C:  1120006B  beq     t1, zero, next_obj               ; at or above 0x9B0000: skip it
00114260:  9248039E  lbu     t0, 0x39e(s2)                    ; (delay) t0 = [+0x39E]
00114264:  9249039F  lbu     t1, 0x39f(s2)                    ; t1 = [+0x39F]
00114268:  0109A024  and     s4, t0, t1                       ; s4 = the live slots ...
0011426C:  3294001F  andi    s4, s4, 0x1f                     ; ... 0..4
00114270:  9248008A  lbu     t0, 0x8a(s2)                     ; t0 = [+0x8A]
00114274:  9249008B  lbu     t1, 0x8b(s2)                     ; t1 = [+0x8B]
00114278:  01094024  and     t0, t0, t1                       ; t0 = [+0x8A] & [+0x8B]
0011427C:  31080020  andi    t0, t0, 0x20                     ; t0 = bit 5: slot 5 live
00114280:  0288A025  or      s4, s4, t0                       ; s4 |= slot 5
00114284:  3C08009B  lui     t0, 0x9b                         ; t0 = 0x9B0000 ...
00114288:  25086BD8  addiu   t0, t0, 0x6bd8                   ; ... + 0x6BD8 = entry 6 of the work list
0011428C:  0208482B  sltu    t1, s0, t0                       ; t1 = (this entry is 0..5: a fighter)
00114290:  924A008C  lbu     t2, 0x8c(s2)                     ; t2 = [+0x8C], the flags
00114294:  000A5082  srl     t2, t2, 2                        ; t2 >>= 2
00114298:  314A0001  andi    t2, t2, 0x1                      ; t2 = the skip bit
0011429C:  394A0001  xori    t2, t2, 0x1                      ; t2 = not skipped
001142A0:  012A4824  and     t1, t1, t2                       ; t1 = a fighter and not skipped
001142A4:  00094980  sll     t1, t1, 6                        ; t1 = bit 6
001142A8:  0289A025  or      s4, s4, t1                       ; s4 |= slot 6
001142AC:  12800057  beq     s4, zero, next_obj               ; no slot to draw: next object (no axis either)
001142B0:  26550314  addiu   s5, s2, 0x314                    ; (delay) s5 = &slot 0 (+0x314)

; --------------------------------------------------------------------------------------------------
; slot_loop: one slot (s5) while s4 has bits left; bit 0 of s4 is the current slot
;
; Picks the kind (1..8) and leaves t0 = kind * 16, the offset of its colour from colours - 16:
;   slots 4, 5 (s5 < +0x350): throw (7);  slot 6: body (8);  slots 0..3: by id (kind_by_id).
; --------------------------------------------------------------------------------------------------
slot_loop:
001142B4:  32880001  andi    t0, s4, 0x1                      ; t0 = this slot is live
001142B8:  1100003C  beq     t0, zero, next_slot              ; not live: next slot
001142BC:  2649033C  addiu   t1, s2, 0x33c                    ; (delay) t1 = &slot 4 (+0x33C)
001142C0:  02A9502B  sltu    t2, s5, t1                       ; t2 = (slot < 4)
001142C4:  15400006  bne     t2, zero, kind_by_id             ; slots 0..3: the kind comes from the id
001142C8:  26490350  addiu   t1, s2, 0x350                    ; (delay) t1 = &slot 6 (+0x350)
001142CC:  02A9502B  sltu    t2, s5, t1                       ; t2 = (slot < 6): slots 4, 5
001142D0:  24080008  addiu   t0, zero, 0x8                    ; t0 = 8 (body)
001142D4:  010A4023  subu    t0, t0, t2                       ; t0 = 8 - t2: 7 (throw) for slots 4, 5; 8 (body) for slot 6
001142D8:  10000009  beq     zero, zero, have_kind            ; b have_kind (always taken)
001142DC:  00084100  sll     t0, t0, 4                        ; (delay) t0 = kind * 16
kind_by_id:
001142E0:  0C04514A  jal     remap                            ; t0 = the id, remapped when 0x70..0x7F
001142E4:  92A80004  lbu     t0, 0x4(s5)                      ; (delay) t0 = the id, u8 at +4 of the slot
001142E8:  3C090011  lui     t1, 0x11                         ; t1 = 0x110000 ...
001142EC:  252946B0  addiu   t1, t1, 0x46b0                   ; ... + 0x46B0 = kinds
001142F0:  01284821  addu    t1, t1, t0                       ; t1 = &kinds[id]
001142F4:  91280000  lbu     t0, 0x0(t1)                      ; t0 = the kind (0 = not drawn)
001142F8:  1100002C  beq     t0, zero, next_slot              ; kind 0: next slot
001142FC:  00084100  sll     t0, t0, 4                        ; (delay) t0 = kind * 16

; --------------------------------------------------------------------------------------------------
; have_kind: colour, transform, outline
;
; Sets the chain's colour qword, computes the box in GS units and calls rect.
; t3 = centre dx then centre X, t4 = half width, t5 = centre dy then centre Y, t6 = half height.
; scale takes t0 (int) and f2 (float) and returns v0 = (int)(t0 * f2); its jal delay slots load the
; next t0 or f2.
; --------------------------------------------------------------------------------------------------
have_kind:
00114300:  3C090011  lui     t1, 0x11                         ; t1 = 0x110000 ...
00114304:  25294620  addiu   t1, t1, 0x4620                   ; ... + 0x4620 = colours - 16 (kind 1 is the first qword)
00114308:  01284821  addu    t1, t1, t0                       ; t1 = &colour[kind]
0011430C:  792A0000  lq      t2, 0x0(t1)                      ; t2 = the RGBA qword
00114310:  7E6A0020  sq      t2, 0x20(s3)                     ; into the chain's RGBAQ data (chain + 0x20)
00114314:  9249008C  lbu     t1, 0x8c(s2)                     ; t1 = [+0x8C], the direction flags
00114318:  86A80000  lh      t0, 0x0(s5)                      ; t0 = the slot's x offset (s16)
0011431C:  312A0002  andi    t2, t1, 0x2                      ; t2 = flags & 2
00114320:  51400001  beql    t2, zero, xs                     ; bit clear: negate x (the delay slot runs only then)
00114324:  00084023  subu    t0, zero, t0                     ; (delay, likely) t0 = -t0
xs:
00114328:  0C04513B  jal     scale                            ; v0 = (int)(t0 * xscale)
0011432C:  C6420090  lwc1    $f2, 0x90(s2)                    ; (delay) f2 = [+0x90], x scale
00114330:  0040582D  daddu   t3, v0, zero                     ; t3 = centre dx
00114334:  0C04513B  jal     scale                            ; v0 = (int)(w * xscale)
00114338:  92A80007  lbu     t0, 0x7(s5)                      ; (delay) t0 = half width, u8 at +7 of the slot
0011433C:  0040602D  daddu   t4, v0, zero                     ; t4 = half width
00114340:  86A80002  lh      t0, 0x2(s5)                      ; t0 = the slot's y offset (s16)
00114344:  312A0001  andi    t2, t1, 0x1                      ; t2 = flags & 1
00114348:  51400001  beql    t2, zero, ys                     ; bit clear: negate y (the delay slot runs only then)
0011434C:  00084023  subu    t0, zero, t0                     ; (delay, likely) t0 = -t0
ys:
00114350:  0C04513B  jal     scale                            ; v0 = (int)(t0 * yscale)
00114354:  C6420094  lwc1    $f2, 0x94(s2)                    ; (delay) f2 = [+0x94], y scale
00114358:  0040682D  daddu   t5, v0, zero                     ; t5 = centre dy
0011435C:  0C04513B  jal     scale                            ; v0 = (int)(h * yscale)
00114360:  92A80008  lbu     t0, 0x8(s5)                      ; (delay) t0 = half height, u8 at +8 of the slot
00114364:  0040702D  daddu   t6, v0, zero                     ; t6 = half height
00114368:  86480000  lh      t0, 0x0(s2)                      ; t0 = the object's x
0011436C:  01685821  addu    t3, t3, t0                       ; t3 = x + dx
00114370:  01765823  subu    t3, t3, s6                       ; t3 -= camera x
00114374:  256B06C0  addiu   t3, t3, 0x6c0                    ; t3 += 1728: the centre in GS pixels
00114378:  86480002  lh      t0, 0x2(s2)                      ; t0 = the object's y
0011437C:  01A86821  addu    t5, t5, t0                       ; t5 = y + dy
00114380:  01B76823  subu    t5, t5, s7                       ; t5 -= camera y
00114384:  25AD0708  addiu   t5, t5, 0x708                    ; t5 += 1824 - 24 = 1800: the centre in GS pixels
00114388:  016C4023  subu    t0, t3, t4                       ; t0 = centre - half width ...
0011438C:  00084100  sll     t0, t0, 4                        ; ... * 16: x0
00114390:  016C4821  addu    t1, t3, t4                       ; t1 = centre + half width ...
00114394:  00094900  sll     t1, t1, 4                        ; ... * 16: x1
00114398:  01AE5023  subu    t2, t5, t6                       ; t2 = centre - half height ...
0011439C:  000A5100  sll     t2, t2, 4                        ; ... * 16: y0
001143A0:  01AE7821  addu    t7, t5, t6                       ; t7 = centre + half height
001143A4:  0C045119  jal     rect                             ; outline the box
001143A8:  000F7900  sll     t7, t7, 4                        ; (delay) t7 * 16: y1
next_slot:
001143AC:  0014A042  srl     s4, s4, 1                        ; s4 >>= 1: the next slot's bit
001143B0:  1680FFC0  bne     s4, zero, slot_loop              ; more slots: loop
001143B4:  26B5000A  addiu   s5, s5, 0xa                      ; (delay) s5 += 10, the next slot

; --------------------------------------------------------------------------------------------------
; axis: a white cross on the object's origin
;
; Two bars 2 px thick, each arm 8 px from the origin, through the same transform
; (s4 = origin X * 16, s5 = origin Y * 16 in GS units). Drawn for every object that had a
; slot to draw.
; --------------------------------------------------------------------------------------------------
axis:
001143B8:  3C090011  lui     t1, 0x11                         ; t1 = 0x110000
001143BC:  792A4680  lq      t2, 0x4680(t1)                   ; t2 = [axis_colour], white
001143C0:  7E6A0020  sq      t2, 0x20(s3)                     ; into the chain's RGBAQ data
001143C4:  86480000  lh      t0, 0x0(s2)                      ; t0 = the object's x
001143C8:  01164023  subu    t0, t0, s6                       ; - camera x
001143CC:  250806C0  addiu   t0, t0, 0x6c0                    ; + 1728
001143D0:  0008A100  sll     s4, t0, 4                        ; s4 = origin X (GS units)
001143D4:  86480002  lh      t0, 0x2(s2)                      ; t0 = the object's y
001143D8:  01174023  subu    t0, t0, s7                       ; - camera y
001143DC:  25080708  addiu   t0, t0, 0x708                    ; + 1800
001143E0:  0008A900  sll     s5, t0, 4                        ; s5 = origin Y (GS units)
001143E4:  2688FF80  addiu   t0, s4, -0x80                    ; t0 = X - 8 px
001143E8:  26890080  addiu   t1, s4, 0x80                     ; t1 = X + 8 px
001143EC:  26AAFFF0  addiu   t2, s5, -0x10                    ; t2 = Y - 1 px
001143F0:  0C045119  jal     rect                             ; the horizontal bar
001143F4:  26AF0010  addiu   t7, s5, 0x10                     ; (delay) t7 = Y + 1 px
001143F8:  2688FFF0  addiu   t0, s4, -0x10                    ; t0 = X - 1 px
001143FC:  26890010  addiu   t1, s4, 0x10                     ; t1 = X + 1 px
00114400:  26AAFF80  addiu   t2, s5, -0x80                    ; t2 = Y - 8 px
00114404:  0C045119  jal     rect                             ; the vertical bar
00114408:  26AF0080  addiu   t7, s5, 0x80                     ; (delay) t7 = Y + 8 px

; --------------------------------------------------------------------------------------------------
; next_obj, clear, done
;
; clear: zeroes the work-list entries from 0x9B6BC0 up to the first null one (or all 128),
; so next frame the walk ends where the game's own refill ends.
; done: restores everything and jumps to 0x1A7D60, the call this routine replaced, with the
; caller's ra and a0; sp is restored in the delay slot.
; --------------------------------------------------------------------------------------------------
next_obj:
0011440C:  26100004  addiu   s0, s0, 0x4                      ; s0 += 4, the next entry
00114410:  1611FF8C  bne     s0, s1, obj_loop                 ; not at the end: loop
00114414:  8E120000  lw      s2, 0x0(s0)                      ; (delay) s2 = the next entry (at the end it reads the count word; unused)
clear:
00114418:  3C08009B  lui     t0, 0x9b                         ; t0 = 0x9B0000 ...
0011441C:  25086BC0  addiu   t0, t0, 0x6bc0                   ; ... + 0x6BC0 = the work list
clear_entry:
00114420:  8D0A0000  lw      t2, 0x0(t0)                      ; t2 = the entry
00114424:  11400003  beq     t2, zero, done                   ; null: done
00114428:  25080004  addiu   t0, t0, 0x4                      ; (delay) t0 += 4
0011442C:  1511FFFC  bne     t0, s1, clear_entry              ; not at the end: next entry ...
00114430:  AD00FFFC  sw      zero, -0x4(t0)                   ; (delay) ... and this entry = 0
done:
00114434:  7BB00010  lq      s0, 0x10(sp)                     ; restore s0
00114438:  7BB10020  lq      s1, 0x20(sp)                     ; restore s1
0011443C:  7BB20030  lq      s2, 0x30(sp)                     ; restore s2
00114440:  7BB30040  lq      s3, 0x40(sp)                     ; restore s3
00114444:  7BB40050  lq      s4, 0x50(sp)                     ; restore s4
00114448:  7BB50060  lq      s5, 0x60(sp)                     ; restore s5
0011444C:  7BB60070  lq      s6, 0x70(sp)                     ; restore s6
00114450:  7BB70080  lq      s7, 0x80(sp)                     ; restore s7
00114454:  DFA40008  ld      a0, 0x8(sp)                      ; restore a0
00114458:  DFBF0000  ld      ra, 0x0(sp)                      ; restore ra
0011445C:  08069F58  j       0x1a7d60                         ; on to the original call, 0x1A7D60
00114460:  27BD00A0  addiu   sp, sp, 0xa0                     ; (delay) free the frame

; --------------------------------------------------------------------------------------------------
; rect: one outline, 2 px wide, sent to the GS
;
; In: t0 = x0, t1 = x1, t2 = y0, t7 = y1 (GS units, pixel * 16), s3 = chain, colour already set.
; Writes 4 sprites (8 XYZ2 vertices, X in the low word, Y in the next word of each qword):
;   top (x0, y0)-(x1, y0+2)   bottom (x0, y1-2)-(x1, y1)   left (x0, y0)-(x0+2, y1)
;   right (x1-2, y0)-(x1, y1)
; then FlushCache(0) (0x10CEE0), sends the chain with 0x102810([0x9BE688], chain) and waits
; for the GIF DMA channel: CHCR 0x1000A000 bit 8 back to 0. Keeps its ra at 0x90(sp) of the
; drawer's frame.
; --------------------------------------------------------------------------------------------------
rect:
00114464:  FFBF0090  sd      ra, 0x90(sp)                     ; save ra in the drawer's frame
00114468:  25580020  addiu   t8, t2, 0x20                     ; t8 = y0 + 2 px
0011446C:  25F9FFE0  addiu   t9, t7, -0x20                    ; t9 = y1 - 2 px
00114470:  25050020  addiu   a1, t0, 0x20                     ; a1 = x0 + 2 px
00114474:  2526FFE0  addiu   a2, t1, -0x20                    ; a2 = x1 - 2 px
00114478:  AE680040  sw      t0, 0x40(s3)                     ; top: (x0,
0011447C:  AE6A0044  sw      t2, 0x44(s3)                     ;   y0)
00114480:  AE690050  sw      t1, 0x50(s3)                     ;   - (x1,
00114484:  AE780054  sw      t8, 0x54(s3)                     ;   y0 + 2)
00114488:  AE680060  sw      t0, 0x60(s3)                     ; bottom: (x0,
0011448C:  AE790064  sw      t9, 0x64(s3)                     ;   y1 - 2)
00114490:  AE690070  sw      t1, 0x70(s3)                     ;   - (x1,
00114494:  AE6F0074  sw      t7, 0x74(s3)                     ;   y1)
00114498:  AE680080  sw      t0, 0x80(s3)                     ; left: (x0,
0011449C:  AE6A0084  sw      t2, 0x84(s3)                     ;   y0)
001144A0:  AE650090  sw      a1, 0x90(s3)                     ;   - (x0 + 2,
001144A4:  AE6F0094  sw      t7, 0x94(s3)                     ;   y1)
001144A8:  AE6600A0  sw      a2, 0xa0(s3)                     ; right: (x1 - 2,
001144AC:  AE6A00A4  sw      t2, 0xa4(s3)                     ;   y0)
001144B0:  AE6900B0  sw      t1, 0xb0(s3)                     ;   - (x1,
001144B4:  AE6F00B4  sw      t7, 0xb4(s3)                     ;   y1)
001144B8:  0C0433B8  jal     0x10cee0                         ; FlushCache(0): the chain out of the data cache
001144BC:  0000202D  daddu   a0, zero, zero                   ; (delay) a0 = 0
001144C0:  3C08009C  lui     t0, 0x9c                         ; t0 = 0x9C0000
001144C4:  8D04E688  lw      a0, -0x1978(t0)                  ; a0 = [0x9BE688], the GIF DMA channel
001144C8:  0C040A04  jal     0x102810                         ; send the chain
001144CC:  0260282D  daddu   a1, s3, zero                     ; (delay) a1 = the chain
001144D0:  3C031001  lui     v1, 0x1001                       ; v1 = 0x10010000
rect_wait:
001144D4:  8C62A000  lw      v0, -0x6000(v1)                  ; v0 = [0x1000A000], GIF channel CHCR
001144D8:  30420100  andi    v0, v0, 0x100                    ; v0 = bit 8 (STR, transfer running)
001144DC:  1440FFFD  bne     v0, zero, rect_wait              ; still running: wait
001144E0:  DFBF0090  ld      ra, 0x90(sp)                     ; (delay) ra back
001144E4:  03E00008  jr      ra                               ; return
001144E8:  00000000  nop                                      ; (delay)

; --------------------------------------------------------------------------------------------------
; scale: v0 = (int)((float)t0 * f2), truncated by cvt.w.s; uses f0 only
; --------------------------------------------------------------------------------------------------
scale:
001144EC:  44880000  mtc1    t0, $f0                          ; f0 = t0
001144F0:  46800020  cvt.s.w $f0, $f0                         ; f0 = (float)f0
001144F4:  46020002  mul.s   $f0, $f0, $f2                    ; f0 *= f2
001144F8:  46000024  cvt.w.s $f0, $f0                         ; f0 = (int)f0
001144FC:  44020000  mfc1    v0, $f0                          ; v0 = f0
00114500:  03E00008  jr      ra                               ; return
00114504:  00000000  nop                                      ; (delay)

; --------------------------------------------------------------------------------------------------
; select_stub: the SELECT handler's exit for codes other than 0..2
;
; Reached by j from 0x33B41C. a1 = [0x9CB24A], the SELECT BUTTON code, loaded by the handler at
; 0x33B3FC. For code 3 (HIT BOX) it flips the on/off byte; then on to 0x33B4C0, where the
; original branch went.
; --------------------------------------------------------------------------------------------------
select_stub:
00114508:  24080003  addiu   t0, zero, 0x3                    ; t0 = 3 (HIT BOX)
0011450C:  14A80004  bne     a1, t0, select_out               ; another code: just leave
00114510:  3C080011  lui     t0, 0x11                         ; (delay) t0 = 0x110000
00114514:  91094628  lbu     t1, 0x4628(t0)                   ; t1 = [flag]
00114518:  39290001  xori    t1, t1, 0x1                      ; t1 ^= 1
0011451C:  A1094628  sb      t1, 0x4628(t0)                   ; [flag] = t1: boxes on / off
select_out:
00114520:  080CED30  j       0x33b4c0                         ; the handler's original exit
00114524:  00000000  nop                                      ; (delay)

; --------------------------------------------------------------------------------------------------
; remap: a box id 0x70..0x7F through the character's own table
;
; In: t0 = id, s2 = the object. Out: t0 = the id to classify. Other ids are returned as they are.
; For 0x70..0x7F: a0 = [+0xEA] (the character), v0 = 0x18D800(a0, 2) = the character's remap
; table (a leaf routine that uses only v0, v1, a0, a1), id = table[id - 0x70] + 0x80 (as a byte,
; the same as XOR 0x80), as the game's own handler 0x194D80 resolves it. ra is kept in t3 across
; the call.
; --------------------------------------------------------------------------------------------------
remap:
00114528:  2509FF90  addiu   t1, t0, -0x70                    ; t1 = id - 0x70
0011452C:  2D2A0010  sltiu   t2, t1, 0x10                     ; t2 = (t1 < 0x10): id in 0x70..0x7F
00114530:  15400003  bne     t2, zero, remap_do               ; yes: remap it
00114534:  03E0582D  daddu   t3, ra, zero                     ; (delay, both ways) t3 = ra
00114538:  03E00008  jr      ra                               ; no: return the id as it is
0011453C:  00000000  nop                                      ; (delay)
remap_do:
00114540:  964400EA  lhu     a0, 0xea(s2)                     ; a0 = [+0xEA], the character
00114544:  0C063600  jal     0x18d800                         ; v0 = the character's remap table
00114548:  24050002  addiu   a1, zero, 0x2                    ; (delay) a1 = 2
0011454C:  00491021  addu    v0, v0, t1                       ; v0 = &table[id - 0x70]
00114550:  90480000  lbu     t0, 0x0(v0)                      ; t0 = the byte
00114554:  39080080  xori    t0, t0, 0x80                     ; t0 = byte + 0x80 (mod 256)
00114558:  01600008  jr      t3                               ; return through the saved ra
0011455C:  00000000  nop                                      ; (delay)

; --------------------------------------------------------------------------------------------------
; chain: the DMA chain sent for each outline (13 quadwords)
;
; A CNT tag with 11 quadwords of GIF data, then an END tag. The GIF data:
;   GIF tag A: NLOOP 1, PRE 1, PRIM = 6 (SPRITE, no other flags), 1 register: RGBAQ
;   the colour qword (written by the drawer: R, G, B, A as four u32)
;   GIF tag B: NLOOP 8, EOP, 1 register: XYZ2
;   8 vertex qwords (written by rect)
; The upper half of the END tag's quadword is unused by the DMA and holds the on/off byte.
; --------------------------------------------------------------------------------------------------
chain:
00114560:  1000000B  .word   0x1000000B                       ; DMA tag: CNT (id 1), QWC = 11
00114564:  00000000  .word   0x00000000                       ;   (tag address, unused)
00114568:  00000000  .word   0x00000000                       ;   (unused)
0011456C:  00000000  .word   0x00000000                       ;   (unused)
00114570:  00000001  .word   0x00000001                       ; GIF tag A: NLOOP = 1, EOP = 0
00114574:  10034000  .word   0x10034000                       ;   PRE = 1, PRIM = 6 (SPRITE), NREG = 1
00114578:  00000001  .word   0x00000001                       ;   REGS: 0x1 = RGBAQ
0011457C:  00000000  .word   0x00000000                       ;   (REGS, upper)
00114580:  00000000  .word   0x00000000                       ; colour: R (set by the drawer)
00114584:  00000000  .word   0x00000000                       ; colour: G (set by the drawer)
00114588:  00000000  .word   0x00000000                       ; colour: B (set by the drawer)
0011458C:  00000000  .word   0x00000000                       ; colour: A (set by the drawer)
00114590:  00008008  .word   0x00008008                       ; GIF tag B: NLOOP = 8, EOP = 1
00114594:  10000000  .word   0x10000000                       ;   NREG = 1
00114598:  00000005  .word   0x00000005                       ;   REGS: 0x5 = XYZ2
0011459C:  00000000  .word   0x00000000                       ;   (REGS, upper)
001145A0:  00000000  .word   0x00000000                       ; vertex 0: X (set by rect)
001145A4:  00000000  .word   0x00000000                       ;   Y (set by rect)
001145A8:  00000000  .word   0x00000000                       ;   Z = 0
001145AC:  00000000  .word   0x00000000                       ;   (unused)
001145B0:  00000000  .word   0x00000000                       ; vertex 1: X (set by rect)
001145B4:  00000000  .word   0x00000000                       ;   Y (set by rect)
001145B8:  00000000  .word   0x00000000                       ;   Z = 0
001145BC:  00000000  .word   0x00000000                       ;   (unused)
001145C0:  00000000  .word   0x00000000                       ; vertex 2: X (set by rect)
001145C4:  00000000  .word   0x00000000                       ;   Y (set by rect)
001145C8:  00000000  .word   0x00000000                       ;   Z = 0
001145CC:  00000000  .word   0x00000000                       ;   (unused)
001145D0:  00000000  .word   0x00000000                       ; vertex 3: X (set by rect)
001145D4:  00000000  .word   0x00000000                       ;   Y (set by rect)
001145D8:  00000000  .word   0x00000000                       ;   Z = 0
001145DC:  00000000  .word   0x00000000                       ;   (unused)
001145E0:  00000000  .word   0x00000000                       ; vertex 4: X (set by rect)
001145E4:  00000000  .word   0x00000000                       ;   Y (set by rect)
001145E8:  00000000  .word   0x00000000                       ;   Z = 0
001145EC:  00000000  .word   0x00000000                       ;   (unused)
001145F0:  00000000  .word   0x00000000                       ; vertex 5: X (set by rect)
001145F4:  00000000  .word   0x00000000                       ;   Y (set by rect)
001145F8:  00000000  .word   0x00000000                       ;   Z = 0
001145FC:  00000000  .word   0x00000000                       ;   (unused)
00114600:  00000000  .word   0x00000000                       ; vertex 6: X (set by rect)
00114604:  00000000  .word   0x00000000                       ;   Y (set by rect)
00114608:  00000000  .word   0x00000000                       ;   Z = 0
0011460C:  00000000  .word   0x00000000                       ;   (unused)
00114610:  00000000  .word   0x00000000                       ; vertex 7: X (set by rect)
00114614:  00000000  .word   0x00000000                       ;   Y (set by rect)
00114618:  00000000  .word   0x00000000                       ;   Z = 0
0011461C:  00000000  .word   0x00000000                       ;   (unused)
00114620:  70000000  .word   0x70000000                       ; DMA tag: END (id 7), QWC = 0
00114624:  00000000  .word   0x00000000                       ;   (tag address, unused)
flag:
00114628:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; flag: byte 0 = HIT BOX on (1) / off (0), toggled by SELECT
0011462C:  00000000  .word   0x00000000                       ;   (unused)

; --------------------------------------------------------------------------------------------------
; colours: one RGBA qword per kind 1..8 (R, G, B as u32 0..255, A = 0x80)
;
; The drawer indexes this from one qword before its start, so kind 1 is the first qword.
; --------------------------------------------------------------------------------------------------
colours:
00114630:  000000FF  .word   0x000000FF                       ; kind 1: attack (hit) box, R = 255
00114634:  00000044  .word   0x00000044                       ;   G = 68
00114638:  00000044  .word   0x00000044                       ;   B = 68
0011463C:  00000080  .word   0x00000080                       ;   A = 0x80
00114640:  00000044  .word   0x00000044                       ; kind 2: hurt box, R = 68
00114644:  00000088  .word   0x00000088                       ;   G = 136
00114648:  000000FF  .word   0x000000FF                       ;   B = 255
0011464C:  00000080  .word   0x00000080                       ;   A = 0x80
00114650:  00000040  .word   0x00000040                       ; kind 3: conditional hurt box, R = 64
00114654:  000000CE  .word   0x000000CE                       ;   G = 206
00114658:  000000E0  .word   0x000000E0                       ;   B = 224
0011465C:  00000080  .word   0x00000080                       ;   A = 0x80
00114660:  000000CC  .word   0x000000CC                       ; kind 4: guard box, R = 204
00114664:  000000AA  .word   0x000000AA                       ;   G = 170
00114668:  00000000  .word   0x00000000                       ;   B = 0
0011466C:  00000080  .word   0x00000080                       ;   A = 0x80
00114670:  000000AA  .word   0x000000AA                       ; kind 5: projectile box, R = 170
00114674:  00000066  .word   0x00000066                       ;   G = 102
00114678:  000000CC  .word   0x000000CC                       ;   B = 204
0011467C:  00000080  .word   0x00000080                       ;   A = 0x80
axis_colour:
00114680:  000000FF  .word   0x000000FF                       ; kind 6: receiver box, R = 255
00114684:  000000FF  .word   0x000000FF                       ;   G = 255
00114688:  000000FF  .word   0x000000FF                       ;   B = 255   (white: also the axis cross colour)
0011468C:  00000080  .word   0x00000080                       ;   A = 0x80
00114690:  000000FF  .word   0x000000FF                       ; kind 7: throw box (slots 4, 5), R = 255
00114694:  00000000  .word   0x00000000                       ;   G = 0
00114698:  000000FF  .word   0x000000FF                       ;   B = 255
0011469C:  00000080  .word   0x00000080                       ;   A = 0x80
001146A0:  00000000  .word   0x00000000                       ; kind 8: body box (slot 6), R = 0
001146A4:  000000C8  .word   0x000000C8                       ;   G = 200
001146A8:  00000000  .word   0x00000000                       ;   B = 0
001146AC:  00000080  .word   0x00000080                       ;   A = 0x80

; --------------------------------------------------------------------------------------------------
; kinds: 256 bytes, box id -> kind (0 = not drawn, 1..8 as in colours)
;
; Built from the game's own id -> class table (0x365BC0): classes in no collision draw nothing.
; Used for slots 0..3, after remap.
; --------------------------------------------------------------------------------------------------
kinds:
001146B0:  02020200  .byte   0x00, 0x02, 0x02, 0x02           ; ids 0x00..0x03: none, vuln, vuln, vuln
001146B4:  02020202  .byte   0x02, 0x02, 0x02, 0x02           ; ids 0x04..0x07: vuln, vuln, vuln, vuln
001146B8:  02020202  .byte   0x02, 0x02, 0x02, 0x02           ; ids 0x08..0x0B: vuln, vuln, vuln, vuln
001146BC:  05020202  .byte   0x02, 0x02, 0x02, 0x05           ; ids 0x0C..0x0F: vuln, vuln, vuln, proj
001146C0:  05050505  .byte   0x05, 0x05, 0x05, 0x05           ; ids 0x10..0x13: proj, proj, proj, proj
001146C4:  05050505  .byte   0x05, 0x05, 0x05, 0x05           ; ids 0x14..0x17: proj, proj, proj, proj
001146C8:  05050505  .byte   0x05, 0x05, 0x05, 0x05           ; ids 0x18..0x1B: proj, proj, proj, proj
001146CC:  04040404  .byte   0x04, 0x04, 0x04, 0x04           ; ids 0x1C..0x1F: guard, guard, guard, guard
001146D0:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x20..0x23: attack, attack, attack, attack
001146D4:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x24..0x27: attack, attack, attack, attack
001146D8:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x28..0x2B: attack, attack, attack, attack
001146DC:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x2C..0x2F: attack, attack, attack, attack
001146E0:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x30..0x33: attack, attack, attack, attack
001146E4:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x34..0x37: attack, attack, attack, attack
001146E8:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x38..0x3B: attack, attack, attack, attack
001146EC:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x3C..0x3F: attack, attack, attack, attack
001146F0:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x40..0x43: attack, attack, attack, attack
001146F4:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x44..0x47: attack, attack, attack, attack
001146F8:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x48..0x4B: attack, attack, attack, attack
001146FC:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x4C..0x4F: attack, attack, attack, attack
00114700:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x50..0x53: attack, attack, attack, attack
00114704:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x54..0x57: attack, attack, attack, attack
00114708:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x58..0x5B: attack, attack, attack, attack
0011470C:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x5C..0x5F: attack, attack, attack, attack
00114710:  02020201  .byte   0x01, 0x02, 0x02, 0x02           ; ids 0x60..0x63: attack, vuln, vuln, vuln
00114714:  00020202  .byte   0x02, 0x02, 0x02, 0x00           ; ids 0x64..0x67: vuln, vuln, vuln, none
00114718:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0x68..0x6B: none, none, none, none
0011471C:  01060000  .byte   0x00, 0x00, 0x06, 0x01           ; ids 0x6C..0x6F: none, none, receiver, attack
00114720:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x70..0x73: attack, attack, attack, attack
00114724:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x74..0x77: attack, attack, attack, attack
00114728:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x78..0x7B: attack, attack, attack, attack
0011472C:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x7C..0x7F: attack, attack, attack, attack
00114730:  01010101  .byte   0x01, 0x01, 0x01, 0x01           ; ids 0x80..0x83: attack, attack, attack, attack
00114734:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0x84..0x87: none, none, none, none
00114738:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0x88..0x8B: none, none, none, none
0011473C:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0x8C..0x8F: none, none, none, none
00114740:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0x90..0x93: none, none, none, none
00114744:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0x94..0x97: none, none, none, none
00114748:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0x98..0x9B: none, none, none, none
0011474C:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0x9C..0x9F: none, none, none, none
00114750:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xA0..0xA3: none, none, none, none
00114754:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xA4..0xA7: none, none, none, none
00114758:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xA8..0xAB: none, none, none, none
0011475C:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xAC..0xAF: none, none, none, none
00114760:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xB0..0xB3: none, none, none, none
00114764:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xB4..0xB7: none, none, none, none
00114768:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xB8..0xBB: none, none, none, none
0011476C:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xBC..0xBF: none, none, none, none
00114770:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xC0..0xC3: none, none, none, none
00114774:  03000000  .byte   0x00, 0x00, 0x00, 0x03           ; ids 0xC4..0xC7: none, none, none, cond
00114778:  03030303  .byte   0x03, 0x03, 0x03, 0x03           ; ids 0xC8..0xCB: cond, cond, cond, cond
0011477C:  03030303  .byte   0x03, 0x03, 0x03, 0x03           ; ids 0xCC..0xCF: cond, cond, cond, cond
00114780:  03030303  .byte   0x03, 0x03, 0x03, 0x03           ; ids 0xD0..0xD3: cond, cond, cond, cond
00114784:  03030303  .byte   0x03, 0x03, 0x03, 0x03           ; ids 0xD4..0xD7: cond, cond, cond, cond
00114788:  03030303  .byte   0x03, 0x03, 0x03, 0x03           ; ids 0xD8..0xDB: cond, cond, cond, cond
0011478C:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xDC..0xDF: none, none, none, none
00114790:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xE0..0xE3: none, none, none, none
00114794:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xE4..0xE7: none, none, none, none
00114798:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xE8..0xEB: none, none, none, none
0011479C:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xEC..0xEF: none, none, none, none
001147A0:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xF0..0xF3: none, none, none, none
001147A4:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xF4..0xF7: none, none, none, none
001147A8:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xF8..0xFB: none, none, none, none
001147AC:  00000000  .byte   0x00, 0x00, 0x00, 0x00           ; ids 0xFC..0xFF: none, none, none, none

; end of listing
