.8086
.MODEL SMALL
.STACK 100H

.DATA

;	 ____   _    ____      _    __  __ _____ _____ ____   ___  ____  
;	|  _ \ / \  |  _ \    / \  |  \/  | ____|_   _|  _ \ / _ \/ ___| 
;	| |_) / _ \ | |_) |  / _ \ | |\/| |  _|   | | | |_) | | | \___ \ 
;	|  __/ ___ \|  _ <  / ___ \| |  | | |___  | | |  _ <| |_| |___) |
;	|_| /_/   \_\_| \_\/_/   \_\_|  |_|_____| |_| |_| \_\\___/|____/   
;
;	Los parametros debajo dictan el comportamiento y el cálculo del juego.
;	El orden en el que estan es MUY importante (se referencian con un solo label).
;	Se pueden cambiar pero hay algunas reglas generales (detalladas debajo).

	
	GAME_MODE			DB 	00H 	; 00H Default, 01H Debug, 02H Trail.

	FRAMEWORK LABEL WORD

;  ╔»													   			    «╗
;  ║		 Tamaño de la pantalla. Fijo para el modo de video 13H.	 	 ║
;  ╚»                                                       	 	    «╝
	SCREEN_WIDTH		DW	320
	SCREEN_HEIGHT		DW	200

;Constantes.

	FLOOR_HEIGHT		DW	160		; 200 es el margen inferior de la pantalla.

	ACCELERATION		DW	3		; Aceleración de la gravedad.

	FRICTION			DW	3		; Constante de rozamiento con el suelo.

	;--------------------------------------------------------------------;
	; 					  CONSTANTES ESPECIFICAS						 ;
	;--------------------------------------------------------------------;
;  ╔»													   				«╗
;  ║					 Constantes de la pelota.	 	 				 ║
;  ╚»                                                       	 	    «╝
	BALL_SIZE			DW	12		; Tamaño de la pelota.

	MIN_VELOCITY_X		DW	-10		; Dictan las velocidades máximas y mínimas
	MAX_VELOCITY_X		DW	35		; que el usuario puede ingresar al usar la dirección.
	MIN_VELOCITY_Y		DW	10		; Se recomiendas usar multiplos de 2, 3, 5.
	MAX_VELOCITY_Y		DW	-35		; Y usar ese numero para el input.

	BALL_INERTIA		DW	8		; Inercia de la pelota. Implica como va a reaccionar la pelota
									; a la gravedad y los golpes. 0 inercia, la pelota no reacciona.
									; se recomienda valores como 4, 8, 16.

;  ╔»													   			    «╗
;  ║		 				 Constantes del aro.	 	 				 ║
;  ╚»                                                       	 	    «╝

;	A tener en cuenta; el aro tiene una particularidad con su posición y tamaño.
; 	El tamaño real del aro cuenta desde su posición hasta el final como:
;
;	(HOOP_X) + (HOOP_W) + (HOOP_BORDER) + (BALL_SIZE) + (TOLERANCE) + 2
;
;	Eso sería el largo real del aro contando todas sus partes.
;	El calculo sería el HOOP_X_MAXIMO = SCREEN_WIDTH - LARGOREAL

	HOOP_X				DW	240		; Posición del aro (X).		
	HOOP_Y				DW	70		; Posición del aro (Y).
	HOOP_WIDTH			DW	25		; Ancho del aro (zona para embocar).
	HOOP_HEIGHT			DW	23		; Alto del tablero.

	HOOP_BORDER			DW	4		; Borde con el que rebota la pelota, cuenta tanto el izquierdo
									; como el derecho (el único que es visual). Valores recomendados
									; menos de 6. Si es 0 el aro no tiene bordes y nunca rebota.

	TOLERANCE			DW	2		; Cuanto es el "angulo" que tolera por aproximación lineal.
									; Se puede interpretar como la dificultad.
									; Valores como 4,3,2 es muy tolerante. 1,0 justo, -1,-2 injusto.

	;--------------------------------------------------------------------;
	; 		 	   VARIABLES INTERNAS DE FUNCIONAMIENTO					 ;
	;--------------------------------------------------------------------;
	;	Son las variables que sirven para el calculo dentro de la lógica del juego.
	;	No hay necesidad de modificarlas, se sobreescriben constantemente, pero
	;	es bueno tener un seguimiento (para el debug).

									; Se pueden considerar como coordenadas iniciales.
	BALL_X				DW	0		; Posición (X) de la pelota, no tiene que ser nunca menor
									; a 0 ni tampoco mayor al SCREEN_WIDTH.
	BALL_Y				DW	0		; Posicion (Y) de la pelota, tiene que ser siempre:
									; (BALL_Y) <= (FLOOR) - (BALL_SIZE)
									; También da información de la posición en todo momento.

	BALL_CENTER			DW	0       ; El centro de la pelota, se calcula automaticamente (recordar).

	BALL_VELOCITY_X		DW	15		; Velocidades iniciales y en todo momento de la pelota.
	BALL_VELOCITY_Y		DW -10		; Aconsejable que inicie en el rango MAX/MIN.

	PREV_BALL_Y			DW	0		; Interno de la lógica, no hace falta modificarlo.
	PREV_BALL_X			DW	0		; Posición previa a la actual (en todo momento).

	GAMESTATE			DW 	0 		; 0:Esperando INPUT, 1:En ejecución. 2:Bola quieta, 3:Victoria en movimiento. 4:Victoria quieta

	HOOP_REAL_WIDTH		DW	0		; Se calcula automaticamente.

	PREV_PLAYERIN_X		DW	0		; Cursor del ajuste de velocidad previo (para limpiar)
	PREV_PLAYERIN_Y		DW	0

	TRAIL_ENABLED		DW	0		;Opción de trail de DRAW_SCENE, no tocar directo.
	TIMEAUX				DB	0		; Sistema de tiempo (no tocar).
	

