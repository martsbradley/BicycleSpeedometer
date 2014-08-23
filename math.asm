
        list p=16f628a, free


        #include <p16f628a.inc>
    	ERRORLEVEL -302 ;removes warning message about using proper bank that occured on the line 'CLRF TRISB'
        #include util_macros.INC


global twosComplement32bits, twosComplement16bits
global increment32bit,  increment16bit

global Add32bit32bit

global argA, argB
global compare_unsigned_16, compare_signed16
global compare32bitReg, Div4824U
global mult_32_16, a1, b1, clear_mult_32_16_registers

global Div4824U,x, y, clear_mult_Div4824U_registers


complement32bitReg macro regName
    comf regName,F
    comf regName+1,F
    comf regName+2,F
    comf regName+3,F
    endm


BANK1 udata
    temp0 res 1
    x res 6
    y res 4
    Count res 1
    mathint res 6
    Rem res 3
    
    a1 res 1
    a2 res 1
    a3 res 1
    a4 res 1
    a5 res 1
    a6 res 1

    c1 res 1
    c2 res 1
    c3 res 1
    c4 res 1

    b1 res 1
    b2 res 1
    b3 res 1
    b4 res 1

    bitcnt res 1
    argA res 4
    argB res 4
; 32 bit dividend  into argA0-4 lsb in 0
; 16 bit divisor   into argB0-1
; 16 bit remainder into argB2-3


PROG code


twosComplement16bits:
    movwf argA ; store w in argA for safe keeping
    movwf FSR

    comf INDF, F

    incf FSR,F
    comf INDF, F

    movfw argA  ; move the contents of argA back into w

    call increment16bit
    return



;Takes argument in W
; To call "movlw fileRegister" where fileRegister is 24 bits long

twosComplement32bits:
    movwf argA ; store w in argA for safe keeping
    movwf FSR
    
    comf INDF, F

    incf FSR,F
    comf INDF, F

    incf FSR,F
    comf INDF, F

    incf FSR,F
    comf INDF, F

    movfw argA  ; move the contents of argA back into w

    call increment32bit
    return


; Takes the address in W
increment16bit:
    movwf FSR
    goto doIncrement16bits
    return

;From Dmitry Kiryashov
increment32bit:
    movwf   FSR
    bcf     STATUS, Z

    incfsz  INDF,F
    return

    incfsz  FSR,F
    incfsz  INDF,F
    return

    incfsz  FSR,F
doIncrement16bits:
    incfsz  INDF,F
    return

    incfsz  FSR,F
    incf    INDF,F
    return


; Adds argA & argB leaving the result in argB
Add32bit32bit:
    movf   argA0,w
    addwf  argB0,f

    movf   argA1,w
    btfsc  STATUS,C
    incfsz argA1,W
    addwf  argB1,f

    movf   argA2,w
    btfsc  STATUS,C
    incfsz argA2,w
    addwf  argB2,f

    movf   argA3,w
    btfsc  STATUS,C
    incfsz argA3,w
    addwf  argB3,f
    return



; signed and unsigned 16 bit comparison routine:
; by David Cary 2001-03-30
; returns the correct flags (Z and C)
; to indicate the X=Y, Y<X, or X<Y.
; Does not modify X or Y.
compare_signed16: ; 7
	; uses a "temp0" register.
	movf argB1,w
	xorlw 0x80
	movwf temp0
	movf argA1,w
	xorlw 0x80
	subwf temp0,w	; subtract Y-X
	goto Are_they_equal
compare_unsigned_16: ; 7
	movf argA1,w
	subwf argB1,w ; subtract Y-X
Are_they_equal:
	; Are they equal ?
	skpz
     goto results16
	; yes, they are equal -- compare lo
    movf argA0,w
    subwf argB0,w	; subtract Y-X
results16:
	; if X=Y then now Z=1.
	; if Y<X then now C=0.
	; if X<=Y then now C=1.
	return




; Compares argA and argB
; Signed numbers so there are four sign combinations
; argA  argB
;  +ve  +ve   ; goto handlePositive
;  +ve  -ve   ; return 1
;  -ve  +ve   ; return -1
;  -ve  -ve   ; goto handleNegative
;
; checkargA
; if -ve goto check argB
; if argB positive return -1
;
; A = B return 0x00
; A > B return 0x01
; A < B return 0x02
;

