        list p=16f628a, free


        #include <p16f628a.inc>
    	ERRORLEVEL -302 ;removes warning message about using proper bank that occured on the line 'CLRF TRISB'


        #include util_macros.INC

global QuarterSecond, TenthSecond, Delay150ms, Delay5ms



BANK0  udata
    ButtonPressedValue res 1
    d1 res 1
    d2 res 1
    d3 res 1


PROG  code
QuarterSecond:
			;249993 cycles
	movlw	0x4E
	movwf	d1
	movlw	0xC4
	movwf	d2
QuarterSecond_0:
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	QuarterSecond_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return


TenthSecond:
			;99998 cycles
	movlw	0x1F
	movwf	d1
	movlw	0x4F
	movwf	d2
TenthSecond_0:
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	TenthSecond_0

			;2 cycles
	goto	$+1
    return








Delay150ms: ;149998 cycles

	movlw	0x2F
	movwf	d1
	movlw	0x76
	movwf	d2
Delay_150:
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_150

			;2 cycles
	goto	$+1
    return


Delay5ms:       ;4998 cycles
	movlw	0xE7
	movwf	d1
	movlw	0x04
	movwf	d2
Delay_0_5ms:
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_0_5ms

			;2 cycles
	goto	$+1
    return

    END