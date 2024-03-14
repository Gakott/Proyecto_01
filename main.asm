//******************************************************************************
//Universidad del Valle de Guatemala
//Programacion de Microcontroladres 
//Proyecto_01.asm
//Hardware: ATMega328P
//Author : Fernando Gabriel Caballeros
//Creado: 02/03/2024
//******************************************************************************
//Encabezado
//******************************************************************************
.include "M328PDEF.inc"    
.cseg					//INICIO DEL CODIGO
.org 0x00				//RESET
	JMP Main
.org 0x0008				// VECTOR ISR : PCINT1
	JMP ISR_PCINT1
.org 0x001A				// VECTOR ISR : TIMER1_OVF
	JMP ISR_TIMER_OVF1
.org 0x0020				// VECTOR ISR : TIMER0_OVF
	JMP ISR_TIMER_OVF0
	
Main:
//******************************************************************************
//STACK
//******************************************************************************
LDI R16, LOW(RAMEND)
OUT SPL, R16 
LDI R17, HIGH(RAMEND)
OUT SPH, R17
//******************************************************************************
//CONFIGURACION
//******************************************************************************
Setup:
	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16 			//HABILITAMOS EL PRESCALER
	LDI R16, 0b0000_0100
	STS CLKPR, R16			//DEFINIMOS UNA FRECUENCIA DE 4MGHz
	
	//PULLUPS
	LDI R16, 0b0000_0011	//PUERTO C
	OUT PORTC, R16

	LDI R16, 0b0001_0001	//PUERTO B
	OUT PORTB, R16		
		
	//Entragas y salidas
	LDI R16, 0b0011_1100
	OUT DDRC, R16			//PUERTO C

	LDI R16, 0xFF
	OUT DDRD, R16			//PUERTO D

	LDI R16, 0b0010_1110
	OUT DDRB, R16			//PUERTO B

	LDI R16, (0 << RXEN0) | (0 << TXEN0) //DESHABILITAR TX Y RX
    STS UCSR0B, R16

	CLR R16
	LDI R16, (1 << PCIE1)
	STS PCICR, R16			//CONFIGURAMOS PCIE1

	CLR R16
	LDI R16, (1 << PCINT10) | (1 << PCINT11) | (1 << PCINT12) | (1 << PCINT13)
	STS PCMSK1, R16		//HABILITAR INTERRUPCIONES

	CLR R16
	LDI R16, (1 << TOIE0)
	STS TIMSK0, R16			//HABILITAR INTERRUPCION PARA TIMER0 (OVERFLOW)

	LDI R16, (1 << TOIE1)
	STS TIMSK1, R16			//HABILITAR INTERRUPCION PARA TIMER1 (OVERFLOW)
		
	//LSO TIMER SE HARAN DE MODO NORMAL
	//TIMER1
	CLR R16
	STS TCCR1A, R16		

	CLR R16
	LDI R16, (1 << CS12 | 1 << CS10)
	STS TCCR1B, R16 			//PRESCALAR 1024

	//LDI R16, 0x1B				//VALOR EN DONDE INICIAR
	LDI R16, 0xFF				//VALOR EN DONDE INICIAR
	STS TCNT1H, R16
	//LDI R16, 0x1E				//VALOR EN DONDE INICIAR
	LDI R16, 0xFF				//VALOR EN DONDE INICIAR
	STS TCNT1L, R16

	//TIMER0
	CLR R16
	OUT TCCR0A, R16

	CLR R16
	LDI R16, (1 << CS02 | 1 << CS00)
	OUT TCCR0B, R16				//PRESCALAR 1024

	LDI R16, 251				//VALOR EN DONDE INICIAR
	OUT TCNT0, R16

	SEI						//INTERRUPCIONES GLOBALES SIE

	TABLA7SEG: .DB 0x40, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10, 0x08, 0x03, 0x46, 0x21, 0x06, 0x0E 
	
	LDI ZH, HIGH(TABLA7SEG << 1)
	LDI ZL, LOW(TABLA7SEG << 1)
	MOV R21, ZL
	MOV R25, ZL
	MOV R26, ZL
	MOV R27, ZL
	LDI R16, 1
	MOV R28, ZL
	ADD R28, R16
	MOV R29, ZL
	MOV R23, ZL
	ADD R23, R16
	MOV R18, ZL
	STS 0x0100, ZL
	STS 0x0101, ZL
	STS 0x0102, ZL
	STS 0x0103, ZL
	LPM R19, Z
	OUT PORTD, R19

	CLR R16
	CLR R17
	CLR R20
	CLR R22
	CLR R24
	
	SBI PORTC, PC2
	SBI PORTC, PC3
	SBI PORTC, PC4
	SBI PORTC, PC5
