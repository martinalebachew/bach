IDEAL
MODEL small

STACK 0f500h

DATASEG
; Bitmap Variables
    OneBmpLine db 320 dup (0)
    ScrLine db 320 dup (0)
    Header db 54 dup(0)
  	Palette db 400h dup (0)
    BmpLeft dw ?
  	BmpTop dw ?
  	BmpColSize dw ?
  	BmpRowSize dw ?
    FileHandle	dw ?

; Hard Coded Settings
    FileName 	db 'assets/bg.bmp' ,0
    CommsName 	db 'assets/comms.txt' ,0
    AlbumFile db 'assets/1.bmp', 0

; General Variables
    InputCode dw 0h
    IsAlbumLoaded db 0
    currentAlbum db 0
    currentRow db 0

; Mouse Mask
	MouseMask       dw    0011111111111111b
                  dw    0001111111111111b
                  dw    0000111111111111b
                  dw    0000011111111111b
                ;
                  dw    0000001111111111b
                  dw    0000000111111111b
                  dw    0000000011111111b
                  dw    0000000001111111b
                ;
                  dw    0000000000111111b
                  dw    0000000111111111b
                  dw    0001000011111111b
                  dw    0011000011111111b
                ;
                  dw    1111100001111111b
                  dw    1111100001111111b
                  dw    1111110000111111b
                  dw    1111111111111111b
                ;
                ; cursor mask ---
                  dw    0000000000000000b
                  dw    0100000000000000b
                  dw    0110000000000000b
                  dw    0111000000000000b
                ;
                  dw    0111100000000000b
                  dw    0111110000000000b
                  dw    0111111000000000b
                  dw    0111111100000000b
                ;
                  dw    0111111110000000b
                  dw    0111111111000000b
                  dw    0111110000000000b
                  dw    0100011000000000b
                ;
                  dw    0000011000000000b
                  dw    0000001100000000b
                  dw    0000001100000000b
                  dw    0000000000000000b

CODESEG
start:
  	mov ax, @data
  	mov ds, ax

  	call SetGraphic

    ; Load Album Grid
    mov dx, offset FileName
    call LoadScreen

    ; Wait For Action
  	call setAsyncMouse ; Mouse Handler
    mov ah, 7 ; Press Any Key to Exit
  	int 21h

exit:
  	call SetText
  	mov ax, 4c00h
  	int 21h

;---------------------------
; Procudures area
;---------------------------

; LoadScreen
; Description: Load Relevant Screen.
; Entry:
; dx = screen filename ptr
; Return: set bmp size, call OpenBitmap and print title.
proc LoadScreen
    ; Set Coordinates and Load BMP
    mov [BmpLeft],0
    mov [BmpTop],0
    mov [BmpColSize], 320
    mov [BmpRowSize], 200
    call OpenBitmap

    ret
endp LoadScreen


; OpenFile
; Description: Open File.
; Entry:
; dx = filename ptr
; Return: open file using interrupt 21 / function 03Dh, then save file handle.
proc OpenFile near
    ; Open File. On Error Exit Program. Save Handle.
    mov ah, 3Dh
    mov al, 2
    int 21h
    jc exit

    mov [FileHandle], ax
    ret
endp OpenFile


; CloseFile
; Description: Close File.
; Entry:
; dx = filename ptr
; Return: retrieve file handle, close file using interrupt 21 / function 03Eh.
proc CloseFile near
  ; Retrieve Handle. Close File.
  	mov ah,3Eh
  	mov bx, [FileHandle]
  	int 21h
  	ret
endp CloseFile


; OpenBitmap
; Description: View Bmp File.
; Entry:
; dx = filename ptr
; Return: see flowchart I.
proc OpenBitmap near

    call OpenFile

    ; read 54 bytes header

    push cx
  	push dx

  	mov ah,3fh
  	mov bx, [FileHandle]
  	mov cx,54
  	mov dx,offset Header
  	int 21h

  	pop dx
  	pop cx

    ; Read BMP file color palette, 256 colors * 4 bytes (400h)
    						 ; 4 bytes for each color BGR + null)
    push cx
    push dx

    mov ah,3fh
    mov cx,400h
    mov dx,offset Palette
    int 21h

    pop dx
    pop cx

    ; Will move out to screen memory the colors
    ; video ports are 3C8h for number of first color
    ; and 3C9h for all rest

    push cx
    push dx

    mov si,offset Palette
    mov cx,256
    mov dx,3C8h
    mov al,0  ; black first
    out dx,al ;3C8h
    inc dx	  ;3C9h
    CopyNextColor:
    mov al,[si+2] 		; Red
    shr al,2 			; divide by 4 Max (cos max is 63 and we have here max 255 ) (loosing color resolution).
    out dx,al
    mov al,[si+1] 		; Green.
    shr al,2
    out dx,al
    mov al,[si] 		; Blue.
    shr al,2
    out dx,al
    add si,4 			; Point to next color.  (4 bytes for each color BGR + null)

    loop CopyNextColor

    pop dx
    pop cx

    ; BMP graphics are saved upside-down.
    ; Read the graphic line by line (BmpRowSize lines in VGA format),
    ; displaying the lines from bottom to top.
    push cx

    mov ax, 0A000h
    mov es, ax

    mov cx,[BmpRowSize]


    mov ax,[BmpColSize] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
    xor dx,dx
    mov si,4
    div si
    cmp dx,0
  	mov bp,0
  	jz @@row_ok
  	mov bp,4
  	sub bp,dx

@@row_ok:
  	mov dx,[BmpLeft]

