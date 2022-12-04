;
; Lab1_1.asm
;
; Created: 27/09/2022 10:29:10 p. m.


;====================================================================
; DEFINICIONES INICIALES
;====================================================================     

			.DEF TEMP 	= R16	; REGISTRO TEMPORAL
			.DEF TEMP1 	= R17	; REGISTRO TEMPORAL 1
			.DEF TEMP2	= R18	; REGISTRO TEMPORAL 2 
			.DEF TIMERL = R19	; REGISTRO PRECARGA LOW
			.DEF TIMERH = R20	; REGISTRO PRECARGA HIGH
			.DEF FORM	= R21	; CONTADOR FORMA
			.DEF TIME   = R22	; CONTADOR TIEMPOS


;====================================================================
; VECTORES DE INTERRUPCION
;====================================================================     
			
			.ORG		0x0000 
			JMP 		Inicio				; Inicio/Reset

			.ORG		0x0002 
			JMP 		Int_Externa0		; Cambio de señal

			.ORG		0x0004 
			JMP 		Int_Externa1		; Cambio de Periodo

			.ORG 		0x0028
			JMP 		InterrupcionT1		; Desbordamiento del Timer 1

;====================================================================
; Vector de valores para cada señal
;====================================================================

TABLE1:		.DB			128, 161, 191, 218, 238, 251, 251, 238, 218, 191, 161, 128, 95, 64, 37, 17, 4, 0, 4, 17, 37, 64, 95, 128		; Seno

TABLE2:		.DB			255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0					; Cuadrada

TABLE3:		.DB			0, 21, 43, 64, 85, 106, 128, 149, 191, 213, 234, 255, 255, 234, 213, 191, 149, 128, 106, 85, 64, 43, 21, 0		; Triangular

TABLE4:		.DB					; Diente Sierra


;====================================================================
; PROGRAMA
;====================================================================

Inicio:

;====================================================================
; CONFIGURACIÓN DE PERIFÉRICOS: PUERTOS A y B
;====================================================================

			LDI			TEMP,0xFF						; Valora el registro TEMP en 0xFF
			OUT			DDRB,TEMP						; Define el Puerto B como salida
			OUT			DDRA,TEMP						; Define el Puerto A como salida


			LDI			TEMP,0xFF						; Inicializa el valor del puerto B
			OUT			PORTB,TEMP						; en 0xFF


;====================================================================
; CONFIGURACIÓN DE PERIFÉRICOS: TIMER 1
;====================================================================

			; CONFIGURACIÓN DEL TIMER
			LDI			TIMERH,0xFD						; SE PRECARGA EL TIMER 1
			STS			TCNT1H,TIMERH					; CON 0xFD65
			LDI			TIMERL,0x65						; VALOR NECESARIO PARADESBORDAR 
			STS			TCNT1L,TIMERL					; a 41.67uSeg para conseguir un periodo de 1ms

			; CONFIGURACIÓN DEL PRESCALER
			LDI			TEMP,0<<CS12|0<<CS11|1<<CS10	; PRESCALER DE 1 (No preescaler)
			STS			TCCR1B,TEMP						; AQUÍ INICIA EL TIMER

;====================================================================
; HABILITAR INTERRUPCIONES INT0, TIMER 1 Y GLOBALES
;====================================================================	
			LDI			TEMP,1<<TOIE1			; Habilitación de INT_TIMER_1
			STS			TIMSK1,TEMP			

			LDI			TEMP,1<<INT0|1<<INT1	; Habilitación de INT_EXT0 E INT_EXT1
			OUT			EIMSK,TEMP				; EIMSK

			LDI			TEMP,0x0F				; Selecciona activación por cualquier flanco
			STS			EICRA,TEMP			

			SEI									; Habilitador global de interrupciones


;====================================================================
; PARÁMETROS INICIALES
;====================================================================	

			LDI			FORM, 0xFF				; Contador de Señal Inicial en Seno
			LDI			TIME, 0xFF				; Contador de Periodo Inicial en 1ms
			LDI			TEMP2, 24				; Contador de datos por recorrer en la señal en la cantidad máxima de datos (24)

			LDI			ZL,LOW(TABLE1<<1)		; Iniciar apuntador Z
			LDI			ZH,HIGH(TABLE1<<1)		; en la señal Seno

			LDI			TIMERH,0xFD				; Iniciar Timer
			LDI			TIMERL,0x65				; en el periodo de 1ms

;====================================================================
; BUCLE INFINITO: LOOP
;====================================================================	

BUCLE:      NOP
			JMP			BUCLE				; BUCLE INFINITO

;=================================================================================
; Subrutina de Atención a la Interrupción del Timer 1 => Desbordamiento del Timer
;=================================================================================

InterrupcionT1:

			STS			TCNT1L,TIMERL		; Reiniciar el
			STS			TCNT1H,TIMERH		; Timer tras el desbordamiento

			LPM			TEMP1, Z			; Obtener el valor del vector de señales
			OUT			PORTB, TEMP1		; Escribirlo en el puerto B
			INC			ZL					; Alistar el próximo valor del vector de señales

			DEC			TEMP2				; Decrementar el contador de datos por recorrer
		    BREQ		Repetir				; Si este es igual, saltar a Repetir, si no, continuar el código 