;	-		-			-				-					-
;
;		ACÁ IRÍA LA INFO DEL GRUPO SUPONGO (PODRIA SER).
;
;	-		-			-				-					-
	
						
	;Table levels trabaja junto a otra función para validar cosas como por ejemplo que el
	;suelo actual coincida con la posición de la pelota.

	 
.CODE

;FUNCIONES DE CALIDAD DE VIDA:
	
	;En AX: Valor +/-. Devuelve en AX el valor absoluto.
	EXTRN ABSOLUTE:PROC
	;Limpia la pantalla, la primera vez setea el modo de video.
	EXTRN CLEAR_SCREEN:PROC
	EXTRN POLL_PLAYERINPUT:PROC
	EXTRN CALCULATE:PROC
	EXTRN DRAW_RECTANGLE:PROC
	;DRAW BALL: En AL color de la pelota (00H a 0FH).
	;El tamaño esta dado por los parámetros.
	EXTRN DRAW_BALL:PROC
	;DRAW SCENE: Dibuja la escena completa.
	EXTRN DRAW_SCENE:PROC
	;DEFINE: Define algunas de las constantes auxiliares del juego en especifico.
	EXTRN DEFINE_AUXILIARY_CONSTANTS:PROC
	EXTRN GENERATE_RANDOM_LEVEL:PROC
	EXTRN DRAW_HOOP:PROC
	EXTRN RANDOM_NUMBER:PROC

	;--------------------------------------------------------------------;
	;						 FUNCIONES DEL JUEGO		    			 ;
	;--------------------------------------------------------------------;
	; Esto es la parte funcional y lo que se comunica con el main.

	MAIN PROC
		MOV AX, @DATA
		MOV DS, AX

		LEA SI, FRAMEWORK	; GAMELOGIC funciona con SI apuntando al framework.
							; siempre asegurense de que SI este apuntando al framework
							; antes de usar una función de GAMELOGIC.

		CALL CLEAR_SCREEN	; SET al modo de video 13H, pone fondo negro.


;	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å 
;		
;	Å		FALTARÍA HACER UN MENU ACÁ DESPUES DEL MODO DE VIDEO Y ANTES			Å
;			DE QUE SIQUIERA EMPIECE EL JUEGO (NO SE ME OCURRE IGUAL MÁS)			
;	Å		PODRIA SER RANDOM PERO NECESITARIAMOS QUE RESPETE LOS LIMITES			Å
;			DE LAS VARIABLES.
;	Å																				Å
;
;	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å	Å

;	SUPONIENDO QUE DESPUES DEL MENU HAY UN ALGORITMO QUE GENERA NUMEROS RANDOM
; 	EN UN INTERVALO DADO QUE RESPETA LOS LIMITES DE LAS VARIABLES, SIGUE EL PROGRAMA
;	(AHORA ESTARIA USANDO LAS DEFAULT).
;	Y sino usamos una tabla de posibles valores y es mas fácil (creo).
;	Lo de la tabla podrian fijarse si hay alguna forma con archivos capáz.


		;Acá la función general que calcula las constantes auxiliares.
		;Constantes como el HOOP_REAL_WIDTH, y los minimos y maximos.
		;Por eso HOOP_X tiene que ir después de las constantes.
		
		;Recibe por STACK la dificultad incrementando de 0 a 4.
		;Algunas variables de la dificultad son fijas.
		
		WIN_JMP:
		CALL CLEAR_SCREEN
		PUSH 00H
		CALL GENERATE_RANDOM_LEVEL
		CALL DEFINE_AUXILIARY_CONSTANTS

		;Primera ejecución de la escena, dibuja todo asincronicamente.
		;Dibuja el piso y todo el resto de cosas (faltaria también cuando hagan los numeros en pantalla)   

		MOV AH, 00H
		CALL DRAW_SCENE
		MOV AL, 0FH
		CALL DRAW_BALL
		MOV AH, 02H
		MOV DH, 22
		MOV DL, 70

		;- - - - - - - - -	;
		GAME_CLOCK:			;
		MOV AH, 2CH			;
		INT 21H				;
		CMP DL, TIMEAUX		;
		JE GAME_CLOCK		;
		;- - - - - - - - -	;


		;0:Esperando INPUT, 1:En ejecución.
		;2:Bola quieta, 3:Victoria en movimiento. 
		;4:Victoria quieta (FINALIZADA)

		CMP GAMESTATE, 01H
		JE INGAME
		CMP GAMESTATE, 02H
		JE GAME_END
		CMP GAMESTATE, 03H
		JE INGAME
		CMP GAMESTATE, 04H
		JE GAME_WIN
		JMP STARTING
		GAME_WIN:
		MOV GAMESTATE, 00H
		MOV PREV_BALL_X, 00H
		MOV PREV_BALL_Y, 00H
		JMP WIN_JMP

		STARTING:
		;CALL DRAW_BALL
		CALL POLL_PLAYERINPUT ;(draw player input adentro? capaz)
		
		;CALL DRAW_SCENE
		;CALL DRAW_HOOP


		JMP CONTINUE_CLOCK

		INGAME:

		;CALL CLEAR_BALL

		CALL CALCULATE
		MOV AH, GAME_MODE     ;AH = 00H Default, 01H Debug, 02H Trail.
		CALL DRAW_SCENE
		MOV AL, 06H
		CALL DRAW_BALL
		CALL DRAW_HOOP


		CONTINUE_CLOCK:
		MOV TIMEAUX, DL
		JMP GAME_CLOCK
		GAME_END:

		MOV AX, 02H
		INT 10H


		MOV AX, 4C00H
		INT 21H
	MAIN ENDP
END