Loop:	
	CPI R22, 0
	BREQ reloj
	CPI R22, 1
	BREQ config_r_h
	CPI R22, 2
	BREQ config_r_min
	CPI R22, 3
	BREQ fecha
	CPI R22, 4
	BREQ config_f_dia
	CPI R22, 5
	BREQ config_f_mes
	RJMP Loop

reloj:
	CBI PORTB, PB2
	SBI PORTB, PB3
	SBRS R24, 3
	CPI R20, 1
	BREQ p_confirmar
	CPI R20, 2
	BREQ p_min_u
	RJMP Loop

config_r_h:
	CPI R20, 1
	BREQ p_confirmar
	SBRC R24, 0
	RJMP p_hora_u
	SBRC R24, 1
	RJMP p_dec_hora_u
	RJMP Loop

config_r_min:
	CPI R20, 1
	BREQ p_confirmar
	SBRC R24, 0
	RJMP p_min_u
	SBRC R24, 1
	RJMP p_dec_min_u
	RJMP Loop

fecha:
	SBI PORTB, PB2
	CBI PORTB, PB3
	SBRS R24, 3
	CPI R20, 1
	BREQ p_confirmar_f
	CPI R20, 2
	BREQ p_min_u
	RJMP Loop

config_f_dia:
	CPI R20, 1
	BREQ p_confirmar_f
	SBRC R24, 0
	RJMP p_dia_u
	SBRC R24, 1
	RJMP p_dec_dia_u
	RJMP Loop

config_f_mes:
	CPI R20, 1
	BREQ p_confirmar_f
	SBRC R24, 0
	RJMP p_mes_u
	SBRC R24, 1
	RJMP p_dec_mes_u
	RJMP Loop

//P-puentes
p_min_u:
	RJMP min_u
p_confirmar:
	RJMP display1_r
p_hora_u:
	RJMP hora_u
p_dec_hora_u:
	RJMP dec_hora_u
p_dec_min_u:
	RJMP dec_min_u
p_confirmar_f:
	RJMP display1_f

//******************************************************************************
//SUB-RUTINAS
//******************************************************************************
//RELOJ
	//MULTIPLEXEADO
display1_r:					
	CLR R20
	SBIS PORTC, PC2
	RJMP display2_r
	RJMP unidades_hora
display2_r:
	SBIS PORTC, PC3
	RJMP display3_r
	RJMP decenas_minuto
display3_r:
	SBIS PORTC, PC4
	RJMP decenas_hora
	RJMP unidades_minuto

unidades_minuto:
	CBI PORTC, PC2
	CBI PORTC, PC3
	CBI PORTC, PC4
	SBI PORTC, PC5
	MOV ZL, R21
	LPM R19, Z
	CPI R22, 2
	BREQ pip
	RJMP display7
decenas_minuto:
	CBI PORTC, PC2
	CBI PORTC, PC3
	SBI PORTC, PC4
	CBI PORTC, PC5
	MOV ZL, R25
	LPM R19, Z
	CPI R22, 2
	BREQ pip
	RJMP display7
unidades_hora:
	CBI PORTC, PC2
	SBI PORTC, PC3
	CBI PORTC, PC4
	CBI PORTC, PC5
	MOV ZL, R26
	LPM R19, Z
	CPI R22, 1
	BREQ pip
	RJMP display7
	
