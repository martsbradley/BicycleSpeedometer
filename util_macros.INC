;; call_cntstack address if equal


BUTTON_PASSIVE            EQU 0
BUTTON_RB4_SET_PRESSED    EQU 1
BUTTON_RB5_ADJUST_PRESSED EQU 2


#define GOTO_BANK0 bcf STATUS, RP0
#define GOTO_BANK1 bsf STATUS, RP0

;call_cntstack macro address
;    local here, makeCall
;    movwf stackwtmp
;    bcf  INTCON, GIE
;    incf stackcounter, F
;
;
;
;    movfw stackcounter
;    subwf stackmax,w	; subtract w from f
;                        ; stackmax - stackcounter
;	; if stackmax == stackcounter then now Z=1.
;   ; if stackmax < stackcounter then now C=0.
;	; if stackmax > stackcounter then now C=1.
;    btfsc STATUS, Z
;    goto makeCall
;    btfsc STATUS, C
;    goto makeCall
;    movfw stackcounter
;    movwf stackmax
;    bsf  INTCON, GIE


fcall macro address
    local here, makeCall
    lcall address
    pagesel here
    endm

;makeCall:
;    movfw stackwtmp
;
;
;    lcall address
;    pagesel here
;    endm
;
;
;
;return_cntstack macro
;    decf stackcounter,f
;    return
;    endm

cifeq   macro register,literal,address
    movlw literal
    xorwf register,w
    skpnz
    call_cntstack   address
    endm

; call_cntstack address if not equal
cifneq macro register,literal,address
    movlw literal
    xorwf register,w
    skpz
    call_cntstack   address
    endm

; Jump to address if not equal
jifneq macro register,literal,address
    movlw literal
    xorwf register,w
    skpz
    goto  address
    endm


; Jump to address if equal
jifeq macro register,literal,address
    movlw literal
    xorwf register,w
    skpnz
    goto  address
    endm

if_A_greaterthan_B_goto macro address
    call compare32bitReg
    xorlw 0x01
    skpnz
    goto  address
    endm


Jump_If_Adjust_Pressed macro address
    JIFEQ ButtonPressedValue, BUTTON_RB4_ADJUST_PRESSED, address
    endm


Jump_If_Set_Pressed macro address
    JIFEQ ButtonPressedValue, BUTTON_RB5_SET_PRESSED, address
    endm

clear16bitReg macro fileRegister
    clrf fileRegister
    clrf fileRegister+1
    endm

clear32bitReg macro fileRegister
    clrf fileRegister+2
    clrf fileRegister+3
    clrf fileRegister+1
    clrf fileRegister
    endm

clear48bitReg macro fileRegister
    clrf fileRegister+4
    clrf fileRegister+5
    clrf fileRegister+2
    clrf fileRegister+3
    clrf fileRegister+1
    clrf fileRegister
    
    endm

move32bitReg macro src,dest
    movfw src
    movwf dest
  
    movfw src+1
    movwf dest+1

    movfw src+2
    movwf dest+2

    movfw src+3
    movwf dest+3
    endm

 move48bitReg macro src,dest
    move32bitReg src,dest
    movfw src+4
    movwf dest+4
    movfw src+5
    movwf dest+5
    endm


move16bitReg macro src, dest
    movfw src
    movwf dest

    movfw src+1
    movwf dest+1
    endm


move16bitRegTo32bitReg macro src, dest
    clear32bitReg dest
    move16bitReg src, dest
    endm

move16RegToReg48 macro src, dest
    clear48bitReg dest
    move16bitReg src, dest
    endm

;*******************************************************************
; Double Precision Multiplication
;
; argA1 : argA0 * argA3 : argA2 -> argB3:argB2:argB1:argB0
;
; Standard shift and add.
; Execution time: 215 to 295 clock cycles.
; Code space: 22 locations
;
; Cleaned up and corrected version from Microchip Ap note by BF.
; Note: Ap note has errors! Additional mods by Scott Dattalo.
;
;*******************************************************************
mpy16b16: macro
    local nextbit, nobit_l, nobit_h
	clrf    argB3
	clrf	argB2
	clrf    argB1
	movlw	0x80
	movwf	argB0

nextbit
	rrf		argA1,f
	rrf		argA0,f

	btfss	STATUS, C
	goto	nobit_l
	movf	argA2,w
	addwf	argB1,f

	movf	argA3, w
	btfsc	STATUS, C
	incfsz	argA3, w
	addwf	argB2, f
	btfsc	STATUS, C
	incf	argB3, f
	bcf		STATUS, C

nobit_l
	btfss	argA0, 7
	goto	nobit_h
	movf	argA2,w
	addwf	argB2,f
	movf	argA3, w
	btfsc	STATUS, C
	incfsz	argA3, w
	addwf	argB3, f

nobit_h
	rrf		argB3,f
	rrf		argB2,f
	rrf		argB1,f
	rrf		argB0,f

	btfss   STATUS, C
	goto	nextbit
endm

#define argA0 argA
#define argA1 argA+1
#define argA2 argA+2
#define argA3 argA+3

#define argB0 argB
#define argB1 argB+1
#define argB2 argB+2
#define argB3 argB+3


PrintString macro string
    movlw high string       ; point to the string

    movwf printchar_hi      ; in printchar_hi & low
    movlw low string
    movwf printchar_lo
    call print              ; go process it
    endm



setArgA macro a, b, c, d
    movlw d
    movwf argA
    movlw c
    movwf argA+1
    movlw b
    movwf argA+2
    movlw a
    movwf argA+3
    endm
setArgB macro a, b, c, d
    movlw d
    movwf argB
    movlw c
    movwf argB+1
    movlw b
    movwf argB+2
    movlw a
    movwf argB+3
    endm

set32bitReg macro Reg, a, b, c, d
    movlw d
    movwf Reg
    movlw c
    movwf Reg+1
    movlw b
    movwf Reg+2
    movlw a
    movwf Reg+3
    endm

set16bitReg macro Reg, c, d
    movlw d
    movwf Reg
    movlw c
    movwf Reg+1
    endm


increment32bitReg macro regName, onComplete

    bcf     STATUS, Z

    incfsz regName,F
    goto onComplete

    incfsz  regName+1,F
    goto onComplete

    incfsz  regName+2,F
    goto onComplete

    incf    regName+3,F
    goto onComplete
    endm