LIST p=16F887
#include "p16f887.inc"

__CONFIG _CONFIG1, _FOSC_HS & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _LVP_OFF
__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;Variables
CBLOCK 0x70 
    W_TEMP          
    STATUS_TEMP 
    INDEX           
    DIS_0           
    DIS_1            
    DIS_2           
    DIS_3           
    TECLA_PRES      
    ESTADO_TECLA ;0=Libre, 1=Presionada
ENDC

    ORG 0x00
    GOTO INICIO

    ORG 0x04
    GOTO ISR

INICIO:
    CLRF    INDEX
    CLRF    ESTADO_TECLA
    MOVLW   0x10 ;Displays apagados        
    MOVWF   DIS_0
    MOVWF   DIS_1
    MOVWF   DIS_2
    MOVWF   DIS_3

    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH ;Salidas digitales
    
    ;Configuración de puertos
    BANKSEL TRISD
    CLRF    TRISD       ; Puerto D > Segmentos (Salida)
    MOVLW   B'11110000' ; Puerto B > Teclado (Filas: RB7-RB4 Entrada, Columnas: RB3-RB0 Salida)
    MOVWF   TRISB
    CLRF    TRISC       ; Puerto C > Displays (Salida)

    ;Configuración de registros de interrupción
    BANKSEL OPTION_REG
    BCF     OPTION_REG, 7 ;Resistencias de pull-up
    MOVLW   B'00000100'   ; TMR0 prescaler 1:32
    MOVWF   OPTION_REG

    BANKSEL WPUB
    MOVLW   B'11110000' ; Pull-ups RB4-RB7 (entradas del teclado)
    MOVWF   WPUB

    BANKSEL IOCB
    MOVLW   B'11110000' ; Interrupción por cambio en puerto B (RB4-RB7)
    MOVWF   IOCB
    
    BANKSEL PORTB
    CLRF    PORTB       

    BANKSEL INTCON
    MOVLW   B'10101000' ;GIE=1, T0IE=1, RBIE=1
    MOVWF   INTCON

    ;Recarga del TMR0
    BANKSEL TMR0
    MOVLW   D'100'
    MOVWF   TMR0
    ;T= 156*32us =5ms
    ;T_total= 5ms*4 =20ms 
    ;f= 1/20ms =50Hz
LOOP:
    GOTO    LOOP

;Rutina de interrupcion
ISR:
    ;Guardado de contexto (W/STATUS)
    MOVWF   W_TEMP
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP

    BTFSS   INTCON, RBIF ;RBIF=1 > cambio en el teclado
    GOTO    OVER_TIMER

    MOVF    PORTB, W    
    BCF     INTCON, RBIF ;RBIF=0 (bajada de bandera manual)

    ANDLW   B'11110000'
    XORLW   B'11110000'
    BTFSC   STATUS, Z   ;Z=0 Tecla presionada, Z=1 Tecla liberada
    GOTO    LIBERAR_TECLA 

    CALL    BARRIDO_TECLADO ;Z=0
    GOTO    OVER_TIMER

LIBERAR_TECLA:
    CLRF    ESTADO_TECLA 
    GOTO    OVER_TIMER

OVER_TIMER:
    BTFSS   INTCON, TMR0IF
    GOTO    FIN_ISR

    BCF     INTCON, TMR0IF ;TMR0IF=0 (Bajo la bandera)
    MOVLW   D'100' ;Recargo TMR0
    MOVWF   TMR0

    CLRF PORTC ;Apago displays

    ;Multiplexado de 4 displays
    MOVLW   0x73        ; Dirección de DIS_0 (0x73)
    ADDWF   INDEX, W
    MOVWF   FSR
    MOVF    INDF, W     

    CALL    TABLA_DISPLAY_CC
    MOVWF   PORTD       

    MOVF    INDEX, W
    CALL    HABILITACION_DISPLAY
    MOVWF   PORTC       

    INCF    INDEX, F
    MOVLW   0x04
    XORWF   INDEX, W
    BTFSC   STATUS, Z
    CLRF    INDEX
    
;Recuperación de contexto
FIN_ISR:
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE


BARRIDO_TECLADO:
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
    MOVWF   ESTADO_TECLA ;Anti rebote lógico
    
    ;Desplazamiento hacia la izquierda dis_0 > dis_1 > dis_2 > dis_3
    
    ; Corrimiento hacia la izquierda
    MOVF    DIS_2, W
    MOVWF   DIS_3
    MOVF    DIS_1, W
    MOVWF   DIS_2
    MOVF    DIS_0, W
    MOVWF   DIS_1
    MOVF    TECLA_PRES, W
    MOVWF   DIS_0
    
    CLRF    PORTB 
    RETURN

;Tablas
   TABLA_DISPLAY_CC:
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
    RETLW   B'00000001' ; RC0 (DIS_0 - derecha)
    RETLW   B'00000010' ; RC1
    RETLW   B'00000100' ; RC2
    RETLW   B'00001000' ; RC3 (DIS_3 - izquierda)

    END