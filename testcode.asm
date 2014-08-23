        list p=16f628a, free


        #include <p16f628a.inc>
    	ERRORLEVEL -302 ;removes warning message about using proper bank that occured on the line 'CLRF TRISB'


        #include util_macros.INC

extern argA, argB
extern compare32bitReg, Add32bit32bit
extern mult_32_16, a1, b1, clear_mult_32_16_registers
extern Div4824U, x, y, clear_mult_Div4824U_registers
global TestCode

BANK1  udata
;    BinaryFraction res 1
;    FractionConversion res 2 ; holds the fraction 0 - > 999 used for display.
;
;    COUNTER1 res 1
;    COUNTER2 res 1

PROG  code

TestCode:

;    movlw 0x80
;    movwf BinaryFraction
;
;ConvertFractionBinary2Decimal:
;    clear16bitReg FractionConversion
;    clear32bitReg argB
;    bcf STATUS, C
;Convert0.5:
;    rlf BinaryFraction
;    btfss STATUS, C
;    goto Convert0.25
;    set32bitReg FractionConversion, 0x00, 0x00, 0x01, 0xF4
;
;
;    movlw 0x07
;    movwf COUNTER1 ; used to repeat 7 times.
;    movlw 0xFA ; 250
;    movwf COUNTER2; used for the value thats halfed on each iteration.
;
;
;Convert0.25:
;    bcf STATUS, C
;    rlf BinaryFraction
;    btfss STATUS, C
;    goto RepeatConversion   ;Bit was Zero
;
;    move32bitReg FractionConversion, argA
;    clear32bitReg argB
;    movfw COUNTER2
;    movwf argB
;    call Add32bit32bit
;    move32bitReg argB, FractionConversion
;
;RepeatConversion:
;    bcf STATUS, C
;    rrf COUNTER2
;    decfsz COUNTER1,F
;    goto Convert0.25
;    return


























    banksel a1
    call clear_mult_32_16_registers
    set32bitReg a1, 0x00, 0x00, 0x00, 0xCD
    set16bitReg b1, 0x04, 0xE2
    call mult_32_16

    nop

    banksel a1
    call clear_mult_32_16_registers
    set16bitReg a1, 0x04, 0xE2
    set32bitReg b1, 0x00, 0x00, 0x00, 0xCD

    call mult_32_16

    nop


    banksel a1
    call clear_mult_32_16_registers
    set32bitReg a1, 0x00, 0x0C, 0xDC, 0x01
    set16bitReg b1, 0x09, 0x51
    call mult_32_16

    nop
    nop

    call clear_mult_Div4824U_registers
    move48bitReg a1, x
    set16bitReg y, 0x09, 0x51
    call Div4824U

    nop
    nop

    goto TestCode

;    set32bitReg argA, 0x00, 0x00, 0x00, 0x01
;
;    set32bitReg argB, 0x00, 0x00, 0x00, 0x00
;
;    call compare32bitReg
;    nop
;    nop
;
;    set32bitReg argA, 0x00, 0x00, 0x00, 0x00
;
;    set32bitReg argB, 0x00, 0x00, 0x00, 0x01
;
;    call compare32bitReg
;    nop
;    nop
;
;
;
;    set32bitReg argA, 0x00, 0x01, 0x00, 0x01
;
;    set32bitReg argB, 0x00, 0x00, 0x01, 0xFF
;
;    call compare32bitReg
;    nop
;    nop
;
;
;    set32bitReg argA, 0x00, 0x00, 0x76, 0xF2
;
;    set32bitReg argB, 0x00, 0x02, 0x9b, 0x51
;
;    call compare32bitReg
;    nop
;    nop
;    return





;           timer1_overflow,    this_capture32  last_capture32  delta32
; Test1     0                   5000            4000            1000
;           0x00                0x1388          0x0FA0          0X03E8
;
;    movlw 0x00
;    movwf timer1_overflow
;    set32bitReg this_capture32, 0x00, 0x00, 0x13, 0x88
;    set32bitReg last_capture32, 0x00, 0x00, 0x0F, 0xA0
;    code should calculate delta as 03E8           Test Passed.


; Test2     0                   50000           1000            49000
;           0x00                0xC350          0X03E8          0xBF68

;
; Test3     1                   0               0               65536
;           0x01                0x00            0x00            0xFFFF
;
;    movlw 0x01
;    movwf timer1_overflow
;    set32bitReg this_capture32, 0x00, 0x00, 0x00, 0x00
;    set32bitReg last_capture32, 0x00, 0x00, 0x00, 0x00
;    code should calculate delta as 0xFFFF          Test Passed.

; Test4     1                   5000            4000            66536
;           0x01                0x1388          0x0FA0          0x0103E8
;    movlw 0x01
;    movwf timer1_overflow
;    set32bitReg this_capture32, 0x00, 0x00, 0x13, 0x88
;    set32bitReg last_capture32, 0x00, 0x00, 0x0F, 0xA0
;    code should calculate delta as  0x0103E8     Test Passed (gave 0x0103E7)


; Test5     1                   1000            50000           114536
    END