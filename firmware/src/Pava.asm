       LIST    P=16F887
        #include <p16f887.inc>
        ERRORLEVEL -302

; ============================================================
; CONFIGURACION
; ============================================================

        __CONFIG _CONFIG1, _INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
        __CONFIG _CONFIG2, _BOR40V & _WRT_OFF

; ============================================================
; CONSTANTES
; ============================================================

TMR0_PRELOAD    EQU     d'225'      ; aprox 1 ms con Fosc=4MHz y prescaler 1:32

; ============================================================
; VARIABLES
; ============================================================

        CBLOCK  0x20
            ADC8
            TEMP_C

            SETPOINT
            SET_TMP
            HAS_SETPOINT

            RX_FLAG
            RXCHAR
            DIGITO

            VALUE
            TENS
            UNITS
            AUX1
            AUX2

            DISP_SP_D
            DISP_SP_U
            DISP_T_D
            DISP_T_U

            MUX_IDX

            TX_COUNT
            TX_DIV
            TX_FLAG
            TXTEMP

            RELAY_STATE

            D1
        ENDC

; Variables comunes para interrupcion
        CBLOCK  0x70
            W_TEMP
            STATUS_TEMP
            PCLATH_TEMP
        ENDC

; ============================================================
; VECTOR RESET
; ============================================================

        ORG     0x0000
        GOTO    INIT

; ============================================================
; VECTOR INTERRUPCION
; ============================================================

        ORG     0x0004
        GOTO    ISR

; ============================================================
; TABLA 7 SEGMENTOS
; Catodo comun:
; RD0=a, RD1=b, RD2=c, RD3=d, RD4=e, RD5=f, RD6=g
; ============================================================

        ORG     0x0008

SEG_TABLE:
        ADDWF   PCL, F
        RETLW   b'00111111'     ; 0
        RETLW   b'00000110'     ; 1
        RETLW   b'01011011'     ; 2
        RETLW   b'01001111'     ; 3
        RETLW   b'01100110'     ; 4
        RETLW   b'01101101'     ; 5
        RETLW   b'01111101'     ; 6
        RETLW   b'00000111'     ; 7
        RETLW   b'01111111'     ; 8
        RETLW   b'01101111'     ; 9

; ============================================================
; INTERRUPCION TMR0
; Multiplexa los 4 displays
;
; Orden fisico pedido:
; RC0 - RC1 - RC2 - RC3
;
; RC0 y RC1 -> temperatura sensada
; RC2 y RC3 -> setpoint
; ============================================================

        ORG     0x0020

ISR:
        ; Guardar contexto
        MOVWF   W_TEMP
        SWAPF   STATUS, W
        MOVWF   STATUS_TEMP
        MOVF    PCLATH, W
        MOVWF   PCLATH_TEMP

        BANKSEL INTCON
        BTFSS   INTCON, 2          ; T0IF
        GOTO    ISR_RESTORE

        BCF     INTCON, 2          ; limpiar T0IF

        BANKSEL TMR0
        MOVLW   TMR0_PRELOAD
        MOVWF   TMR0

; ------------------------------------------------------------
; Apagar todos los displays antes de cambiar segmentos
; Asumo transistores activos en alto:
; RCx = 1 prende display
; RCx = 0 apaga display
; ------------------------------------------------------------

        BANKSEL PORTC
        BCF     PORTC, 0
        BCF     PORTC, 1
        BCF     PORTC, 2
        BCF     PORTC, 3

; ------------------------------------------------------------
; MUX_IDX:
; 0 -> temperatura decenas/unidades corregido en UPDATE_DISPLAY
; 1 -> temperatura decenas/unidades corregido en UPDATE_DISPLAY
; 2 -> setpoint decenas/unidades corregido en UPDATE_DISPLAY
; 3 -> setpoint decenas/unidades corregido en UPDATE_DISPLAY
; ------------------------------------------------------------

        BANKSEL MUX_IDX
        MOVF    MUX_IDX, W
        BTFSC   STATUS, Z
        GOTO    ISR_TEMP_DEC

        MOVLW   d'1'
        SUBWF   MUX_IDX, W
        BTFSC   STATUS, Z
        GOTO    ISR_TEMP_UNI

        MOVLW   d'2'
        SUBWF   MUX_IDX, W
        BTFSC   STATUS, Z
        GOTO    ISR_SP_DEC

        GOTO    ISR_SP_UNI

