        list p=16f628a, free


        #include <p16f628a.inc>
    	ERRORLEVEL -302 ;removes warning message about using proper bank that occured on the line 'CLRF TRISB'
        #include util_macros.INC

; These globals are for the BINDEC method
global BINDEC
global DIGIT1, DIGIT2,DIGIT3,DIGIT4,DIGIT5,DIGIT6,DIGIT7,DIGIT8
global COUNT0, COUNT1, COUNT2
global BinaryFraction, ConvertFractionBinary2Decimal, FractionConversion

extern argA, argB, Add32bit32bit


; These globals are for the BIN2BCD method
;global byte2numberInput, hundreds, tens, units

BANK0  udata
;    byte2numberInput res 1 ; binary to decimal conversion
;    hundreds res 1
;    tens res 1
;    units res 1
;    count res 1

    DIGIT1 res 1  ;/*  These are needed for
    DIGIT2 res 1
    DIGIT3 res 1
    DIGIT4 res 1
    DIGIT5 res 1  ;     The binary to decimal
    DIGIT6 res 1
    DIGIT7 res 1
    DIGIT8 res 1

    ConvertCounter1 res 1
    ConvertCounter2 res 1

    COUNT0 res 1
    COUNT1 res 1
    COUNT2 res 1

    
    BinaryFraction res 1
    FractionConversion res 2 ; holds the fraction 0 - > 999 used for display.



PROG code


; BINDEC
; Converts 24bit binary into decimal
; Input: COUNT0,COUNT1,COUNT2
; Updates: ConvertCounter1 & ConvertCounter2 - uses these internally
; Output: DIGIT8..DIGIT7..DIGIT6..DIGIT5..DIGIT4..DIGIT3..DIGIT2..DIGIT1
BINDEC:
            CLRF DIGIT1
        	CLRF DIGIT2
        	CLRF DIGIT3
        	CLRF DIGIT4
        	CLRF DIGIT5
        	CLRF DIGIT6
        	CLRF DIGIT7
        	CLRF DIGIT8


        	MOVLW d'24'
        	MOVWF ConvertCounter1
        	GOTO SHIFT1
ADJBCD:  	MOVLW DIGIT1
        	MOVWF FSR
        	MOVLW d'7'
        	MOVWF ConvertCounter2
        	MOVLW d'3'
ADJLOOP: 	ADDWF INDF,F
        	BTFSS INDF,3
        	SUBWF INDF,F
        	INCF FSR,F
        	DECFSZ ConvertCounter2,F
        	GOTO ADJLOOP
SHIFT1:  	call SLCNT
SLDEC:   	MOVLW DIGIT1
        	MOVWF FSR
        	MOVLW d'8'
        	MOVWF ConvertCounter2
SLDLOOP:
        	RLF INDF,F
        	BTFSC INDF,4
        	BSF STATUS,C
        	BCF INDF,4
        	INCF FSR,F
        	DECFSZ ConvertCounter2,F
        	GOTO SLDLOOP
        	DECFSZ ConvertCounter1,F
        	GOTO ADJBCD
        	return
SLCNT:   	RLF COUNT0,F
        	RLF COUNT1,F
        	RLF COUNT2,F
        	return


; After the 500 the other values 250,125 etc fit in
; one byte, a shift right could be sued to divide by 2
; and shorten the code.

;0.5             500         1	500
;0.25            250         1	250
;0.125           125         1	125
;0.0625          62.5		 1	62.5
;0.03125         31.25		 0	0
;0.015625        15.625		 0	0
;0.0078125		 7.8125		 0	0
;0.00390625		 3.90625	 1	3.90625
;
;                               941.40625

;    ArgA will hold the result.
; This method takes a 8bit value that represents a fraction
; and converts it into a value from 0 to 1000 that can be displayed.
;
ConvertFractionBinary2Decimal:
    clear16bitReg FractionConversion
    clear32bitReg argB
    bcf STATUS, C
    movlw 0x07
    movwf ConvertCounter1 ; used to repeat 7 times.
    movlw 0xFA ; 250
    movwf ConvertCounter2; used for the value thats halfed on each iteration.
Convert0.5:
    rlf BinaryFraction
    btfss STATUS, C
    goto Convert0.25
    set32bitReg FractionConversion, 0x00, 0x00, 0x01, 0xF4
 
Convert0.25:
    bcf STATUS, C
    rlf BinaryFraction
    btfss STATUS, C
    goto RepeatConversion   ;Bit was Zero

    move32bitReg FractionConversion, argA
    clear32bitReg argB
    movfw ConvertCounter2
    movwf argB
    call Add32bit32bit
    move32bitReg argB, FractionConversion

RepeatConversion:
    bcf STATUS, C
    rrf ConvertCounter2
    decfsz ConvertCounter1,F
    goto Convert0.25
    return
    end
