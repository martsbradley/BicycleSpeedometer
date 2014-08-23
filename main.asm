        list p=16f628a, free
        #include <p16f628a.inc>

        __CONFIG _LVP_OFF & _INTOSC_OSC_NOCLKOUT & _WDT_OFF & _CP_OFF & _BOREN_OFF & _WDT_OFF & _MCLRE_ON 

    ;	ERRORLEVEL -302 ;removes warning message about using proper bank that occured on the line 'CLRF TRISB'
        #include util_macros.INC
extern QuarterSecond, TenthSecond

extern BINDEC
extern DIGIT1, DIGIT2,DIGIT3,DIGIT4,DIGIT5,DIGIT6,DIGIT7,DIGIT8
extern COUNT0, COUNT1, COUNT2

extern readEEPROM16bitInteger, writeEEPROM16bitInteger
extern eeprom_data, eeprom_address

extern print, PrintDecimalDigits, printchar_hi, printchar_lo
extern PrintDecimalFractionDigits
extern InitUsartComms

extern twosComplement32bits, increment32bit, twosComplement16bits

extern  Add32bit32bit

extern argA, argB, compare_unsigned_16
extern compare32bitReg
extern InterruptServiceRoutine
extern BinaryFraction, ConvertFractionBinary2Decimal, FractionConversion
extern InitLCD, lcdData, DecimalPlaces

extern clear_mult_32_16_registers, a1, b1, mult_32_16
extern clear_mult_Div4824U_registers, x, y, Div4824U
extern resetScreen, writeLCDData, clearLine,
extern setFirstLine, setSecondLine


global deltaArray0,deltaArray1,deltaArray2,deltaArray3
global ButtonPressedValue

global this_capture32, CaptureCounter, timer1_overflow


;  The following registers are in bank2
;   x, y a1, b1 and deltaArray0.. deltaArray3
;  The need to be moved using the xBanks macros


MILES_PER_HOUR            EQU 0
KILOMETERS_PER_HOUR       EQU 1

BackLightOFF EQU 0
BackLightON  EQU 1


;--------------------------------------------------------------------------
; Variables
;--------------------------------------------------------------------------
;global arg1, arg2, arg3, arg4


BANK0 udata
    ButtonPressedValue res 1
    pfBar res 2            ; current state funtion address.
    CaptureCounter  res 1
    DisplayUnits    res 1
    TimesWheelRotated res 4
    BackLightState  res 1

BANK1 udata
    deltaArray0     res 4
    deltaArray1     res 4
    deltaArray2     res 4
    deltaArray3     res 4

    last_capture32  res 4
    delta32         res 4 ; 32 bit signed integer.
    RevTime         res 4
    PreviousRevTime res 4
    speedDisplayFactor res 2
    timer1_overflow res 1
    deltaArrayIndex res 1


group2 udata_shr ; Data that goes into the shared bank area
    this_capture32  res 4
    speedMetersSec  res 6
    WheelDiameterCM res 2 ; 16 bit unsigned wheel diameter.

UpdateSpeedoState macro address
    movlw   HIGH(address)
    movwf   pfBar
    movlw   LOW(address)
    movwf   pfBar+1
    endm


; The following section of code is VERY important.
; It sets the interrupt code into PAGE1 at the correct position
PROG   code             ;Reset Vector
     goto    Main       ;Call main program

     nop
     nop
     nop
     goto InterruptServiceRoutine

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;MAIN METHOD;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Main:

     ;Setup the microchips ports etc.
    CLRF PORTA

    MOVLW 0x07
    MOVWF CMCON
    bcf  INTCON, GIE      ; Disable interrupts globally

    call QuarterSecond

    call Init

    bsf  INTCON, GIE      ; Enable interrupts globally
    bsf  INTCON, PEIE     ; Enable unmasked peripheral interrupts



;    call QuarterSecond
;    call QuarterSecond
;    call QuarterSecond

;
;    PrintString OK
;    call QuarterSecond
;    call QuarterSecond
;    call QuarterSecond
    PrintString SayReadyNow
    call QuarterSecond
    call QuarterSecond

Loop:
    GOTO_BANK0
    ; If the state is not passive then a button was pressed.
    ; so invoke the function for the current state.
    jifneq ButtonPressedValue, BUTTON_PASSIVE, InvokeStateFunction

    goto CheckForCapture
    

    ;+++this section can be removed
