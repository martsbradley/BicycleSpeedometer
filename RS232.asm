        list p=16f628a, free


        #include <p16f628a.inc>
    	ERRORLEVEL -302 ;removes warning message about using proper bank that occured on the line 'CLRF TRISB'
        #include util_macros.INC
; global variables/labels that this module exports.
global print, PrintDecimalDigits, InitUsartComms, PrintDecimalFractionDigits
global printchar_hi, printchar_lo, DecimalPlaces

; variables used by this module.
extern DIGIT1, DIGIT2,DIGIT3,DIGIT4,DIGIT5,DIGIT6,DIGIT7,DIGIT8
extern COUNT0, COUNT1, COUNT2, BINDEC

extern writeLCDData, lcdData

BANK0 udata
    printchar_hi res 1     ; string being printed.
    printchar_lo res 1
    PrintCounter1 res 1
    DecimalPlaces res 1

PROG  code

; subroutine to process string at look_hi look_lo
print:
    call lookup             ; get a byte (this is the magic)

    addlw 0x00              ; Check for end of string \0 character
    btfsc STATUS,Z
    return                  ;\0 hit - return from print subroutine.
    call RS232_SendByte
    goto print            ; do it again


                     

; Jump to address in look_hi/look_lo, which presumably is an RETLW.
; Note pointer post increment.
; Equivalent to: W=*look_ptr++
lookup:
    movfw printchar_hi      ; set PCLATH
    movwf PCLATH
    movfw printchar_lo     ; and get PCL
    incf printchar_lo,f    ; but post inc
    skpnz
    incf printchar_hi,f
                          ; the dt setup...
    movwf PCL               ; ok, now jump



; Move your value into COUNT0 & COUNT1
;; then call this method to print it.
;Print16bitInteger:
;    call BINDEC
;    call PrintDecimalDigits
;    return



; Print the decimal digits without the leading zeros
; Initialise counter to process first seven digits.
; The final digit is alway printed regardless.
; Setup Indirect Addressing at last digit
; @Author Martin Bradley.
PrintDecimalDigits:
    movlw DIGIT8               ;Digit8 is above Digit7654 so decrement the FSR
    movwf FSR                  ;To address the next digits.
    movlw 0x08                 ;8 digits to check.
    movwf PrintCounter1

checkZero:
    movfw INDF
    btfsc STATUS,Z
    goto handleZero        ;Found a digit that was zero
    goto printchars        ;Found the first non zero digit

handleZero:
    movfw PrintCounter1
    sublw 0x01
    btfsc STATUS,Z
     goto printchars   ; if ZeroCounter is 1 we print the final character

    decf PrintCounter1,F
    decf FSR,F
    goto checkZero

printchars:
    movfw INDF
    addlw 0x30
    call RS232_SendByte

    decf FSR,F
    decf PrintCounter1,F
    btfss STATUS,Z
    goto printchars
    return

#define LCD_ENABLE PORTA, RA7
#define LCD_RS PORTA, RA6

#define MODE_DATA bsf LCD_RS
#define MODE_CMD  bcf LCD_RS


RS232_SendByte:
    btfss   PIR1,TXIF       ; If TXIF = 1 ready to send another char
    goto    RS232_SendByte
    
    movwf   TXREG
;   bcf  INTCON, GIE      ; Enable interrupts globally
    movwf lcdData
    call writeLCDData
;    bsf  INTCON, GIE      ; Enable interrupts globally

    return


#define DECIMAL_PLACES 0x02

PrintDecimalFractionDigits:
    movlw DIGIT3               ;Digit8 is above Digit7654 so decrement the FSR
    movwf FSR                  ;To address the next digits.
    movfw DecimalPlaces
    ;movlw DECIMAL_PLACES       ;8 digits to check.
    movwf PrintCounter1
    goto printchars

InitUsartComms:           ; Setup the usart hardware
    bcf   TRISB, 2        ;
    banksel	TXSTA
    movlw 0x19            ; BAUD 9600 & FOSC 4000000L
    movwf SPBRG           ; 8 bit communication rather than 9bit
    movlw 0x24
    movwf TXSTA
    banksel RCSTA
    movlw 0x90            ; DIVIDER ((int)(FOSC/(16UL * BAUD) -1))
    movwf RCSTA           ; HIGH_SPEED 1
    return

    END                     ;Stop assembling here