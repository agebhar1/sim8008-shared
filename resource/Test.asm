; Zahlensystem: Dezimal
; Pointer HL zeigt auf die zu invertierende Zahl im Speicher
; die Stelle des zu invertierenden Bits liegt in Register C vor [0..7]
;------- Initialisierung --------
		mvi h, 0
		mvi l, 100
		mvi m(hl), 239
		mvi c, 5
		jmp Start
; Routine zur Bitmaskenerstellung
Maske:	        mov a, c	; A:= C
		ana a		; CF = 0 setzen
		rar		; C nach rechts rotieren lassen
		mov c,a	        ; C:= A
		ret		; Rückkehr

;----- Begin des Programmes -----
Start:	        mvi b, 1 	; Register der Bitmaske mit 00000001 initialisieren
		call Maske	; Abfrage 1. Stelle von C = 0
		jnc Bit2	; wenn ja Sprung nach Bit2
		mov a, b	; A:= B
		add a		; A:= 2*A
		mov b, a	; B:= A
Bit2: 	        call Maske	; Abfrage 2. Stelle von C = 0
		jnc Bit3	; wenn ja Sprung nach Bit3
		mov a, b	; A:= B
		add a		; A:= 2*A
		add a		; A:= 2*A
		mov b, a	; B:= A
Bit3:		call Maske	; Abfrage 3. Stelle von C = 0
		jnc Ende	; wenn ja Sprung zu End, Bitmaske ist schon fertig
		mov a, b	; A:= B
		add a		; A:= 2*A
		add a		; A:= 2*A
		add a		; A:= 2*A
		mov b, a	; B:= A , Bitmaske ist jetzt fertig
Ende:	        mov a, m(hl)    ; A:= M(HL)
		xra b		; A:= A xor B , gewünschtes Bit wird invertert
		mov m(hl), a    ; M(HL):= A
END

; Speicherbedarf:  	40 Bytes
; Zeitkomplexität:
