.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "A-MAZE-ING",0
area_width EQU 640
area_height EQU 480
area DD 0

playerX DD 30
playerY DD 120

clickX DD 0
clickY DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

tile_width EQU 30
tile_height EQU 30
tile_size EQU 30

include digits.inc
include letters.inc
include tiles.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

make_tile proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 0
	jg make_perete
	lea esi, tiles
	jmp draw_tile
make_perete: 
	cmp eax, 1
	jg make_lava
	lea esi, tiles
	jmp draw_tile
make_lava: 
	cmp eax, 2
	jg make_up
	lea esi, tiles
	jmp draw_tile
make_up: 
	cmp eax, 3
	jg make_down
	lea esi, tiles
	jmp draw_tile
make_down: 
	cmp eax, 4
	jg make_right
	lea esi, tiles
	jmp draw_tile
make_right: 
	cmp eax, 5
	jg make_left
	lea esi, tiles
	jmp draw_tile
make_left: 
	cmp eax, 6
	jg make_spatiu
	lea esi, tiles
	jmp draw_tile
make_spatiu:
	mov eax, 7
	lea esi, tiles
	jmp draw_tile

draw_tile:
	mov ebx, tile_width
	mul ebx
	mov ebx, tile_height
	mul ebx
	add esi, eax
	mov ecx, tile_height
	
bucla_simbol_linii_tile:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, tile_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, tile_width
	
bucla_simbol_coloane_tile:
	cmp byte ptr [esi], 0 ;transparent
	je black	
	cmp byte ptr [esi], 1 ;alb
	je white
	cmp byte ptr [esi], 2 ;perete 
	je green
	cmp byte ptr [esi], 3 ;lava
	je orange
	cmp byte ptr [esi], 4 ;jucator
	je blue
	cmp byte ptr [esi], 5 ;buton
	je light_blue
	cmp byte ptr [esi], 6 ;sageata
	je red

done:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane_tile
	pop ecx
	loop bucla_simbol_linii_tile
	jmp over

	black:
		mov dword ptr [edi], 0000000h ;transparent
		jmp done
	white:
		mov dword ptr [edi], 0FFFFFFh ;alb
		jmp done
	green:
		mov dword ptr [edi], 0193B11h;perete
		jmp done
	orange:
		mov dword ptr [edi], 0FF2A00h ;lava
		jmp done
	blue:
		mov dword ptr [edi], 062FFFAh ;jucator
		jmp done
	light_blue:
		mov dword ptr [edi], 007FFBFh ;buton
		jmp done
	red:
		mov dword ptr [edi], 0950000h ;sageata
		jmp done
	
	over:
	popa
	mov esp, ebp
	pop ebp
	ret
make_tile endp

make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_line
	cmp eax, '9'
	jg make_line
	sub eax, '0'
	lea esi, digits
	jmp draw_text
	
make_line:	
	cmp eax, 26 ; de la 0 pana la 25 sunt litere, 26 e linie, 27 e space
	jg make_space 
	lea esi, letters
	jmp draw_text

make_space:
	mov eax, 27
	lea esi, letters
	
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
	
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_negru
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
simbol_pixel_negru:
	mov dword ptr [edi], 0000000h
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp


; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

make_tile_macro macro tile, drawArea, x, y
	push y
	push x
	push drawArea
	push tile
	call make_tile
	add esp, 16
	
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	
	;jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
;
	mov eax,[ebp+arg1]
	;
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0
	push area
	call memset
	add esp, 12
	;	jmp afisare_litere
; evt_timer:
	; inc counter
	
	
afisare_litere:
	
;scriem un mesaj

	make_text_macro 'A', area, 520, 60 
	make_text_macro 26, area,  530, 60 
	make_text_macro 'M', area, 540, 60 
	make_text_macro 'A', area, 550, 60 
	make_text_macro 'Z', area, 560, 60 
	make_text_macro 'E', area, 570, 60
	make_text_macro 26, area,  580, 60
	make_text_macro 'I', area, 590, 60 
	make_text_macro 'N', area, 600,	60
	make_text_macro 'G', area, 610, 60
	
	make_text_macro 'R', area,520, 390 
	make_text_macro 'U', area,530, 390
	make_text_macro 'S', area,540, 390
	make_text_macro 'A', area,520, 420
	make_text_macro 'N', area,530, 420
	make_text_macro 'A', area,540, 420
	make_text_macro 26, area, 550, 420
	make_text_macro 'M', area,560, 420
	make_text_macro 'A', area,570, 420
	make_text_macro 'R', area,580, 420
	make_text_macro 'I', area,590, 420
	make_text_macro 'A', area,600, 420
	make_text_macro 'C', area,520, 450
	make_text_macro 'A', area,530, 450
	make_text_macro 'R', area,540, 450
	make_text_macro 'I', area,550, 450
	make_text_macro 'N', area,560, 450
	make_text_macro 'A', area,570, 450