decenas_hora:
	SBI PORTC, PC2
	CBI PORTC, PC3
	CBI PORTC, PC4
	CBI PORTC, PC5
	MOV ZL, R27
	LPM R19, Z
	CPI R22, 1
	BREQ pip
	RJMP display7

pip:
	SBRS R24, 2
	RJMP ap_multi
	RJMP display7
ap_multi:
	CLR R19
	RJMP display7

	//CONFIGURACION DEL RELOJ

min_u:
	CLR R20
	CBR R24, 0000_0001
	INC R21
	MOV ZL, R21
	LPM R19, Z
	CPI R19, 0x08
	BREQ reset_min_unid
	RJMP Loop

reset_min_unid:
	LDI R21, LOW(TABLA7SEG << 1)
	RJMP min_dec
	
min_dec: 
	INC R25
	MOV ZL, R25
	LPM R19, Z
	CPI R19, 0x02
	BREQ reset_min_dec
	RJMP Loop

reset_min_dec:
	LDI R25, LOW(TABLA7SEG << 1)
	CPI R22, 0
	BREQ hora_u
	CPI R22, 3
	BREQ hora_u
	RJMP Loop

hora_u:
	CBR R24, 0b0000_0001
	INC R26
	MOV ZL, R27
	LPM R19, Z
	CPI R19, 0x24
	BREQ reset_hora_u2
	RJMP reset_hora_u1

reset_hora_u2:
	MOV ZL, R26
	LPM R19, Z
	CPI R19, 0x19
	BREQ reset_hora_unid
	RJMP Loop

reset_hora_u1:
	MOV ZL, R26
	LPM R19, Z
	CPI R19, 0x08
	BREQ reset_hora_unid
	RJMP Loop
reset_hora_unid:
	LDI R26, LOW(TABLA7SEG << 1)
	RJMP hora_dec

hora_dec:  
	INC R27
	MOV ZL, R27
	LPM R19, Z
	CPI R19, 0x30
	BREQ rst_hora_dec
	RJMP Loop
rst_hora_dec:
	LDI R27, LOW(TABLA7SEG << 1)
	CPI R22, 0
	BREQ p_dia_u
	CPI R22, 3
	BREQ p_dia_u
	RJMP Loop

dec_hora_u:
	CBR R24, 0b0000_0010
	MOV ZL, R26
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_hora_u
	DEC R26
	RJMP Loop
reset_dec_hora_u:
	MOV ZL, R27
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_hora_u2
	RJMP reset_dec_hora_u1
reset_dec_hora_u2:
	LDI R16, 3
	LDI R26, LOW(TABLA7SEG << 1)
	ADD R26, R16
	RJMP dec_hora_dec
reset_dec_hora_u1:
	LDI R16, 9
	LDI R26, LOW(TABLA7SEG << 1)
	ADD R26, R16
	RJMP dec_hora_dec

dec_hora_dec:  
	MOV ZL, R27
	LPM R19, Z
	CPI R19, 0x40
	BREQ rst_dec_hora_dec
	DEC R27
	RJMP Loop
rst_dec_hora_dec:
	LDI R16, 2
	LDI R27, LOW(TABLA7SEG << 1)
	ADD R27, R16
	RJMP Loop

dec_min_u:
	CBR R24, 0b0000_0010
	MOV ZL, R21
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_min_unid
	DEC R21
	RJMP Loop
reset_dec_min_unid:
	LDI R16, 9
	LDI R21, LOW(TABLA7SEG << 1)
	ADD R21, R16
	RJMP dec_min_dec

dec_min_dec:  
	MOV ZL, R25
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_min_dec
	DEC R25
	RJMP Loop
reset_dec_min_dec:
	LDI R16, 5
	LDI R25, LOW(TABLA7SEG << 1)
	ADD R25, R16
	RJMP Loop
//P-puentes
p_pip:
	RJMP pip
p_dia_u:
	RJMP dia_u
p_dec_dia_u:
	RJMP dec_dia_unid
p_mes_u:
	RJMP mes_unid
p_dec_mes_u:
	RJMP dec_mes_u
;----------Multiplexado fecha----------
display1_f: //revisa cual display está encendido
	CLR R20
	SBIS PORTC, PC2
	RJMP display2_f
	RJMP unidades_dia