;    GOTO_BANK1
;    movfw RevTime
;    addlw 0x01
;    movwf RevTime
;    GOTO_BANK0
    ;+++this section can be removed
DisplayIfNeeded:

     GOTO_BANK0
     call setSecondLine
   ;  PrintString SayResetDistanceDone
     goto DisplaySpeedIfNecessary
    
EnableButtons:
    GOTO_BANK0
    btfss INTCON, RBIE
    goto ReenableButtons
    goto Loop

ReenableButtons:
    call TenthSecond
    bsf  INTCON, RBIE   ;  Reenable Button interrupts.
    goto Loop





; OK need a method
; that can be called each time the main loop iterates
; This will check if we are in the normal running state before
; Deciding to display the speed on line 1.
DisplaySpeedIfNecessary:
   movlw HIGH(NormalRunning)
   xorwf pfBar,w
   skpnz
   goto compareLowByte
   goto EnableButtons
compareLowByte:
   movlw LOW(NormalRunning)
   xorwf pfBar+1,w
   skpnz
   goto UpdateCurrentSpeed  ;comparison was zero so the fields were the same :-)
   goto EnableButtons




UpdateCurrentSpeed:
    GOTO_BANK1
    ; compare the previous and current times.
    move32bitReg RevTime, argA
    move32bitReg PreviousRevTime, argB
    call compare32bitReg
    addlw 0x00  ; needed to refresh the Status register 
    skpnz
    goto EnableButtons

    move32bitReg RevTime, PreviousRevTime


    ;Multiply the wheelSize by 1250 then shift 8 bits left
    ;Divide by the RevTime.  This leaves the fraction as the
    ;48bits = wheelSize * 1250 the << 8 bits.
    ;24bits is the RevTime.
    ;Result has fractional part in the lower 8 bits.



    ; Multiply by 1250 because;
    ; I am using cm rather than meters.
    ; The timer prescaler is 8micro seconds
    ; 2.05m becomes 205 cm via multiplication by 100
    ; 100 = 1e2
    ; 8ms = 8e-6
    ; Therefore multiply by 1/8e-4


    call clear_mult_32_16_registers
    move16RegToReg48 WheelDiameterCM, a1
    set16bitReg b1, 0x04, 0xE2        ; =  1250 or 1/8e-4
    call mult_32_16
    clear32bitReg b1
    set16bitReg b1, 0x01, 0x00        ; Would be quicker to shift left 8 bits
    call mult_32_16

    call clear_mult_Div4824U_registers
    move48bitReg a1, x
    move32bitReg RevTime, y
    call Div4824U
    
    move48bitReg x, speedMetersSec

MultiplyByUnitsFactor:
    GOTO_BANK1
    call clear_mult_32_16_registers
    move48bitReg speedMetersSec, a1
    move16RegToReg48 speedDisplayFactor, b1
    call mult_32_16
    ; This is multiplying Q24.8 by Q8.8
    ; Yeilds number in Q16.16 format in a1 that resides in bank2
    GOTO_BANK1
    movfw a1+1
    movwf speedMetersSec
  
    movfw a1+2
    movwf speedMetersSec+1


DisplayCurrentSpeed:
    
    GOTO_BANK0
    movlw 0x01
    movwf DecimalPlaces
    call setFirstLine
    call clearLine
    call setFirstLine

    movfw speedMetersSec
    movwf BinaryFraction
    
    movfw speedMetersSec+1
    movwf COUNT0

    movfw speedMetersSec+2
    movwf COUNT1

    movfw speedMetersSec+3
    movwf COUNT2

    call BINDEC
    call PrintDecimalDigits

    PrintString DecimalPlace

    movfw speedMetersSec

    movwf BinaryFraction
    call ConvertFractionBinary2Decimal
    movfw FractionConversion
    movwf COUNT0
    movfw FractionConversion+1
    movwf COUNT1
    clrf COUNT2

    
    call BINDEC
   
    call PrintDecimalFractionDigits
    nop



    jifneq DisplayUnits, KILOMETERS_PER_HOUR, DisplayMPH

    PrintString KPH
    goto SpeedUnitsBeenDisplayed
DisplayMPH:
    PrintString MPH

SpeedUnitsBeenDisplayed:

;    set32bitReg WheelDiameterCM, 0x00, 0x00, 0x00, 0xCD   ; 205 cm
;    set32bitReg TimesWheelRotated, 0x00, 0x01, 0x86, 0xA0 ; 100000
;    205 km or 127.3 miles

     GOTO_BANK1
;   Take wheel size in cm * number of turns
;   Divide by a numberto to get into MPH or KPH

    call clear_mult_32_16_registers

    GOTO_BANK0
    movfw TimesWheelRotated
    GOTO_BANK1
    movwf a1

    GOTO_BANK0
    movfw TimesWheelRotated+1
    GOTO_BANK1
    movwf a1+1

    GOTO_BANK0
    movfw TimesWheelRotated+2
    GOTO_BANK1
    movwf a1+2

    GOTO_BANK0
    movfw TimesWheelRotated+3
    GOTO_BANK1
    movwf a1+3

    movfw WheelDiameterCM
    movwf b1
    movfw WheelDiameterCM+1
    movwf b1+1
    call mult_32_16

    move48bitReg a1 , x



    ; Now shift x to the left discarding the top byte
    movfw x+4
    movwf x+5

    movfw x+3
    movwf x+4

    movfw x+2
    movwf x+3

    movfw x+1
    movwf x+2

    movfw x
    movwf x+1
    clrf x

    GOTO_BANK0
    jifneq DisplayUnits, KILOMETERS_PER_HOUR, DisplayDistanceMPH

    GOTO_BANK1
    set32bitReg y, 0x00, 0x01, 0x86, 0xA0 ; 100000
                                          ; divide by 100 * 1000 to get
                                          ; from CM to KM
    goto DistanceFactorBeenDisplayed
DisplayDistanceMPH:
    GOTO_BANK1
    set32bitReg y, 0x00, 0x02, 0x74, 0x84 ; Miles factor from cm
                                          ; 1609 meters in a mile * 100

DistanceFactorBeenDisplayed:

    call Div4824U

    movfw x+1
    GOTO_BANK0
    movwf COUNT0
    GOTO_BANK1
    movfw x+2
    GOTO_BANK0
    movwf COUNT1
    GOTO_BANK1
    movfw x+3
    GOTO_BANK0
    movwf COUNT2
    call setSecondLine
    call clearLine
    call setSecondLine

    call BINDEC
    call PrintDecimalDigits



    PrintString DecimalPlace

    GOTO_BANK1
    movfw x
    GOTO_BANK0
    movwf BinaryFraction
    movlw 0x02
    movwf DecimalPlaces
    call ConvertFractionBinary2Decimal
    movfw FractionConversion
    movwf COUNT0
    movfw FractionConversion+1
    movwf COUNT1
    clrf COUNT2


    call BINDEC
    call PrintDecimalFractionDigits


    ;1 metre =   0.000621371192 miles
    ;1 metre =   0.001 km
    ;1 mile =    1609.344 metres
    ;1 km   =    1000 metres



    GOTO_BANK0
    jifneq DisplayUnits, KILOMETERS_PER_HOUR, DistanceUnitsMiles

    PrintString KM
    goto DistanceUnitsDisplayed
DistanceUnitsMiles:

    PrintString MILES
DistanceUnitsDisplayed:

    goto EnableButtons



InvokeStateFunction:
;    movlw pfBar       ; Use FSR to point to pointer to function 1
;    call  InvokeFunction
    call InvokeBarFunction
    movlw BUTTON_PASSIVE
    movwf ButtonPressedValue
    goto  Loop


InvokeBarFunction:
    movfw pfBar
    movwf PCLATH
    movfw pfBar+1
    movwf PCL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;RESET DISTANCE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NormalRunning:
    jifeq  ButtonPressedValue, BUTTON_RB4_SET_PRESSED, NormalRunning_Set
    return

NormalRunning_Set:
    UpdateSpeedoState ResetDistance
    call setFirstLine
    call clearLine
    call setFirstLine
    PrintString SayResetDistance
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;RESET DISTANCE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ResetDistance:
    jifeq  ButtonPressedValue, BUTTON_RB4_SET_PRESSED, ResetDistance_Set
    jifeq  ButtonPressedValue, BUTTON_RB5_ADJUST_PRESSED, ResetDistance_Adjust
    call setSecondLine
    call clearLine
    call setFirstLine
    PrintString SayResetDistance
    return