ISR_TEMP_DEC:
        BANKSEL DISP_T_D
        MOVF    DISP_T_D, W
        BANKSEL PORTD
        MOVWF   PORTD

        BANKSEL PORTC
        BSF     PORTC, 0
        GOTO    ISR_NEXT

ISR_TEMP_UNI:
        BANKSEL DISP_T_U
        MOVF    DISP_T_U, W
        BANKSEL PORTD
        MOVWF   PORTD

        BANKSEL PORTC
        BSF     PORTC, 1
        GOTO    ISR_NEXT

ISR_SP_DEC:
        BANKSEL DISP_SP_D
        MOVF    DISP_SP_D, W
        BANKSEL PORTD
        MOVWF   PORTD

        BANKSEL PORTC
        BSF     PORTC, 2
        GOTO    ISR_NEXT

ISR_SP_UNI:
        BANKSEL DISP_SP_U
        MOVF    DISP_SP_U, W
        BANKSEL PORTD
        MOVWF   PORTD

        BANKSEL PORTC
        BSF     PORTC, 3

ISR_NEXT:
        BANKSEL MUX_IDX
        INCF    MUX_IDX, F

        MOVLW   d'8'
        SUBWF   MUX_IDX, W
        BTFSC   STATUS, C
        CLRF    MUX_IDX

; ------------------------------------------------------------
; Envio UART cada aprox 1 segundo
; TX_COUNT cuenta 250 ms
; TX_DIV cuenta 4 veces 250 ms = 1 segundo
; ------------------------------------------------------------

        BANKSEL TX_COUNT
        INCF    TX_COUNT, F

        MOVLW   d'250'
        SUBWF   TX_COUNT, W
        BTFSS   STATUS, C
        GOTO    ISR_RESTORE

        CLRF    TX_COUNT

        INCF    TX_DIV, F

        MOVLW   d'8'
        SUBWF   TX_DIV, W
        BTFSS   STATUS, C
        GOTO    ISR_RESTORE

        CLRF    TX_DIV
        BSF     TX_FLAG, 0

ISR_RESTORE:
        ; Restaurar contexto
        MOVF    PCLATH_TEMP, W
        MOVWF   PCLATH

        SWAPF   STATUS_TEMP, W
        MOVWF   STATUS

        SWAPF   W_TEMP, F
        SWAPF   W_TEMP, W

        RETFIE

; ============================================================
; PROGRAMA PRINCIPAL
; ============================================================

        ORG     0x0100

INIT:
; ------------------------------------------------------------
; Oscilador interno 4 MHz
; ------------------------------------------------------------

        BANKSEL OSCCON
        MOVLW   b'01100001'
        MOVWF   OSCCON

; ------------------------------------------------------------
; AN0 analogico, resto digital
; ------------------------------------------------------------

        BANKSEL ANSEL
        MOVLW   b'00000001'        ; AN0 analogico
        MOVWF   ANSEL

        CLRF    ANSELH             ; PORTB digital

; ------------------------------------------------------------
; Puertos
; ------------------------------------------------------------

        ; RA0 entrada LM35
        BANKSEL TRISA
        BSF     TRISA, 0

        ; RB0 salida relay
        BANKSEL TRISB
        MOVLW   b'11111110'
        MOVWF   TRISB

        ; PORTD salida segmentos
        BANKSEL TRISD
        CLRF    TRISD

        ; RC0-RC3 salidas displays
        ; RC6 TX salida
        ; RC7 RX entrada
        BANKSEL TRISC
        MOVLW   b'10000000'
        MOVWF   TRISC

; ------------------------------------------------------------
; Limpiar puertos
; ------------------------------------------------------------

        BANKSEL PORTB
        CLRF    PORTB              ; relay apagado

        BANKSEL PORTC
        CLRF    PORTC              ; displays apagados

        BANKSEL PORTD
        CLRF    PORTD              ; segmentos apagados

; ------------------------------------------------------------
; ADC
; AN0, Vref=Vdd, justificacion izquierda
; ------------------------------------------------------------

        BANKSEL ADCON1
        CLRF    ADCON1

        BANKSEL ADCON0
        MOVLW   b'01000001'        ; Fosc/8, canal AN0, ADC ON
        MOVWF   ADCON0

; ------------------------------------------------------------
; UART 9600 baudios, Fosc=4MHz
; RC6 TX, RC7 RX
; ------------------------------------------------------------

        BANKSEL SPBRG
        MOVLW   d'25'
        MOVWF   SPBRG

        BANKSEL TXSTA
        MOVLW   b'00100100'        ; TXEN=1, BRGH=1
        MOVWF   TXSTA

        BANKSEL RCSTA
        MOVLW   b'10010000'        ; SPEN=1, CREN=1
        MOVWF   RCSTA

; ------------------------------------------------------------
; Variables iniciales
; ------------------------------------------------------------

        BANKSEL SETPOINT
        CLRF    SETPOINT           ; arranca sin setpoint
        CLRF    SET_TMP
        CLRF    HAS_SETPOINT       ; 0 = displays de umbral apagados

        CLRF    RX_FLAG
        CLRF    ADC8
        CLRF    TEMP_C
        CLRF    MUX_IDX
        CLRF    TX_COUNT
        CLRF    TX_DIV
        CLRF    TX_FLAG
        CLRF    RELAY_STATE

        ; Displays iniciales
        ; Temperatura se actualiza con ADC
        ; Setpoint queda apagado hasta recibir Uxx
        CLRF    DISP_SP_D
        CLRF    DISP_SP_U
        CLRF    DISP_T_D
        CLRF    DISP_T_U

; ------------------------------------------------------------
; Timer0
; ------------------------------------------------------------

        BANKSEL OPTION_REG
        MOVLW   b'00000011'        ; T0CS=0, PSA=0, PS=100 -> 1:32
        MOVWF   OPTION_REG

        BANKSEL TMR0
        MOVLW   TMR0_PRELOAD
        MOVWF   TMR0

        BANKSEL INTCON
        MOVLW   b'10100000'        ; GIE=1, T0IE=1
        MOVWF   INTCON

        CALL    TX_INICIO

; ============================================================
; LOOP PRINCIPAL
; ============================================================

MAIN:
        CALL    RECIBIR_UART_ALL
        CALL    LEER_ADC
        CALL    CALC_TEMP
        CALL    UPDATE_DISPLAY
        CALL    CONTROL_RELAY

        BANKSEL TX_FLAG
        BTFSS   TX_FLAG, 0
        GOTO    MAIN

        BCF     TX_FLAG, 0
        CALL    ENVIAR_ESTADO

        GOTO    MAIN

; ============================================================
; LEER ADC
; Guarda ADRESH en ADC8
; ============================================================

LEER_ADC:
        CALL    DELAY_ADC

        BANKSEL ADCON0
        BSF     ADCON0, 1          ; iniciar conversion

WAIT_ADC:
        BTFSC   ADCON0, 1
        GOTO    WAIT_ADC

        BANKSEL ADRESH
        MOVF    ADRESH, W

        BANKSEL ADC8
        MOVWF   ADC8

        RETURN

; ============================================================
; CALC_TEMP
;
; Ajuste simple:
; TEMP_C = ADC8*2 - ADC8/10
;
; Aproxima ADC8*1,9
; ============================================================

CALC_TEMP:
        BANKSEL ADC8

        ; TEMP_C = ADC8 * 2
        MOVF    ADC8, W
        MOVWF   TEMP_C

        BCF     STATUS, C
        RLF     TEMP_C, F

        ; VALUE = ADC8
        MOVF    ADC8, W
        MOVWF   VALUE

        ; TENS = ADC8 / 10
        CLRF    TENS