FinRep:		

			RETI							; Salida de la subrutina de Interrupción


Repetir:	SUBI		ZL, 24				; Restar a la posición en el vector de señales 24 (resetear el apuntador)
			LDI			TEMP2, 24			; Reinicia el contador de datos por recorrer en 24
			JMP			FinRep				; Saltar a FinRep

;===============================================================================
; Subrutina de Atención a la Interrupción Externa 0 => Cambio Forma de la Señal
;===============================================================================

Int_Externa0:

			INC			FORM						; Incrementar el contador de forma

SENO:		CPI			FORM,0						; Comparar el contador de forma con 0
			BRNE		CUADRADA					; Saltar a Cuadrada en caso de no ser igual
			
			LDI			ZL,LOW(TABLE1<<1)			; Establecer el apuntador Z
			LDI			ZH,HIGH(TABLE1<<1)			; en el vector de datos de la Seno
			JMP			F_SALIR						; Salta a F_Salir

CUADRADA:	CPI			FORM,1						; Comparar el contador de forma con 1
			BRNE		TRIANGULO					; Saltar a Triangulo en caso de no ser igual
			
			LDI			ZL,LOW(TABLE2<<1)			; Establecer el apuntador Z
			LDI			ZH,HIGH(TABLE2<<1)			; en el vector de datos de la Cuadrada
			JMP			F_SALIR						; Salta a F_Salir

TRIANGULO:	CPI			FORM,2						; Comparar el contador de forma con 2
			BRNE		SIERRA						; Saltar a Sierra en caso de no ser igual
			
			LDI			ZL,LOW(TABLE3<<1)			; Establecer el apuntador Z
			LDI			ZH,HIGH(TABLE3<<1)			; en el vector de datos de la Triangular
			JMP			F_SALIR						; Salta a F_Salir

SIERRA:		CPI			FORM,3						; Comparar el contador de forma con 3
			BRNE		F_OTROS						; Saltar a F_Otros en caso de no ser igual
			
			LDI			ZL,LOW(TABLE4<<1)			; Establecer el apuntador Z
			LDI			ZH,HIGH(TABLE4<<1)			; en el vector de datos de la Diente de sierra
			JMP			F_SALIR						; Salta a F_Salir

F_OTROS:	CLR			FORM						; Limpiar el contador de forma (ponerlo en 0, para reiniciar el ciclo)
			JMP			Seno						; Saltar a Seno para reiniciar su ciclo
			
F_SALIR:	LDI			TEMP2, 24					; Reinicia el contador de datos por recorrer en 24

			RETI									; Salida de la Subrutina de cambio de forma de la señal

;===============================================================================
; Subrutina de Atención a la Interrupción Externa 1 => Cambio Tiempo de Periodo
;===============================================================================

Int_Externa1:

			INC			TIME				; Incrementa el contador de tiempo (Periodo)

MS1:		CPI			TIME,0				; Compara el contador de tiempo con 0
			BRNE		MS5					; Salta a MS5 en caso de no ser igual

			LDI			TIMERH,0xFD			; Carga las variables del timer con
			LDI			TIMERL,0x65			; 0xFD65 equivalentes a 41.67us para un periodo de 1ms
			JMP			T_SALIR				; Salta a T_Salir

MS5:		CPI			TIME,1				; Compara el contador de tiempo con 1
			BRNE		MS10				; Salta a MS10 en caso de no ser igual

			LDI			TIMERH,0xF2			; Carga las variables del timer con
			LDI			TIMERL,0xFB			; 0xF2FB equivalentes a 208.3us para un periodo de 5ms
			JMP			T_SALIR				; Salta a T_Salir

MS10:		CPI			TIME,2				; Compara el contador de tiempo con 2
			BRNE		MS15				; Salta a MS15 en caso de no ser igual
			
			LDI			TIMERH,0xE5			; Carga las variables del timer con
			LDI			TIMERL,0xF5			; 0xE5F5 equivalentes a 416.7us para un periodo de 10ms
			JMP			T_SALIR				; Salta a T_Salir

MS15:		CPI			TIME,3				; Compara el contador de tiempo con 3
			BRNE		T_OTROS				; Salta a T_Otros en caso de no ser igual
			
			LDI			TIMERH,0xD8			; Carga las variables del timer con
			LDI			TIMERL,0xF0			; 0xD8F0 equivalentes a 625us para un periodo de 15ms
			JMP			T_SALIR				; Salta a T_Salir

T_OTROS:	CLR			TIME				; Limpia el contador de tiempo, para reiniciar su ciclo
			JMP			MS1					; Saltar a MS1 para reiniciar el ciclo
			
T_SALIR:	

			RETI							; Salida de la Subrutina de cambio de periodo de la señal


;======================================================================
; FIN DEL PROGRAMA
;======================================================================