compare32bitReg:
    movfw argA3
    xorwf argB3, w
    andlw 0x80
    btfsc STATUS, Z   ; If zero was computed
                      ; it means the numbers have the same sign.
    goto numbersSignSame
    goto numbersSignDiffer

numbersSignDiffer:
    movfw argA3
    andlw 0x80
    btfss STATUS, Z
    goto returnAbigger
    goto returnAsmaller

numbersSignSame:
    complement32bitReg argB
    increment32bitReg argB, onComplete
onComplete:
    call Add32bit32bit
    clrw
    iorwf argB, W
    iorwf argB+1, W
    iorwf argB+2, W
    iorwf argB+3, W   ; crude way to check if argB is zero

    skpnz
    return      ; returns with zero in W register
                ; meaning they are equal.
    movfw argB+3
    andlw 0x80
    skpz    ; if the z is set the result was positive
    goto returnAsmaller
    goto returnAbigger


returnAbigger:
    movlw 0x01
    return
returnAsmaller:
    movlw 0x02
    return


clear_mult_Div4824U_registers:
    clear48bitReg x
    clear32bitReg y
    clrf Count
    clrf Rem
    clrf Rem+1
    clrf Rem+2
    return

;**************************************************************************
;Div4824U
;Inputs:
;	x - x:6 (x)	(0 - least significant!)
;	y	 - Test:3 (y)	(0 - least significant!)
;Temporary:
;	Counter	 - Count
;	Shift	 - Shift:6 (mathint)
;Output:
;	Quotient - x:6 (x)	(0 - least significant!)
;	Remainder- Rem:3	(0 - least significant!)
;
;Adaptation to PIC 12/16 Assembly and error fix of code by Frank Finster 3/15/2005
;by Lewis Lineberger 4/24/2009
;Fixes overrun in Rem+2 when upper bit of y+2 and Rem+2 are set, but Rem+2 is still
;less than y+2.  Overrun is illustrated by 0x34631A9FC / 0xDD39E9.
;Adaptation of 24x24 division by Tony Nixon with corrections
;PIC18 assembly instructions in comments for easy adaptation.
;by Frank Finster 3/15/2005.
;Code adapted by Andy Lee
;01-Sep-2006    Original version
;**************************************************************************

Div4824U:
;---------------------------------------------------
; SUBROUTINE - 48 by 24 BIT division
	movlw d'48'
	movwf Count
;	movff x+0, Shift+0
	movf x+0, W
	movwf mathint+0

;	movff x+1, Shift+1
	movf x+1, W
	movwf mathint+1

;	movff x+2, Shift+2
	movf x+2, W
	movwf mathint+2

;	movff x+3, Shift+3
	movf x+3, W
	movwf mathint+3

;	movff x+4, Shift+4
	movf x+4, W
	movwf mathint+4

;	movff x+5, Shift+5
	movf x+5, W
	movwf mathint+5

	clrf x+0
	clrf x+1
	clrf x+2
	clrf x+3
	clrf x+4
	clrf x+5

	clrf Rem+2
	clrf Rem+1
	clrf Rem+0
dloop
	bcf STATUS, C
	rlf mathint+0, F
	rlf mathint+1, F
	rlf mathint+2, F
	rlf mathint+3, F
	rlf mathint+4, F
	rlf mathint+5, F
	rlf Rem+0, F
	rlf Rem+1, F
	rlf Rem+2, F
	btfsc STATUS, C ; overrun
	goto subtract
	movf y+2, w
	subwf Rem+2, w
	btfss STATUS, Z
	goto nochk
	;bra nochk

	movf y+1,w
	subwf Rem+1,w
	btfss STATUS, Z
	goto nochk
	;bra nochk

	movf y+0,w
	subwf Rem+0,w
nochk
	btfss STATUS, C ; Rem >= y
	goto nogo
	;bra nogo