@@NextLine:
  	push cx
  	push dx

  	mov di,cx  ; Current Row at the small bmp (each time -1)
  	add di,[BmpTop] ; add the Y on entire screen


  	; next 5 lines  di will be  = cx*320 + dx , point to the correct screen line
  	dec di
  	mov cx,di
  	shl cx,6
  	shl di,8
  	add di,cx
  	add di,dx

  	; small Read one line
  	mov ah,3fh
  	mov cx,[BmpColSize]
  	add cx,bp  ; extra  bytes to each row must be divided by 4
  	mov dx,offset ScrLine
  	int 21h
  	; Copy one line into video memory
  	cld ; Clear direction flag, for movsb
  	mov cx,[BmpColSize]
  	mov si,offset ScrLine
  	rep movsb ; Copy line to the screen

  	pop dx
  	pop cx

  	loop @@NextLine

  	pop cx

  	call CloseFile

  	ret
endp OpenBitmap


; WriteComms
; Description: Write Input Code To Comms ('IPC' Like) File.
; Entry: none.
; Return: open comms file, write input code, and close file.
proc WriteComms	near
    ; Open Comms File.
    mov dx, offset CommsName
    call OpenFile

    ; Write Input Code, Then Close.
    mov  ah, 40h
    mov  bx, [FileHandle]
    mov  cx, 2  ;STRING LENGTH.
    mov  dx, offset InputCode
    int  21h

    call CloseFile

@@ExitProc:
  	ret
endp WriteComms


; MouseHandler
; Description: Handle Mouse Left Click.
; Entry:
; cx = row
; dx = column
; Return: see flowchart II.
proc MouseHandler far
    ; documentation: http://www.techhelpmanual.com/845-int_33h_000ch__set_mouse_event_handler.html
		; show mouse
		push ax
		mov ax,01h
		int 33h
		pop ax


		shr cx, 1 	 ;the Mouse default is 640X200 So divide 640 by 2 to get
    ; dx = row [x], cx = column [y]

    push ax
		mov ax,02h
		int 33h
		pop ax

    cmp dx, 23
    jae @@notheader

    jmp @@header

@@notheader:

    cmp [IsAlbumLoaded], 1
    je @@InAlbumLogic

    ; per album frame

    cmp dx, 110
    jb @@FirstRow

    add [currentAlbum], 4

@@FirstRow:

    ; calc in-row pos

    mov di, cx
    sub di, 7

@@calcpos:
    inc [currentAlbum]
    sub di, 77
    cmp di, 0
    jg @@calcpos

    cmp [currentAlbum], 9
    jl @@correct

    dec [currentAlbum]

@@correct:
    push dx
    mov dl, [currentAlbum]
    add dl, 30h
    mov [AlbumFile + 7], dl
    pop dx

    mov dx, offset AlbumFile
    call LoadScreen
    mov [IsAlbumLoaded], 1

    ; ; shl cx, 1
    ; mov ah, 0dh
    ; int 10h
    ; ; shr cx, 1

    ; cmp al, 24
    ; je @@notblank
    ;
    ; cmp al, 25
    ; je @@notblank

@@JMPEXITREF:

    jmp ExitProc

@@InAlbumLogic:

    mov di, dx
    sub di, 27
    mov [currentRow], 0

@@calcrow:
    inc [currentRow]
    sub di, 14
    cmp di, 0
    jg @@calcrow

    cmp [currentRow], 13
    jne @@dontdec

    dec [currentRow]

@@dontdec:
    push ax

    xor ah, ah
    mov al, [currentAlbum]
    shl ax, 4
    add al, [currentRow]
    mov [InputCode], ax
    call WriteComms

    pop ax
    jmp ExitProc

@@header:
    ; ; shl cx, 1
    ; mov ah, 0dh
    ; int 10h
    ; ; shr cx, 1

    ; cmp al, 0
    ; je ExitProc

    cmp cx, 30
    jb @@back

    cmp cx, 235
    jb ExitProc

    cmp cx, 262
    jb @@playpause

    cmp cx, 286
    jb @@stopandexit

    jmp @@forward

@@back:
    mov [InputCode], 0h
    jmp @@save

@@playpause:
    mov [InputCode], 1h
    jmp @@save

@@forward:
    mov [InputCode], 2h
    jmp @@save

@@stopandexit:

    cmp [IsAlbumLoaded], 1
    jne ExitProc

    mov [InputCode], 3h
    mov [IsAlbumLoaded], 0
    mov [currentAlbum], 0

    mov dx, offset FileName
    call LoadScreen

@@save:
    call WriteComms

ExitProc:
		; show mouse
		mov ax,01h
		int 33h
		retf
endp MouseHandler


; SetGraphic
; Description: Set Graphic Mode.
; Entry: none.
; Return: set graphic mode using interrupt 10h / function 13h.
proc SetGraphic
  	mov ax,13h   ; 320 X 200, standard 256-color mode
  	int 10h
  	ret
endp SetGraphic


; SetText
; Description: Set Text Mode.
; Entry: none.
; Return: set text mode using interrupt 10h / function 2h.
proc  SetText
    mov ax,2 ; 16-color text mode
    int 10h
  	ret
endp 	SetText


; SetAsyncMouse
; Description: Initialize Mouse Handler.
; Entry: none.
; Return: set mouse handler procedure using interrupt 33h / function 0Ch.
proc setAsyncMouse
    mov ax, seg MouseHandler
    mov es, ax
    mov dx, offset MouseHandler ; ES:DX -> Far Routine
    mov ax, 0Ch
    mov cx, 2 ; Left Click
    int 33h
	  ret
endp setAsyncMouse


END start