ResetDistance_Set:
    UpdateSpeedoState BackLight
    call setSecondLine
    call clearLine
    call setFirstLine
    call clearLine
    call setFirstLine
    PrintString SayToggleBackLight

    return

ResetDistance_Adjust:
    clear32bitReg TimesWheelRotated
    call setSecondLine
    PrintString SayResetDistanceDone
    return






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;RESET DISTANCE;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BackLight:
    jifeq  ButtonPressedValue, BUTTON_RB4_SET_PRESSED, BackLight_Set
    jifeq  ButtonPressedValue, BUTTON_RB5_ADJUST_PRESSED, BackLight_Adjust
    call setSecondLine
    call clearLine
    call setFirstLine
    PrintString SayToggleBackLight
    return

BackLight_Set:
    UpdateSpeedoState InputWheelPrompt
    call setSecondLine
    call clearLine
    call setFirstLine
    call clearLine
    call setFirstLine
    PrintString SayChangeWheelSize
    call PromptChangeWheelSize
    return

BackLight_Adjust:
    call setSecondLine
    call clearLine
    call setSecondLine
    jifneq BackLightState, BackLightON, BackLightOn
   
    PrintString LightOff

    movlw BackLightOFF
    movwf BackLightState

    bcf PORTB, RB0
    goto BackLightDone

BackLightOn:
    movlw BackLightON
    movwf BackLightState
    PrintString LightOn
    bsf PORTB, RB0
BackLightDone:
    return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INPUT WHEEL;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InputWheelPrompt:
    jifeq  ButtonPressedValue, BUTTON_RB4_SET_PRESSED, InputWheelPrompt_Set
    jifeq  ButtonPressedValue, BUTTON_RB5_ADJUST_PRESSED, InputWheelPrompt_Adjust
    return

InputWheelPrompt_Set:
    UpdateSpeedoState SetUnits
    call setSecondLine
    call clearLine
    call setFirstLine
    call clearLine
    call setFirstLine

    PrintString SaySetUnits
    return


;  This method reads the currently stored
;  wheel size, then updates the wheel size before storing it back in the
;  eeprom
InputWheelPrompt_Adjust:

    call readWheelSize

    PrintString ReadWheelAs
    movfw WheelDiameterCM   ;PrintWheelSize:
    movwf COUNT0
    movfw WheelDiameterCM+1
    movwf COUNT1
    clrf  COUNT2

    ; Print the 16 bit Integer that is in COUNT1 & COUNT2
    call BINDEC
    call PrintDecimalDigits

    GOTO_BANK1
    movlw d'220'            ; upper bound for wheel size
    movwf argB
    movlw 0x00
    movwf argB+1

    move16bitRegTo32bitReg WheelDiameterCM, argA

    ;if( WheelDiameter <= ?? )
    call compare_unsigned_16
    skpc
    goto ChangeWheelDiameterReset
    ; then:

    incf  WheelDiameterCM+1,f
    incfsz WheelDiameterCM,f
    decf WheelDiameterCM+1,f

    goto ChangeWheelDiameterEnd
    ; else
ChangeWheelDiameterReset:
    movlw d'200'   ; lower bound for wheel size
    movwf WheelDiameterCM
    clrf  WheelDiameterCM+1
ChangeWheelDiameterEnd:
    GOTO_BANK0

    ;PrintString WroteWheel
    movfw WheelDiameterCM
    movwf eeprom_data
    movfw WheelDiameterCM+1

    movwf eeprom_data+1
    movlw 0x0a  ; this is the address I was using in the eeprom when using C
    movwf eeprom_address
    call writeEEPROM16bitInteger

    ;Continue into PromptChangeWheelSize
PromptChangeWheelSize:

    movfw WheelDiameterCM   ;PrintWheelSize:
    movwf COUNT0
    movfw WheelDiameterCM+1
    movwf COUNT1
    clrf  COUNT2

    call setSecondLine
    call clearLine
    call setSecondLine
    ; Print the 16 bit Integer that is in COUNT1 & COUNT2
    call BINDEC
    call PrintDecimalDigits
    PrintString WheelSizeUnits

    ;PrintString SayNewLine
    return