;butoane
	
	make_tile_macro 3, area, 555, 180 ;up
	make_tile_macro 4, area, 555, 250 ;down
	make_tile_macro 6, area, 590, 215 ;right
	make_tile_macro 5, area, 520, 215 ;left
	
;chenar mapa
	
	make_tile_macro 1, area,  30, 60
	make_tile_macro 1, area,  60, 60
	make_tile_macro 1, area,  90, 60
	make_tile_macro 1, area, 120, 60
	make_tile_macro 1, area, 150, 60
	make_tile_macro 1, area, 180, 60
	make_tile_macro 1, area, 210, 60
	make_tile_macro 1, area, 240, 60
	make_tile_macro 1, area, 270, 60
	make_tile_macro 1, area, 300, 60
	make_tile_macro 1, area, 330, 60
	make_tile_macro 1, area, 360, 60
	make_tile_macro 1, area, 390, 60
	make_tile_macro 1, area, 420, 60
	
	make_tile_macro 1, area,  30,  60
	make_tile_macro 1, area,  30,  90
	make_tile_macro 1, area,  30, 150
	make_tile_macro 1, area,  30, 180
	make_tile_macro 1, area,  30, 210
	make_tile_macro 1, area,  30, 240
	make_tile_macro 1, area,  30, 270
	make_tile_macro 1, area,  30, 300
	make_tile_macro 1, area,  30, 330
	make_tile_macro 1, area,  30, 360
	make_tile_macro 1, area,  30, 390
	make_tile_macro 1, area,  30, 420
	
	make_tile_macro 1, area,   60, 420
	make_tile_macro 1, area,   90, 420
	make_tile_macro 1, area,  120, 420
	make_tile_macro 1, area,  150, 420
	make_tile_macro 1, area,  180, 420
	make_tile_macro 1, area,  210, 420
	make_tile_macro 1, area,  240, 420
	make_tile_macro 1, area,  270, 420
	make_tile_macro 1, area,  300, 420
	make_tile_macro 1, area,  330, 420
	make_tile_macro 1, area,  360, 420
	make_tile_macro 1, area,  390, 420
	make_tile_macro 1, area,  420, 420
	
	make_tile_macro 1, area,  420, 90
	make_tile_macro 1, area,  420,120
	make_tile_macro 1, area,  420,150
	make_tile_macro 1, area,  420,180
	make_tile_macro 1, area,  420,210
	make_tile_macro 1, area,  420,240
	make_tile_macro 1, area,  420,270
	make_tile_macro 1, area,  420,300
	make_tile_macro 1, area,  420,330
	make_tile_macro 1, area,  420,390

;pereti

	make_tile_macro 1, area,  90, 90
	make_tile_macro 1, area,  60,150 
	make_tile_macro 1, area,  90,150 
	make_tile_macro 1, area,  120, 150
	make_tile_macro 1, area,  150, 150
	make_tile_macro 1, area,  150,120 
	make_tile_macro 1, area,  210,120
	make_tile_macro 1, area,  210,150
	make_tile_macro 1, area,  90,210
	make_tile_macro 1, area,  90,240 
	make_tile_macro 1, area,  150,210 
	make_tile_macro 1, area,  150,240
	make_tile_macro 1, area,  210,210
	make_tile_macro 1, area,  210,270
	make_tile_macro 1, area,  210,300
	make_tile_macro 1, area,  90,300	
    make_tile_macro 1, area,  150,300 
	make_tile_macro 1, area,  120, 360
	make_tile_macro 1, area,  180, 360
	make_tile_macro 1, area,  270,120 
	make_tile_macro 1, area,  270,150
	make_tile_macro 1, area,  330,120
	make_tile_macro 1, area,  330,180 
	make_tile_macro 1, area,  360, 180
	make_tile_macro 1, area,  270,210
	make_tile_macro 1, area,  270,270
	make_tile_macro 1, area,  300, 270
	make_tile_macro 1, area,  270,330 
	make_tile_macro 1, area,  270, 360
	make_tile_macro 1, area,  270, 390	
	make_tile_macro 1, area,  330,270 
	make_tile_macro 1, area,  330,300
	make_tile_macro 1, area,  330,360
	make_tile_macro 1, area,  240,120