DIV10_LOOP:
        MOVLW   d'10'
        SUBWF   VALUE, W           ; W = VALUE - 10
        BTFSS   STATUS, C
        GOTO    DIV10_DONE

        MOVWF   VALUE
        INCF    TENS, F
        GOTO    DIV10_LOOP

DIV10_DONE:
        ; TEMP_C = TEMP_C - TENS
        MOVF    TENS, W
        SUBWF   TEMP_C, F

        RETURN

; ============================================================
; UPDATE_DISPLAY
;
; Displays:
; RC0 y RC1 -> temperatura sensada
; RC2 y RC3 -> setpoint
; ============================================================

UPDATE_DISPLAY:
; ------------------------------------------------------------
; TEMP_C -> displays RC0 y RC1
; Se carga invertido para que visualmente quede correcto.
; ------------------------------------------------------------

        BANKSEL TEMP_C
        MOVF    TEMP_C, W
        CALL    LIMIT_99
        CALL    NUM_TO_2DIG

        ; unidades de temperatura
        CLRF    PCLATH
        BANKSEL UNITS
        MOVF    UNITS, W
        CALL    SEG_TABLE
        BANKSEL DISP_T_D
        MOVWF   DISP_T_D

        ; decenas de temperatura
        CLRF    PCLATH
        BANKSEL TENS
        MOVF    TENS, W
        CALL    SEG_TABLE
        BANKSEL DISP_T_U
        MOVWF   DISP_T_U

; ------------------------------------------------------------
; Si todavía no llegó setpoint, apagar displays RC2 y RC3
; ------------------------------------------------------------

        BANKSEL HAS_SETPOINT
        MOVF    HAS_SETPOINT, F
        BTFSC   STATUS, Z
        GOTO    UD_SETPOINT_APAGADO

; ------------------------------------------------------------
; SETPOINT -> displays RC2 y RC3
; Se carga invertido para que visualmente quede correcto.
; ------------------------------------------------------------

        BANKSEL SETPOINT
        MOVF    SETPOINT, W
        CALL    LIMIT_99
        CALL    NUM_TO_2DIG

        ; unidades del setpoint
        CLRF    PCLATH
        BANKSEL UNITS
        MOVF    UNITS, W
        CALL    SEG_TABLE
        BANKSEL DISP_SP_D
        MOVWF   DISP_SP_D

        ; decenas del setpoint
        CLRF    PCLATH
        BANKSEL TENS
        MOVF    TENS, W
        CALL    SEG_TABLE
        BANKSEL DISP_SP_U
        MOVWF   DISP_SP_U

        RETURN

UD_SETPOINT_APAGADO:
        BANKSEL DISP_SP_D
        CLRF    DISP_SP_D
        CLRF    DISP_SP_U

        RETURN

; ============================================================
; LIMIT_99
; Entrada W = numero
; Salida W = numero limitado a 99
; ============================================================

LIMIT_99:
        BANKSEL VALUE
        MOVWF   VALUE

        MOVLW   d'100'
        SUBWF   VALUE, W           ; W = VALUE - 100
        BTFSC   STATUS, C
        GOTO    LIMIT_IS_99

        MOVF    VALUE, W
        RETURN

LIMIT_IS_99:
        MOVLW   d'99'
        RETURN

; ============================================================
; NUM_TO_2DIG
; Entrada W = 0..99
; Salida:
; TENS = decenas
; UNITS = unidades
; ============================================================

NUM_TO_2DIG:
        BANKSEL VALUE
        MOVWF   VALUE
        CLRF    TENS
        CLRF    UNITS

N2D_LOOP:
        MOVLW   d'10'
        SUBWF   VALUE, W
        BTFSS   STATUS, C
        GOTO    N2D_DONE

        MOVWF   VALUE
        INCF    TENS, F
        GOTO    N2D_LOOP

N2D_DONE:
        MOVF    VALUE, W
        MOVWF   UNITS
        RETURN