SetUnits:
    jifeq  ButtonPressedValue, BUTTON_RB4_SET_PRESSED, SetUnits_Set
    jifeq  ButtonPressedValue, BUTTON_RB5_ADJUST_PRESSED, SetUnits_Adjust
    return

SetUnits_Set:
    UpdateSpeedoState NormalRunning
    call setSecondLine
    call clearLine
    call setFirstLine
    call clearLine
    call setFirstLine
    return

SetUnits_Adjust:
    call setSecondLine
    call clearLine
    call setSecondLine
    jifeq DisplayUnits, KILOMETERS_PER_HOUR, SetUnits_MilesPerHour

SetUnits_KMPH:
    PrintString KPH

    movlw KILOMETERS_PER_HOUR
    movwf DisplayUnits
    
    ;the low byte of speedDisplayFactor is fractional part.
    GOTO_BANK1
    ;1ms = 3.6kmps  (Calculated using the Fractions spreadsheet)
    set16bitReg speedDisplayFactor,  0x03, 0x9A
    GOTO_BANK0
    return
SetUnits_MilesPerHour:
    PrintString SayMilesPerHour
    ;1ms = 2.23693629mph
    ;fractional part is 0x3D giving 0.236
    
    GOTO_BANK1
    set16bitReg speedDisplayFactor,  0x02, 0x3D
    GOTO_BANK0
    movlw MILES_PER_HOUR
    movwf DisplayUnits

    ;store this value in the speedDisplayFactor

    return



readWheelSize:
    movlw 0x0a  ; this is the address I was using in the eeprom when using C
    movwf eeprom_address
    call readEEPROM16bitInteger
    movfw  eeprom_data
    movwf WheelDiameterCM
    movfw eeprom_data+1
    movwf WheelDiameterCM+1
    return

;RP1:RP0 Bank
;0   0      0
;0   1      1
;1   0      2
;1   1      3




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SETUP  ROUTINES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*****Init - set up all ports, make unused ports outputs

Init:
    banksel PCON
    bsf	PCON, OSCF
    banksel T1CON ;back to bank 1

    call  InitUsartComms
    


    call InitInterruptOnChange
    call InitTimer0      ; Timer used for button debouncing.
    call InitTimer1
    call InitCapturePin1
    call InitInterruptVars
    call InitLCD


    banksel TRISB         
    bcf   TRISB, TRISB0    ; Output on portB0  to control the back light!!
    GOTO_BANK0




    ; Setup some function pointers for examples for later.
    movlw   HIGH(NormalRunning)   ; Initialize pointer to function 2
    movwf   pfBar
    movlw   LOW(NormalRunning)
    movwf   pfBar+1


    ; set the button as passive.
    movlw BUTTON_PASSIVE
    movwf ButtonPressedValue



    movlw d'205'
    movwf WheelDiameterCM
    clrf  WheelDiameterCM+1
    call readWheelSize

    
    ;0x03, 0x9A    KILOMETERS_PER_HOUR
    ;0x02, 0x3D    MILES_PER_HOUR
    movlw MILES_PER_HOUR
    movwf DisplayUnits
    GOTO_BANK1
    clear32bitReg PreviousRevTime
    clear32bitReg RevTime
    set16bitReg speedDisplayFactor, 0x02, 0x3D  ; MPH





    GOTO_BANK0
    clear48bitReg speedMetersSec
    clear32bitReg TimesWheelRotated

    movlw BackLightOFF
    movwf BackLightState

    movlw 0x03
    movwf DecimalPlaces

    ;PrintString SayReadyNow

    return



InitInterruptOnChange:
    banksel TRISB         
    bsf   TRISB,  TRISB4   ; Input on port RB7/5
    bsf   TRISB,  TRISB5   ;
    bcf   TRISB, TRISB0    ; Output on portB0  to control the back light!!
    bcf   INTCON, RBIF     ; Clear Port Change Interrupt Flag bit
    bsf   INTCON, RBIE     ; Enables the RB port change interrupt
    bsf   STATUS, RP0      ; Change to bank1
                           ; Enable the pull up on port B inputs.
    bcf   OPTION_REG, NOT_RBPU
    bcf   STATUS, RP0      ; Back to bank0
    return