display2_f:
	SBIS PORTC, PC3
	RJMP display3_f
	RJMP decenas_mes
display3_f:
	SBIS PORTC, PC4
	RJMP decenas_dia
	RJMP unidades_mes

unidades_mes:
	CBI PORTC, PC2
	CBI PORTC, PC3
	CBI PORTC, PC4
	SBI PORTC, PC5
	MOV ZL, R28
	LPM R19, Z
	CPI R22, 5
	BREQ p_pip
	RJMP display7
decenas_mes:
	CBI PORTC, PC2
	CBI PORTC, PC3
	SBI PORTC, PC4
	CBI PORTC, PC5
	MOV ZL, R29
	LPM R19, Z
	CPI R22, 5
	BREQ p_pip
	RJMP display7
unidades_dia:
	CBI PORTC, PC2
	SBI PORTC, PC3
	CBI PORTC, PC4
	CBI PORTC, PC5
	MOV ZL, R23
	LPM R19, Z
	CPI R22, 4
	BREQ p_pip
	RJMP display7
	
decenas_dia:
	SBI PORTC, PC2
	CBI PORTC, PC3
	CBI PORTC, PC4
	CBI PORTC, PC5
	MOV ZL, R18
	LPM R19, Z
	CPI R22, 4
	BREQ p_pip
	RJMP display7

;******************************************************************************
//DISPLAY Y LOS PUNTOS INTERMEDIOS
display7: 
	SBIS PORTD, PD7
	RJMP off_pts
	RJMP on_pts
on_pts:
	OUT PORTB, R19
	SBI PORTD, PD7
	RJMP punTOS_int
off_pts:
	OUT PORTD, R19
	CBI PORTD, PD7
	RJMP puntos_int

puntos_INT:							//LEDS ENTRE LOS DISPLAYS
	CPI R17, 100
	BREQ act_puntos
	INC R17
	RJMP Loop
act_puntos:
	CLR R17
	SBIS PORTB, PB1
	RJMP on_puntos
	RJMP off_puntos
on_puntos:
	SBRC R24, 3
	SBI PORTB, PB5
	CBR R24, 0b0000_0100
	SBI PORTB, PB1
	CPI R22, 1
	BREQ off_led1
	CPI R22, 2
	BREQ off_led1
	CPI R22, 4
	BREQ off_led2
	CPI R22, 5
	BREQ off_led2
	RJMP Loop
on_led1:
	SBI PORTB, PB3
	RJMP Loop
on_led2:
	SBI PORTB, PB2
	RJMP Loop
off_puntos:
	SBR R24, 0b0000_0100
	CBI PORTB, PB1
	CPI R22, 1
	BREQ on_led1
	CPI R22, 2
	BREQ on_led1
	CPI R22, 4
	BREQ on_led2
	CPI R22, 5
	BREQ on_led2
	RJMP Loop
off_led1:
	CBI PORTB, PB3
	RJMP Loop
off_led2:
	CBI PORTB, PB2
	RJMP Loop

//FECHA
dia_u:
	CBR R24, 0b0000_0001
	INC R23
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x40
	BREQ meses_sin_dec
	RJMP meses_con_dec
meses_sin_dec:				//meses del enero a septiembre
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x79 
	BREQ dias31
	CPI R19, 0x24
	BREQ dias28
	CPI R19, 0x30 
	BREQ dias31
	CPI R19, 0x19
	BREQ dias30
	CPI R19, 0x12
	BREQ dias31
	CPI R19, 0x02
	BREQ dias30
	CPI R19, 0x78
	BREQ dias31
	CPI R19, 0x00
	BREQ dias31
	CPI R19, 0x10
	BREQ dias30
meses_con_dec:		//meses de octubre a diciembre
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x40
	BREQ dias31
	CPI R19, 0x79
	BREQ dias30
	CPI R19, 0x24
	BREQ dias31
//configuracion de los dias 28, 30, 31
dias28:
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x24
	BREQ reset_dias28
	RJMP reset_dia28