; ============================================================
; CONTROL RELAY CON HISTERESIS
;
; Si no hay setpoint recibido:
;   relay OFF
;
; Si TEMP_C >= SETPOINT:
;   relay OFF
;
; Si TEMP_C <= SETPOINT - 2:
;   relay ON
;
; Relay en RB0, activo en alto.
; ============================================================

CONTROL_RELAY:
        BANKSEL HAS_SETPOINT
        MOVF    HAS_SETPOINT, F
        BTFSC   STATUS, Z
        GOTO    RELAY_OFF

        BANKSEL TEMP_C

        ; TEMP_C >= SETPOINT ?
        MOVF    SETPOINT, W
        SUBWF   TEMP_C, W          ; W = TEMP_C - SETPOINT
        BTFSC   STATUS, C
        GOTO    RELAY_OFF

        ; AUX1 = SETPOINT - 2
        MOVF    SETPOINT, W
        MOVWF   AUX1

        MOVLW   d'5'
        SUBWF   AUX1, F

        ; TEMP_C <= AUX1 ?
        MOVF    TEMP_C, W
        SUBWF   AUX1, W            ; W = AUX1 - TEMP_C
        BTFSC   STATUS, C
        GOTO    RELAY_ON

        RETURN

RELAY_ON:
        BANKSEL PORTB
        BSF     PORTB, 0

        BANKSEL RELAY_STATE
        MOVLW   d'1'
        MOVWF   RELAY_STATE
        RETURN

RELAY_OFF:
        BANKSEL PORTB
        BCF     PORTB, 0

        BANKSEL RELAY_STATE
        CLRF    RELAY_STATE
        RETURN

; ============================================================
; RECIBIR UART
;
; Formato esperado:
; U70 + ENTER
; U85 + ENTER
; ============================================================

RECIBIR_UART_ALL:
        CALL    RECIBIR_UART

        BANKSEL PIR1
        BTFSC   PIR1, 5            ; mientras RCIF=1 sigue leyendo
        GOTO    RECIBIR_UART_ALL

        RETURN

RECIBIR_UART:
        BANKSEL PIR1
        BTFSS   PIR1, 5            ; RCIF
        RETURN

        ; Overrun
        BANKSEL RCSTA
        BTFSS   RCSTA, 1           ; OERR
        GOTO    RX_READ

        BCF     RCSTA, 4           ; CREN=0
        BSF     RCSTA, 4           ; CREN=1
        RETURN

RX_READ:
        BANKSEL RCREG
        MOVF    RCREG, W

        BANKSEL RXCHAR
        MOVWF   RXCHAR

        ; U
        MOVLW   'U'
        SUBWF   RXCHAR, W
        BTFSC   STATUS, Z
        GOTO    RX_START

        ; u
        MOVLW   'u'
        SUBWF   RXCHAR, W
        BTFSC   STATUS, Z
        GOTO    RX_START

        ; ENTER CR
        MOVLW   d'13'
        SUBWF   RXCHAR, W
        BTFSC   STATUS, Z
        GOTO    RX_END

        ; ENTER LF
        MOVLW   d'10'
        SUBWF   RXCHAR, W
        BTFSC   STATUS, Z
        GOTO    RX_END

        ; Si no estoy cargando setpoint, ignoro
        MOVF    RX_FLAG, F
        BTFSC   STATUS, Z
        RETURN

        ; Verificar digito 0..9
        MOVLW   '0'
        SUBWF   RXCHAR, W          ; W = RXCHAR - '0'
        BTFSS   STATUS, C
        RETURN

        MOVWF   DIGITO

        MOVLW   d'10'
        SUBWF   DIGITO, W
        BTFSC   STATUS, C
        RETURN

        CALL    MULT10_ADD_DIGIT
        RETURN

RX_START:
        MOVLW   d'1'
        MOVWF   RX_FLAG
        CLRF    SET_TMP
        RETURN