subtract	movf y+0,w
	subwf Rem+0, F
	btfsc STATUS, C
	goto nodec_remainM
	;bra	nodec_remainM
	decf Rem+1, f
	movf Rem+1, w
	xorlw 0xff
	btfsc STATUS, Z
		decf Rem+2, f
nodec_remainM
	movf y+1, w
	subwf Rem+1, f
	btfss STATUS, C
	decf Rem+2, f
	movf y+2, w
	subwf Rem+2, f
	bsf STATUS, C
nogo
	rlf x+0, F
	rlf x+1, F
	rlf x+2, F
	rlf x+3, F
	rlf x+4, F
	rlf x+5, F
	decfsz Count, f
	goto dloop
        return


clear_mult_32_16_registers:
    clear48bitReg a1

    clrf c1
    clrf c2
    clrf c3
    clrf c4

    clrf b1
    clrf b2
    clrf b3
    clrf b4
    return


;As a thank you for all the code, here is a 32x16 bit Mult.
;Unsigned 32 bit by 16 bit multiplication
;This routine will take a4:a3:a2:a1*b2:b1 -> a6:a5:a4:a3:a2:a1

mult_32_16:
    banksel	a4
; Begin rearrange code
	nop
	movf	a4,w
	movwf	a6
	movf	a3,w
	movwf	a5
	movf	a2,w
	movwf	a4
	movf	a1,w
	movwf	a3
; End rearrange code
    CLRF    a2          ; clear partial product
    CLRF    a1
    MOVF    a6,W
    MOVWF   c4
    MOVF    a5,W
    MOVWF   c3
    MOVF    a4,W
    MOVWF   c2
    MOVF    a3,W
    MOVWF   c1

    MOVLW   0x08
    MOVWF   bitcnt

LOOPUM3216A:
    RRF     b1, F
    BTFSC   STATUS, C
    GOTO    ALUM3216NAP
    DECFSZ  bitcnt, F
    GOTO    LOOPUM3216A

    MOVWF   bitcnt

LOOPUM3216B:
    RRF     b2, F
    BTFSC   STATUS, C
    GOTO    BLUM3216NAP
    DECFSZ  bitcnt, F
    GOTO    LOOPUM3216B

    CLRF    a6
    CLRF    a5
    CLRF    a4
    CLRF    a3
    RETLW   0x00

BLUM3216NAP:
    BCF     STATUS, C
    GOTO    BLUM3216NA

ALUM3216NAP:
    BCF     STATUS, C
    GOTO    ALUM3216NA

ALOOPUM3216:
    RRF     b1, F
    BTFSS   STATUS, C
    GOTO    ALUM3216NA
    MOVF   c1,W
    ADDWF   a3, F
    MOVF    c2,W
    BTFSC   STATUS, C
    INCFSZ  c2,W
    ADDWF   a4, F
    MOVF    c3,W
    BTFSC   STATUS, C
    INCFSZ  c3,W
    ADDWF   a5, F
    MOVF    c4,W
    BTFSC   STATUS, C
    INCFSZ  c4,W
    ADDWF   a6, F

ALUM3216NA:
    RRF    a6, F
    RRF    a5, F
    RRF    a4, F
    RRF    a3, F
    RRF    a2, F
    DECFSZ  bitcnt, f
    GOTO    ALOOPUM3216

    MOVLW   0x08
    MOVWF   bitcnt

BLOOPUM3216:
    RRF    b2, F
    BTFSS  STATUS, C
    GOTO   BLUM3216NA
    MOVF   c1,W
    ADDWF  a3, F
    MOVF   c2,W
    BTFSC  STATUS, C
    INCFSZ c2,W
    ADDWF  a4, F
    MOVF   c3,W
    BTFSC  STATUS, C
    INCFSZ c3,W
    ADDWF  a5, F
    MOVF   c4,W
    BTFSC  STATUS, C
    INCFSZ c4,W
    ADDWF  a6, F

BLUM3216NA
    RRF    a6, F
    RRF    a5, F
    RRF    a4, F
    RRF    a3, F
    RRF    a2, F
    RRF    a1, F
    DECFSZ  bitcnt, F
    GOTO    BLOOPUM3216
	nop
	return


    end
