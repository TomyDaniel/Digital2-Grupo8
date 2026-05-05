LIST p=16F887
#include "p16f887.inc"

__CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _LVP_OFF
__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;==============================================================================
; VARIABLES
;==============================================================================
CBLOCK 0x70
    W_TEMP          
    STATUS_TEMP     
    INDEX           
    NUM3            ; Display Izquierda (D4) - Primer número que entra
    NUM2            
    NUM1            
    NUM0            ; Display Derecha (D1)
    TECLA_PRES      
    ESTADO_TECLA    ; 0 = Libre, 1 = Presionada
ENDC

    ORG 0x00
    GOTO INICIO

    ORG 0x04
    GOTO ISR

;==============================================================================
; INICIO
;==============================================================================
INICIO:
    CLRF    INDEX
    CLRF    ESTADO_TECLA
    MOVLW   0x10        ; 0x10 es "Apagado"
    MOVWF   NUM0
    MOVWF   NUM1
    MOVWF   NUM2
    MOVWF   NUM3

    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH

    BANKSEL TRISD
    CLRF    TRISD       ; Segmentos
    MOVLW   B'11110000' ; Teclado
    MOVWF   TRISB
    CLRF    TRISC       ; Comunes

    BANKSEL OPTION_REG
    BCF     OPTION_REG, 7 
    MOVLW   B'00000100'   ; TMR0 prescaler 1:32
    MOVWF   OPTION_REG

    BANKSEL WPUB
    MOVLW   B'11110000'
    MOVWF   WPUB

    BANKSEL IOCB
    MOVLW   B'11110000'
    MOVWF   IOCB

    BANKSEL PORTB
    CLRF    PORTB       

    BANKSEL INTCON
    MOVLW   B'10101000' 
    MOVWF   INTCON

    BANKSEL TMR0
    MOVLW   D'100'
    MOVWF   TMR0

LOOP:
    GOTO    LOOP

;==============================================================================
; ISR
;==============================================================================
ISR:
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP

    BTFSS   INTCON, RBIF
    GOTO    CHEQUEAR_TIMER

    MOVF    PORTB, W    
    BCF     INTCON, RBIF

    ANDLW   B'11110000'
    XORLW   B'11110000'
    BTFSC   STATUS, Z   
    GOTO    LIBERAR_TECLA 

    CALL    ESCANEO_TECLADO
    GOTO    CHEQUEAR_TIMER

LIBERAR_TECLA:
    CLRF    ESTADO_TECLA 
    GOTO    CHEQUEAR_TIMER

CHEQUEAR_TIMER:
    BTFSS   INTCON, TMR0IF
    GOTO    FIN_ISR

    BCF     INTCON, TMR0IF
    MOVLW   D'100'
    MOVWF   TMR0

    CLRF PORTC

    ; --- MULTIPLEXACIÓN CORREGIDA ---
    ; Apuntamos a NUM3, NUM2, NUM1, NUM0 en orden
    MOVLW   0x73        ; Dirección de NUM3 (0x73)
    ADDWF   INDEX, W
    MOVWF   FSR
    MOVF    INDF, W     

    CALL    TABLA_DISPLAY
    MOVWF   PORTD       

    MOVF    INDEX, W
    CALL    HABILITACION_DISPLAY
    MOVWF   PORTC       

    INCF    INDEX, F
    MOVLW   0x04
    XORWF   INDEX, W
    BTFSC   STATUS, Z
    CLRF    INDEX

FIN_ISR:
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE

;==============================================================================
; ESCANEO (Sin cambios en detección, solo en Guardar)
;==============================================================================
ESCANEO_TECLADO:
    MOVF    ESTADO_TECLA, F
    BTFSS   STATUS, Z
    RETURN

    ; Columna 0
    MOVLW B'11111110'
    MOVWF PORTB
    BTFSS PORTB, 4
    MOVLW 0x01
    BTFSS PORTB, 4
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 5
    MOVLW 0x04
    BTFSS PORTB, 5
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 6
    MOVLW 0x07
    BTFSS PORTB, 6
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 7
    MOVLW 0x0E
    BTFSS PORTB, 7
    GOTO GUARDAR_TECLA

    ; Columna 1
    MOVLW B'11111101'
    MOVWF PORTB
    BTFSS PORTB, 4
    MOVLW 0x02
    BTFSS PORTB, 4
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 5
    MOVLW 0x05
    BTFSS PORTB, 5
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 6
    MOVLW 0x08
    BTFSS PORTB, 6
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 7
    MOVLW 0x00
    BTFSS PORTB, 7
    GOTO GUARDAR_TECLA

    ; Columna 2
    MOVLW B'11111011'
    MOVWF PORTB
    BTFSS PORTB, 4
    MOVLW 0x0A
    BTFSS PORTB, 4
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 5
    MOVLW 0x0B
    BTFSS PORTB, 5
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 6
    MOVLW 0x0C
    BTFSS PORTB, 6
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 7
    MOVLW 0x0D
    BTFSS PORTB, 7
    GOTO GUARDAR_TECLA

    ; Columna 3
    MOVLW B'11110111'
    MOVWF PORTB
    BTFSS PORTB, 4
    MOVLW 0x03
    BTFSS PORTB, 4
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 5
    MOVLW 0x06
    BTFSS PORTB, 5
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 6
    MOVLW 0x09
    BTFSS PORTB, 6
    GOTO GUARDAR_TECLA
    BTFSS PORTB, 7
    MOVLW 0x0F
    BTFSS PORTB, 7
    GOTO GUARDAR_TECLA

    CLRF PORTB
    RETURN

GUARDAR_TECLA:
    MOVWF   TECLA_PRES
    MOVLW   0x01
    MOVWF   ESTADO_TECLA 
    
    ; --- DESPLAZAMIENTO INVERTIDO (Hacia la derecha) ---
    ; Lo que estaba en NUM1 pasa a NUM0
    ; Lo que estaba en NUM2 pasa a NUM1
    ; Lo que estaba en NUM3 pasa a NUM2
    ; El nuevo valor entra en NUM3 (Izquierda)
    
    MOVF    NUM1, W
    MOVWF   NUM0
    MOVF    NUM2, W
    MOVWF   NUM1
    MOVF    NUM3, W
    MOVWF   NUM2
    MOVF    TECLA_PRES, W
    MOVWF   NUM3

    CLRF    PORTB 
    RETURN

;==============================================================================
; TABLAS
;==============================================================================
   TABLA_DISPLAY:
    ADDWF   PCL, F
    RETLW   0x3F ; 0
    RETLW   0x06 ; 1
    RETLW   0x5B ; 2
    RETLW   0x4F ; 3
    RETLW   0x66 ; 4
    RETLW   0x6D ; 5
    RETLW   0x7D ; 6
    RETLW   0x07 ; 7
    RETLW   0x7F ; 8
    RETLW   0x6F ; 9
    RETLW   0x77 ; A
    RETLW   0x7C ; B
    RETLW   0x39 ; C
    RETLW   0x5E ; D
    RETLW   0x79 ; E
    RETLW   0x71 ; F
    RETLW   0x00 ; APAGADO

HABILITACION_DISPLAY:
    ADDWF   PCL, F
    RETLW   B'00000001' ; RC0 (NUM0 - derecha)
    RETLW   B'00000010' ; RC1
    RETLW   B'00000100' ; RC2
    RETLW   B'00001000' ; RC3 (NUM3 - izquierda)

    END