;lava

	make_tile_macro 2, area,  60, 90
	make_tile_macro 2, area,  60 ,240
	make_tile_macro 2, area,  210,180 
	make_tile_macro 2, area,  210,330 
	make_tile_macro 2, area,  270,240 
	make_tile_macro 2, area,  270,300 
	make_tile_macro 2, area,  240,390 
	make_tile_macro 2, area,  300,90 
	make_tile_macro 2, area,  330,210
	make_tile_macro 2, area,  330,330 
	make_tile_macro 2, area,  390,90 
	make_tile_macro 2, area,  390,330 
	make_tile_macro 2, area,  360,390 	
	make_tile_macro 2, area,  150, 360
	make_tile_macro 2, area,  210, 240
	make_tile_macro 2, area,  90 ,360 
	make_tile_macro 2, area,  150, 270
	make_tile_macro 2, area,  360, 270
	
	
evt_click:
	
	mov eax, [ebp+arg2];x	
	mov clickX, eax
	
	mov eax, [ebp+arg3];y
	mov clickY, eax
	
;up	
	cmp clickX, 555
	jl up_fail
	cmp clickX, 585
	jg up_fail
	cmp clickY, 180
	jl up_fail
	cmp clickY, 210
	jg up_fail
	
	mov eax, playerY
	dec eax 
	mov ebx, area_width
	mul ebx
	add eax, playerX
	shl eax,2
	add eax, area
	
	cmp dword ptr [eax],0FF2A00h
	je este_lava
		
	cmp dword ptr [eax],0193B11h
	je up_fail
	
	make_tile_macro 7,area,playerX,playerY
	sub playerY, 30
	jmp up_fail

	este_lava:
	make_tile_macro 7,area,playerX,playerY
	mov playerX, 30
	mov playerY,120	
	
;down	
	up_fail:
	cmp clickX, 555
	jl down_fail
	cmp clickX, 585
	jg down_fail
	cmp clickY, 250
	jl down_fail
	cmp clickY, 280
	jg down_fail
	
	mov eax, playerY
	inc eax 
	add eax, 30
	mov ebx, area_width
	mul ebx
	add eax, playerX
	shl eax,2
	add eax, area
	
	cmp dword ptr [eax],0FF2A00h
	je este_lava1
		
	cmp dword ptr [eax],0193B11h
	je down_fail
	
	make_tile_macro 7,area,playerX,playerY
	add playerY, 30
	jmp down_fail
	
	este_lava1:
	make_tile_macro 7,area,playerX,playerY
	mov playerX, 30
	mov playerY,120	
	
	
;right		
	down_fail:
	cmp clickX, 590
	jl right_fail
	cmp clickX, 620
	jg right_fail
	cmp clickY, 215
	jl right_fail
	cmp clickY, 245
	jg right_fail
	
	mov eax, playerY
	mov ebx, area_width
	mul ebx
	add eax, playerX
	add eax, 30
	inc eax
	shl eax,2
	add eax, area
	
	cmp dword ptr [eax],0FF2A00h
	je este_lava2
		
	cmp dword ptr [eax],0193B11h
	je right_fail
	
	make_tile_macro 7,area,playerX,playerY
	add playerX, 30
	jmp right_fail
	
	este_lava2:
	make_tile_macro 7,area,playerX,playerY
	mov playerX, 30
	mov playerY,120	
		
;left	
	right_fail:
	cmp clickX, 520
	jl left_fail
	cmp clickX, 550
	jg left_fail
	cmp clickY, 215
	jl left_fail
	cmp clickY, 245
	jg left_fail
	
	mov eax, playerY
	mov ebx, area_width
	mul ebx
	add eax, playerX
	;sub eax, 30
	dec eax
	shl eax,2
	add eax, area
	
	cmp dword ptr [eax],0FF2A00h
	je este_lava3
		
	cmp dword ptr [eax],0193B11h
	je left_fail
	
	make_tile_macro 7,area,playerX,playerY
	sub playerX, 30
	jmp left_fail
	
	este_lava3:
	make_tile_macro 7,area,playerX,playerY
	mov playerX, 30
	mov playerY,120
	
	left_fail: 
	make_tile_macro 0, area, playerX,playerY
	
	cmp playerX, 420
	jl final_draw
	cmp playerX,440
	jg final_draw
	cmp playerY, 360
	jl final_draw
	cmp playerY, 390
	jg final_draw
	
	make_text_macro 'A', area, 170, 20 
	make_text_macro 'I', area, 180, 20
	make_text_macro 27,  area, 190, 20
	make_text_macro 'C', area, 200, 20
	make_text_macro 'A', area, 210, 20
	make_text_macro 'S', area, 220, 20
	make_text_macro 'T', area, 230, 20
	make_text_macro 'I', area, 240, 20
	make_text_macro 'G', area, 250, 20
	make_text_macro 'A', area, 260, 20
	make_text_macro 'T', area, 270, 20
			

	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp
			   
start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start






