InitTimer0:                ; Timer0 used for button debouncing.
    clrf TMR0              ; Clear the counter for T0
    banksel OPTION_REG     ; Change to bank1
    bsf  OPTION_REG, PS0   ; Prescaler set to 0b111 = 256
    bsf  OPTION_REG, PS1
    bsf  OPTION_REG, PS2
    bcf  OPTION_REG, PSA   ; Prescaler is on Timer0 rather than the WDT
    bcf  OPTION_REG, T0CS  ; This is a Timer rather than a counter on a pin.
    bcf  STATUS, RP0       ; Back to bank0
    bcf  INTCON, TMR0IE    ; Mask the timer0 interrupt.
    return

;#define IN 1
;#define OUT 0

InitCapturePin1:
    banksel TRISB
    movlw b'01111111'
    movwf TRISB
    bsf PIE1, CCP1IE
    banksel CCP1CON
    movlw  0x05 ; rising edge.
    movwf CCP1CON


    call startTimer1
    return

startTimer1:
    bsf T1CON, TMR1ON
    banksel PIE1   ; back to bank 2
    bsf PIE1, TMR1IE
    banksel TMR0  ; back to bank 0
    return


InitTimer1:
    clrf TMR1H
    clrf TMR1L

    movlw b'00110000'
          ; **00****   1:8 prescale
          ; ****0***   oscillator off
          ; *****0**   This bit is ignored as the internal clock is in use.
          ; ******0*   Internal clock
          ; *******0   Dont start the timer.
    movwf T1CON;

   ; // With the setting 0b00110001; as above the clock gets
   ; // incremented every 8 micro seconds.
   ; // The counter has range 0000h to FFFFh
   ;// which is 65535 * 8 = 524280 microseconds before it overflows.
   ; // that is 196.605 milli seconds or almost 1/5 of a second.

   ; //1000000/4 = 250000
    return

InitInterruptVars:
    GOTO_BANK1
    clear32bitReg this_capture32
    clear32bitReg last_capture32
    clear32bitReg delta32
    clrf timer1_overflow
    clrf  deltaArrayIndex

    GOTO_BANK0
    
    clrf  CaptureCounter
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;SETUP  ROUTINES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;








;--------------------------------------------------------------------------
; String tables that are needed to be printed out.
;--------------------------------------------------------------------------

SayResetDistance:
    dt "Reset Distance:\0"
       ;123456789abcdef
SayResetDistanceDone:
    dt "Dist reset to 0\0"
       ;123456789abcdef
SayChangeWheelSize:
    dt "Wheel Adjust:\0"
       ;123456789abcdef

SayInputWheelPrompt:
    dt "Wheel Size: \0"
       ;123456789abcdef
SayReadyNow:
    dt "Marty's Speedo\0"

SayNewLine:
    dt "\r\n\0"

DecimalPlace:
    dt ".\0"

SaySetUnits:
    dt "Set Units\0"
       ;123456789abcdef
SayMilesPerHour:
    dt "mph\0"

RevCounter:
    dt "RevCounter: \0"
ReadWheelAs:
    dt "ReadWheelAs: \0"

WroteWheel:
    dt "EEPROMUpdated: \0"

SpaceChar:
    dt " \0"

WheelSizeUnits:
    dt " cm circum\0"

KPH:
    dt " kmh \0"

MPH:
    dt " mph \0"

MILES:
    dt " miles\0"
KM:
    dt " kms\0"

;OK:
;    dt "ok\0";
;
TIMEROVER:
    dt "0.0 MPH\0"
;
;OK2:
;    dt "ok2\0";
;
;HERE2:
;    dt "here2\0"

SayToggleBackLight:
    dt "Toggle Lights\0"

LightOn:
    dt "Light On\0";
LightOff:
    dt "Light Off\0";

CheckForCapture:
    movf CaptureCounter,f
    btfsc STATUS, Z
    goto CheckifStopped
    goto ProcessCapture


CheckifStopped:
    clrf CaptureCounter
    GOTO_BANK1
    clear32bitReg argA
    movfw timer1_overflow       ; Check for too many timer overflows
    movwf argA
    set32bitReg argB, 0x00, 0x00, 0x00, 0x03
    call compare32bitReg

    ; if argA > argB result in W is 1
    andlw 0x01  
    skpnz
    goto DisplayIfNeeded
    set32bitReg RevTime, 0x7F, 0xFF, 0xFF, 0xFF ;  Set the rev time
    goto DisplayIfNeeded                        ;  So high its effective 0mph