reset_dias28:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x79
	BREQ reset_dia_unid
	RJMP Loop
reset_dia28:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x08
	BREQ reset_dia_unid0
	RJMP Loop
	
dias30:
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x30
	BREQ reset_dias30
	RJMP reset_dia30
reset_dias30:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x79
	BREQ reset_dia_unid
	RJMP Loop
reset_dia30:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x08
	BREQ reset_dia_unid0
	RJMP Loop

dias31:
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x30
	BREQ reset_dias31
	RJMP reset_dia31
reset_dias31:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x24
	BREQ reset_dia_unid
	RJMP Loop
reset_dia31:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x08
	BREQ reset_dia_unid0
	RJMP Loop

reset_dia_unid0:
	LDI R23, LOW(tabla7seg << 1)
	RJMP dia_dec

reset_dia_unid:
	LDI R16, 1
	LDI R23, LOW(tabla7seg << 1)
	ADD R23, R16
	RJMP dia_dec
	
dia_dec: 
	INC R18
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x40
	BREQ meses_primeros
	RJMP dias_3
meses_primeros:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x24
	BREQ dias_2
	RJMP dias_3

dias_2:				//dias que no llegan a mas de 2 decenas de dias
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x30
	BREQ reset_dia_dec
	RJMP Loop
dias_3:				//dias que no llegan a mas de 3 decenas de dias
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x19
	BREQ reset_dia_dec
	RJMP Loop

reset_dia_dec:
	LDI R18, LOW(tabla7seg << 1)
	CPI R22, 3
	BREQ mes_unid
	RJMP Loop

mes_unid:
	CBR R24, 0b0000_0001
	INC R28
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x79
	BREQ reset_mes_u1
	RJMP reset_mes_u0
reset_mes_u1:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x30
	BREQ reset_mes_u
	RJMP Loop
reset_mes_u0:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x08
	BREQ reset_mes_u00
	RJMP Loop
reset_mes_u:
	LDI R16, 1
	LDI R28, LOW(tabla7seg << 1)
	ADD R28, R16
	RJMP mes_dec
reset_mes_u00:
	LDI R28, LOW(tabla7seg << 1)
	RJMP mes_dec

mes_dec:  
	INC R29
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x24
	BREQ reset_mes_dec
	RJMP Loop
reset_mes_dec:
	LDI R29, LOW(tabla7seg << 1)
	RJMP Loop

dec_dia_unid:
	CBR R24, 0b0000_0010
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_dia_u31
	RJMP reset_dec_dia_u30

reset_dec_dia_u31:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x79
	BREQ reset_dec_dia_unid
	DEC R23
	RJMP Loop

reset_dec_dia_u30:
	MOV ZL, R23
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_dia_unid_normal
	DEC R23
	RJMP Loop

reset_dec_dia_unid_normal:
	LDI R16, 9
	LDI R23, LOW(tabla7seg << 1)
	ADD R23, R16
	RJMP dec_dia_dec

reset_dec_dia_unid:
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x40
	BREQ dec_meses_sin_dec
	RJMP dec_meses_con_dec

dec_meses_sin_dec:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x79 
	BREQ dec_dias31
	CPI R19, 0x24
	BREQ dec_dias28
	CPI R19, 0x30 
	BREQ dec_dias31
	CPI R19, 0x19
	BREQ dec_dias30
	CPI R19, 0x12
	BREQ dec_dias31
	CPI R19, 0x02
	BREQ dec_dias30
	CPI R19, 0x78
	BREQ dec_dias31
	CPI R19, 0x00
	BREQ dec_dias31
	CPI R19, 0x10
	BREQ dec_dias30
dec_meses_con_dec:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x79
	BREQ dec_dias30
	CPI R19, 0x40
	BREQ dec_dias31
	CPI R19, 0x24
	BREQ dec_dias31

dec_dias28:
	LDI R16, 8
	LDI R23, LOW(tabla7seg << 1)
	ADD R23, R16
	RJMP dec_dia_dec

dec_dias30:
	LDI R16, 1
	LDI R23, LOW(tabla7seg << 1)
	ADD R23, R16
	RJMP dec_dia_dec

