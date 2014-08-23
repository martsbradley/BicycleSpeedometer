        list p=16f628a, free


        #include <p16f628a.inc>
    	ERRORLEVEL -302 ;removes warning message about using proper bank that occured on the line 'CLRF TRISB'
        #include util_macros.INC



;            Address Locations
;
;            2-Line Display LCD
;    Line 1:	00 hex, 01 hex, 02 hex,...........
;    Line 2:	40 hex, 41 hex, 42 hex,...........
;
;
;            4-Line Display LCD
;
;
;    Line 1:	00 hex, 01 hex, 02 hex,...........
;    Line 2:	40 hex, 41 hex, 42 hex,...........
;    Line 3:	20 hex, 21 hex, 22 hex,...........
;    Line 4:	60 hex, 61 hex, 62 hex,...........

; The command to set the address of the cursor is begins with 10xx xxxx
; The last 6 x values are the address
; Therefore to move to
; The first line  b10000000 or 0x80
; The second line b10101000 or 0xA8
; The third line  b10010100 or 0x94
; The fourth line b10111100 or 0xBC





global InitLCD, resetScreen, lcdData, writeLCDData
global writeLCDCommand,setFirstLine, setSecondLine, setThirdLine
global clearLine
extern Delay150ms, Delay5ms

#define LCD_RS PORTA, RA6
#define LCD_ENABLE PORTA, RA7
#define MODE_DATA bsf LCD_RS
#define MODE_CMD  bcf LCD_RS


;methods like



BANK0 udata
    lcdData res 1
    d1 res 1 ; temporary variable.
    characterCounter res 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PROG1   code

writeFourbits macro
    movfw lcdData
    andlw 0x0F
    movwf lcdData

    movfw PORTA
    andlw 0xF0
    iorwf lcdData,W
    movwf PORTA
    goto $+1
    goto $+1
    goto $+1

    bsf LCD_ENABLE
    goto $+1
    goto $+1
    goto $+1
    bcf LCD_ENABLE
    goto $+1
    goto $+1
    goto $+1

    endm


writeLCDData:
    MODE_DATA;
    movfw lcdData
    movwf d1   ;d1 used at a temporary

    rrf lcdData,F
    rrf lcdData,F
    rrf lcdData,F
    rrf lcdData,F


    writeFourbits
    movfw d1
    movwf lcdData
    writeFourbits

    MODE_CMD;
    return

writeLCDCommand:
    MODE_CMD
    movfw lcdData
    movwf d1   ;d1 used at a temporary

    rrf lcdData,F
    rrf lcdData,F
    rrf lcdData,F
    rrf lcdData,F

    writeFourbits
    movfw d1
    movwf lcdData
    writeFourbits
    MODE_DATA
    return


clearLine:
    movlw 0x14
    movwf characterCounter
clearChar:
    movlw 0x20 ; space

    movwf lcdData
    call writeLCDData
    decfsz characterCounter, F
    goto clearChar
    return

resetScreen:
    movlw 0x02
    movwf lcdData
    call writeLCDCommand
    call Delay5ms
    movlw 0x01
    movwf lcdData
    call writeLCDCommand
    call Delay5ms
    return

; done this to make sure the third and first lines are the same
; only as a test during the move to the two line LCD
setThirdLine:
setFirstLine:
    movlw 0x80
    movwf lcdData
    call writeLCDCommand
    call Delay5ms
    return



setSecondLine:
    movlw 0xA8
    movwf lcdData
    call writeLCDCommand
    call Delay5ms
    return

;setThirdLine:
;    movlw 0x94
;    movwf lcdData
;    call writeLCDCommand
;    call Delay5ms
;    return




;*****Init - set up all ports, make unused ports outputs

InitLCD:
    banksel TRISA
    clrf TRISA

    banksel PORTA
    bcf LCD_ENABLE
    bcf LCD_RS


    call Delay150ms

    movlw 0x03
    movwf lcdData
    writeFourbits
    call Delay5ms

    movlw 0x03
    movwf lcdData
    writeFourbits
    call Delay5ms

    movlw 0x03
    movwf lcdData
    writeFourbits
    call Delay5ms

    movlw 0x02
    movwf lcdData
    writeFourbits
    call Delay5ms

    movlw 0x2f
    movwf lcdData
    call writeLCDCommand
    call Delay5ms

    movlw 0x08
    movwf lcdData
    call writeLCDCommand
    call Delay5ms

    movlw 0x01
    movwf lcdData
    call writeLCDCommand
    call Delay5ms

    movlw 0x06
    movwf lcdData
    call writeLCDCommand
    call Delay5ms

    movlw 0x0c
    movwf lcdData
    call writeLCDCommand
    call Delay5ms


    call resetScreen
    return

    End             ;Stop assembling here



