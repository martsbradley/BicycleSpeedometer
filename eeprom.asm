        list p=16f628a, free


        #include <p16f628a.inc>
    	ERRORLEVEL -302 ;removes warning message about using proper bank that occured on the line 'CLRF TRISB'
        #include util_macros.INC

global readEEPROM16bitInteger, writeEEPROM16bitInteger
global eeprom_data, eeprom_address

BANK0 udata
    eeprom_data  res 2     ; read/write to eeprom
    eeprom_address res 1

PROG  code

readEEPROM16bitInteger:
    call readEEPROMByte
    movwf eeprom_data
    incf  eeprom_address,f
    call readEEPROMByte
    movwf eeprom_data+1;
    return

; readEEPROMByte
; On entry eeprom_address holds the address to be read.
; On exit W contains the data that was read
readEEPROMByte:
    GOTO_BANK0
    movfw eeprom_address         ;Bank 0 get the adddress
    GOTO_BANK1
    movwf EEADR                  ;Address from W
    bsf   EECON1, RD             ;EE Read
    
    movfw EEDATA
    GOTO_BANK0
    return



;writeEEPROM16bitInteger
;writes the data in the eeprom_data word into the address at eeprom_address
writeEEPROM16bitInteger:
    ; The first call writes eeprom_data using eeprom_address as set
    ; by the caller
    call writeEEPROMByte

    movfw eeprom_data+1
    movwf eeprom_data
    incf eeprom_address,f   ; Read next address in the two byte word
    call writeEEPROMByte    ; write second byte
    return

; writeEEPROMByte
; On entry eeprom_address holds the address to be written.
; eeprom_data contains the byte to be written.
writeEEPROMByte:
    bcf     STATUS, RP1
    bsf     STATUS, RP0      ;BANK 1 to check EECON1

    btfsc   EECON1,WR        ;Wait for previous writes
    goto    $-1              ;to complete.


    GOTO_BANK0
    movfw   eeprom_address   ;register lives in shared data section
    GOTO_BANK1
    movwf   EEADR            ;Address to write.
    GOTO_BANK0
    movfw   eeprom_data      ;register lives in shared data section
    GOTO_BANK1
    movwf   EEDATA
 
    bsf     EECON1, WREN     ;Enable writes

    bcf     INTCON, GIE      ;Disable INTs.
    movlw   0x55             ;
    movwf   EECON2           ;Write 55h
    movlw   0xAA             ;
    movwf   EECON2           ;Write AAh
    bsf     EECON1, WR           ;Set WR bit to
                             ;begin write
    bsf     INTCON, GIE      ;Enable INTs.
    bcf     EECON1,WREN      ;Disable writes

    bcf     STATUS, RP1
    bcf     STATUS, RP0      ;Bank 0 again
    return

    end