dec_dias31:
	RJMP dec_dia_dec
	

dec_dia_dec:  
	MOV ZL, R18
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_dia_dec
	DEC R18
	RJMP Loop

reset_dec_dia_dec:
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_dia28_dec
	RJMP reset_dec_dia30

reset_dec_dia28_dec:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x24
	BREQ reset_dec_dia_dec_mes02
	RJMP reset_dec_dia30

reset_dec_dia30:
	LDI R16, 3
	LDI R18, LOW(tabla7seg << 1)
	ADD R18, R16
	RJMP Loop
reset_dec_dia_dec_mes02:
	LDI R16, 2
	LDI R18, LOW(tabla7seg << 1)
	ADD R18, R16
	RJMP Loop

dec_mes_u:
	CBR R24, 0b0000_0010
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_mes_u0
	RJMP reset_dec_mes_u1
reset_dec_mes_u0:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x79
	BREQ reset_dec_mes_u00
	DEC R28
	RJMP Loop
reset_dec_mes_u1:
	MOV ZL, R28
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_mes_u11
	DEC R28
	RJMP Loop
reset_dec_mes_u00:
	LDI R16, 2
	LDI R28, LOW(tabla7seg << 1)
	ADD R28, R16
	RJMP dec_mes_dec
reset_dec_mes_u11:
	LDI R16, 9
	LDI R28, LOW(tabla7seg << 1)
	ADD R28, R16
	RJMP dec_mes_dec

dec_mes_dec:  
	MOV ZL, R29
	LPM R19, Z
	CPI R19, 0x40
	BREQ reset_dec_mes_dec
	DEC R29
	RJMP Loop
reset_dec_mes_dec:
	LDI R16, 1
	LDI R29, LOW(tabla7seg << 1)
	ADD R29, R16
	RJMP Loop

//******************************************************************************

ISR_PCINT1:
	PUSH R16
	IN R16, PINB
	SBRS R16, PB4	
	RJMP DelayBounce_1

	CPI R22, 1
	BREQ inc_dec
	CPI R22, 2
	BREQ inc_dec
	CPI R22, 4
	BREQ inc_dec
	CPI R22, 5
	BREQ inc_dec
	CPI R22, 6
	BREQ inc_dec
	CPI R22, 7
	BREQ inc_dec

	BCLR 1
	POP R16
	RETI

	inc_dec:
	BCLR 1
	IN R16, PINC
	SBRS R16, PC1	
	RJMP DelayBounce_3
	IN R16, PINC
	SBRS R16, PC0	
	RJMP DelayBounce_2
	POP R16
	RETI
	
fase:
	CPI R22, 5
	BREQ reset_fase
	INC R22
	POP R16
	RETI
reset_fase:
	CLR R22
	BCLR 1
	POP R16
	RETI
incrementar:
	SBR R24, 0b0000_0001
	POP R16
	RETI
decrementar:
	SBR R24, 0b0000_0010
	POP R16
	RETI

ISR_TIMER_OVF0:
	PUSH R16
	LDI R16, 251 
	OUT TCNT0, R16
	POP R16
	LDI R20, 1
	RETI

	
ISR_TIMER_OVF1:
	PUSH R16
	//LDI R16, 0x1B 
	LDI R16, 0xFF
	STS TCNT1H, R16
	//LDI R16, 0x1E 
	LDI R16, 10
	STS TCNT1L, R16
	POP R16
	LDI R20, 2
	RETI

DelayBounce_1:
	LDI R16, 100
	Ldelay:
		dec R16
		brne Ldelay
	SBIS PINB, PB4
	RJMP DelayBounce_1
	rjmp fase
	
DelayBounce_2:
	LDI R16, 100
	Delay_2:
		DEC R16
		BRNE Delay_2
	SBIS PINC, PC0
	RJMP DelayBounce_2
	rjmp incrementar
	
DelayBounce_3:
	LDI R16, 100
	Delay_3:
		DEC R16
		BRNE Delay_3
	SBIS PINC, PC1
	RJMP DelayBounce_3
	RJMP decrementar