RX_END:
        MOVF    RX_FLAG, F
        BTFSC   STATUS, Z
        RETURN

        MOVF    SET_TMP, W
        CALL    LIMIT_99
        MOVWF   SETPOINT

        MOVLW   d'1'
        MOVWF   HAS_SETPOINT       ; ya se recibio setpoint valido

        CLRF    RX_FLAG
        RETURN

; ============================================================
; SET_TMP = SET_TMP * 10 + DIGITO
; ============================================================

MULT10_ADD_DIGIT:
        BANKSEL SET_TMP

        MOVF    SET_TMP, W
        MOVWF   AUX1

        ; AUX1 = 2 * SET_TMP
        BCF     STATUS, C
        RLF     AUX1, F

        MOVF    SET_TMP, W
        MOVWF   AUX2

        ; AUX2 = 8 * SET_TMP
        BCF     STATUS, C
        RLF     AUX2, F
        BCF     STATUS, C
        RLF     AUX2, F
        BCF     STATUS, C
        RLF     AUX2, F

        ; W = 10 * SET_TMP
        MOVF    AUX2, W
        ADDWF   AUX1, W

        ; W = 10 * SET_TMP + DIGITO
        ADDWF   DIGITO, W
        MOVWF   SET_TMP

        RETURN

; ============================================================
; ENVIAR ESTADO POR UART
; Formato:
; S=70;T=25;R=1
; ============================================================

ENVIAR_ESTADO:
        MOVLW   'S'
        CALL    TX_CHAR
        MOVLW   '='
        CALL    TX_CHAR

        BANKSEL SETPOINT
        MOVF    SETPOINT, W
        CALL    TX_DEC2

        MOVLW   ';'
        CALL    TX_CHAR
        MOVLW   'T'
        CALL    TX_CHAR
        MOVLW   '='
        CALL    TX_CHAR

        BANKSEL TEMP_C
        MOVF    TEMP_C, W
        CALL    TX_DEC2

        MOVLW   ';'
        CALL    TX_CHAR
        MOVLW   'R'
        CALL    TX_CHAR
        MOVLW   '='
        CALL    TX_CHAR

        BANKSEL RELAY_STATE
        MOVF    RELAY_STATE, W
        ADDLW   '0'
        CALL    TX_CHAR

        MOVLW   d'13'
        CALL    TX_CHAR
        MOVLW   d'10'
        CALL    TX_CHAR

        RETURN

TX_INICIO:
        MOVLW   'L'
        CALL    TX_CHAR
        MOVLW   'I'
        CALL    TX_CHAR
        MOVLW   'S'
        CALL    TX_CHAR
        MOVLW   'T'
        CALL    TX_CHAR
        MOVLW   'O'
        CALL    TX_CHAR
        MOVLW   d'13'
        CALL    TX_CHAR
        MOVLW   d'10'
        CALL    TX_CHAR
        RETURN

; ============================================================
; TX_CHAR
; ============================================================

TX_CHAR:
        BANKSEL TXTEMP
        MOVWF   TXTEMP

WAIT_TX:
        BANKSEL PIR1
        BTFSS   PIR1, 4            ; TXIF
        GOTO    WAIT_TX

        BANKSEL TXTEMP
        MOVF    TXTEMP, W

        BANKSEL TXREG
        MOVWF   TXREG

        RETURN

; ============================================================
; TX_DEC2
; Envia numero 0..99 como dos digitos
; 7  -> 07
; 70 -> 70
; ============================================================

TX_DEC2:
        CALL    LIMIT_99
        CALL    NUM_TO_2DIG

        BANKSEL TENS
        MOVF    TENS, W
        ADDLW   '0'
        CALL    TX_CHAR

        BANKSEL UNITS
        MOVF    UNITS, W
        ADDLW   '0'
        CALL    TX_CHAR

        RETURN

; ============================================================
; DELAY ADC
; ============================================================

DELAY_ADC:
        BANKSEL D1
        MOVLW   d'30'
        MOVWF   D1

DADC_LOOP:
        DECFSZ  D1, F
        GOTO    DADC_LOOP

        RETURN

        END

