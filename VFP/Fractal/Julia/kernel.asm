; Raspberry Pi 'Bare Metal' Julia Fractal Animation Demo by krom (Peter Lemon):
; 1. Turn On L1 Cache
; 2. Turn On Vector Floating Point Unit
; 3. Setup Frame Buffer
; 4. Plot Fractal Using Double-Precision
; 5. Change Julia Settings & Redraw To Animate

format binary as 'img'
include 'LIB\FASMARM.INC'
include 'LIB\R_PI.INC'

; Setup Frame Buffer
SCREEN_X       = 640
SCREEN_Y       = 480
BITS_PER_PIXEL = 32

; Setup VFP
VFPEnable = $40000000
VFPSingle = $300000
VFPDouble = $C00000

org BUS_ADDRESSES_l2CACHE_ENABLED + $8000

; Start L1 Cache
mov r0,0
mcr p15,0,r0,c7,c7,0 ; Invalidate Caches
mcr p15,0,r0,c8,c7,0 ; Invalidate TLB
mrc p15,0,r0,c1,c0,0 ; Read Control Register Configuration Data
orr r0,$1000 ; Instruction
orr r0,$0004 ; Data
orr r0,$0800 ; Branch Prediction
mcr p15,0,r0,c1,c0,0 ; Write Control Register Configuration Data

; Enable Vector Floating Point Calculations
mrc p15,0,r0,c1,c0,2 ; R0 = Access Control Register
orr r0,VFPSingle + VFPDouble ; Enable Single & Double Precision
mcr p15,0,r0,c1,c0,2 ; Access Control Register = R0
mov r0,VFPEnable ; Enable VFP
fmxr fpexc,r0 ; FPEXC = R0

FB_Init:
  imm32 r0,PERIPHERAL_BASE + MAIL_BASE
  imm32 r1,FB_STRUCT
  orr r1,MAIL_FB
  str r1,[r0,MAIL_WRITE] ; Mail Box Write

  FB_Read:
    ldr r1,[r0,MAIL_READ]
    tst r1,MAIL_FB ; Test Frame Buffer Channel 1
    beq FB_Read ; Wait For Frame Buffer Channel 1 Data

  imm32 r1,FB_POINTER
  ldr r0,[r1] ; R0 = Frame Buffer Pointer
  cmp r0,0 ; Compare Frame Buffer Pointer To Zero
  beq FB_Init ; IF Zero Re-Initialize Frame Buffer

ldr r1,[LAST_PIXEL]
add r1,r0 ; R1 = Frame Buffer Pointer Last Pixel

mov r2,SCREEN_X ; Load Double Screen X
fmsr s31,r2
fsitod d0,s31 ; D0 = X%
fcpyd d2,d0   ; D2 = SX

mov r2,SCREEN_Y ; Load Double Screen Y
fmsr s31,r2
fsitod d1,s31 ; D1 = Y%
fcpyd d3,d1   ; D3 = SY

fldd d4,[XMAX] ; D4 = XMax
fldd d5,[YMAX] ; D5 = YMax
fldd d6,[XMIN] ; D6 = XMin
fldd d7,[YMIN] ; D7 = YMin
fldd d8,[ANIM] ; D8 = Anim
fldd d9,[ONE]  ; D9 = 1.0

fcpyd d12,d9 ; D12 = CX (1.0)
fcpyd d13,d7 ; D13 = CY (-2.0)

ldr r12,[COL_MUL] ; R12 = Multiply Colour

Refresh:
  mov r2,r0 ; R2 = Frame Buffer Pointer
  mov r3,r1 ; R3 = Frame Buffer Pointer Last Pixel
  fcpyd d1,d3 ; D1 = Y%
  LoopY:
    fcpyd d0,d2 ; D0 = X%
    LoopX:
      fsubd d10,d4,d6 ; ZX = XMin + ((X% * (XMax - XMin)) / SX)
      fmuld d10,d0
      fdivd d10,d2
      faddd d10,d6 ; D10 = ZX

      fsubd d11,d5,d7 ; ZY = YMin + ((Y% * (YMax - YMin)) / SY)
      fmuld d11,d1
      fdivd d11,d3
      faddd d11,d7 ; D11 = ZY

      mov r4,192 ; R4 = IT (Iterations)
      Iterate:
	fmuld d14,d11,d11 ; XN = ((ZX * ZX) - (ZY * ZY)) + CX
	fmscd d14,d10,d10
	faddd d14,d12 ; D14 = XN

	fmuld d15,d10,d11 ; YN = (2 * ZX * ZY) + CY
	faddd d15,d15
	faddd d15,d13 ; D15 = YN

	fcpyd d10,d14 ; Copy XN & YN To ZX & ZY For Next Iteration
	fcpyd d11,d15

	fmuld d14,d14 ; R = (XN * XN) + (YN * YN)
	fmacd d14,d15,d15 ; D14 = R

	ftouid s31,d14 ; IF R > 4 THEN GOTO Plot
	fmrs r5,s31
	cmp r5,4
	bgt Plot

	subs r4,1 ; IT -= 1
	bne Iterate ; IF IT != 0 THEN GOTO Iterate

      Plot:
	mul r4,r12 ; R3 = Pixel Colour
	orr r4,$FF000000 ; Force Alpha To $FF
	str r4,[r2],4  ; Store Pixel Colour To Frame Buffer (Top)
	str r4,[r3],-4 ; Store Pixel Colour To Frame Buffer (Bottom)

	fsubd d0,d9 ; Decrement X%
	fcmpzd d0
	fmstat
	bne LoopX ; IF X% != 0 LoopX

	fsubd d1,d9 ; Decrement Y%
	cmp r2,r3
	blt LoopY ; IF Y% != 0 LoopY

	fsubd d12,d8 ; Change Julia Settings
	faddd d13,d8
	b Refresh

XMAX: dd 3.0
YMAX: dd 2.0
XMIN: dd -3.0
YMIN: dd -2.0
ANIM: dd 0.001
ONE:  dd 1.0

COL_MUL: dw $231AF9 ; Multiply Colour
LAST_PIXEL: dw (SCREEN_X * SCREEN_Y * (BITS_PER_PIXEL / 8)) - (BITS_PER_PIXEL / 8)

align 16
FB_STRUCT: ; Frame Buffer Structure
  dw SCREEN_X ; Frame Buffer Pixel Width
  dw SCREEN_Y ; Frame Buffer Pixel Height
  dw SCREEN_X ; Frame Buffer Virtual Pixel Width
  dw SCREEN_Y ; Frame Buffer Virtual Pixel Height
  dw 0 ; Frame Buffer Pitch (Set By GPU)
  dw BITS_PER_PIXEL ; Frame Buffer Bits Per Pixel
  dw 0 ; Frame Buffer Offset In X Direction
  dw 0 ; Frame Buffer Offset In Y Direction
FB_POINTER:
  dw 0 ; Frame Buffer Pointer (Set By GPU)
  dw 0 ; Frame Buffer Size (Set By GPU)