;   This chart shows x (last capture) and y (this capture
;   along with various overflows.
;   |__________|__________|__________|__________|__________|__________|
;      x             y
;      x y
;            x  y
;     x                        y

ProcessCapture:

    increment32bitReg TimesWheelRotated, ProcessCapture_1
ProcessCapture_1:

    clrf CaptureCounter
    GOTO_BANK1

    movf timer1_overflow,f
    btfsc STATUS, Z             ; if (timer_overflow != 0) {
    goto CaptureNoOverflow
                                ; then:
    clear32bitReg delta32

    decf timer1_overflow,W      ; delta32 = timer1_overflow-1;

    movwf delta32+2             ; delta32 = (delta32 << 16);
                                ; move into delta32+2 handles the 16 bit shift.

    movlw last_capture32        ; 
    call twosComplement32bits  ; negate last_capture32

    set32bitReg argA, 0x00, 0x00, 0xFF, 0xFF
    move32bitReg last_capture32, argB
    call Add32bit32bit
                                ; delta32 = delta32 + last_capture32
                                ; delta32 = delta32 + this_capture32
    move32bitReg delta32, argA
  
    call Add32bit32bit         ; Now ArgB holds delta32+last_capture32


    move32bitReg this_capture32, argA
    call Add32bit32bit         ; Now ArgB holds delta32+this_capture32

    move32bitReg argB, delta32

    goto CaptureStoreDelta
CaptureNoOverflow:              ; else: timer1_overflow == 0
                                ; so calculate
                                ; delta32 = this_capture32 - last_capture32;
    movlw last_capture32
    call twosComplement32bits  ; negate last_capture32

    move32bitReg this_capture32, argA
    move32bitReg last_capture32, argB

    call Add32bit32bit             ;delta32 = delta32 + (-last_capture32)

    move32bitReg argB, delta32


CaptureStoreDelta:
    clrf timer1_overflow

    move32bitReg this_capture32, last_capture32
    ;Need to store the delta in the array.

    ; So use to calculate the FSR needed
    ; then move it here.

;    bcf INTCON, GIE      ;Disable Interrupts
    
    
    bcf  STATUS, IRP
    movlw deltaArray0
    movwf FSR

    ;Multiply the Index by 4 to get the correct offset
    movfw deltaArrayIndex
    movwf argA
    bcf STATUS, C
    rlf argA                ; * times 2
    bcf STATUS, C
    rlf argA                ; * times 2
    movfw argA

    addwf FSR, F            ; add W onto FSR to give correct offset

    movfw delta32
    movwf INDF

    incf FSR, F
    movfw delta32+1
    movwf INDF

    incf FSR, F
    movfw delta32+2
    movwf INDF

    incf FSR, F

    movfw delta32+3
    movwf INDF

    ; now increment deltaArrayIndex
    incf  deltaArrayIndex, F  ; reset if index is > 3
    btfsc deltaArrayIndex, 2  ; is the bit for 4 set?
    clrf  deltaArrayIndex     ; then go back to zero
    
; Rather than working out the speed by dividing meters by seconds
; I am going to divide cm by 100th's of seconds.
; This method will return the time in 100ths of seconds.








CalcAverageTimer1CountValue:



    ;clear32bitReg PreviousRevTime
    ;banksel deltaArray0
    ;set32bitReg deltaArray0, 0x00, 0x00, 0x58,0xBE
    ;set32bitReg deltaArray1, 0x00, 0x00, 0x58,0xBE
    ;set32bitReg deltaArray2, 0x00, 0x00, 0x58,0xBE
    ;set32bitReg deltaArray3, 0x00, 0x00, 0x58,0xBE
    ;Should give 14.25036147m/s


    move32bitReg deltaArray0, argA
    move32bitReg deltaArray1, argB
    call Add32bit32bit

    move32bitReg deltaArray2, argA
    call Add32bit32bit

    move32bitReg deltaArray3, argA

    call Add32bit32bit

    ; should be using two shifts right for division by 4.
    call clear_mult_Div4824U_registers

    move32bitReg argB, x
    set32bitReg y, 0x00, 0x00, 0x00, 0x04
    call Div4824U
    move32bitReg x, RevTime

;    bsf INTCON, GIE          ;Renable Interrupts
    goto DisplayIfNeeded


    END                     ;Stop assembling here