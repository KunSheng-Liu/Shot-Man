PrintChar macro chr  ;輸出字元
          mov ah,02h
          mov dl,chr
          int 21h
          endm

PrintStr macro string ;輸出字串
         mov ah,09h
         mov dx,offset string
         int 21h
         endm

GetChar macro         ;等待輸入
        mov ah,10h
        int 16h
        endm

SetMode macro mode    ;設定顯示模式
        mov ah,00h
        mov al,mode
        int 10h
        endm

SetColor macro color  ;設定背景色
         mov ah,0bh 
         mov bh,00h
         mov bl,color  
         int 10h
         endm

WrPixel macro col,row,color  ;寫入像點
        mov ah,0ch
        mov bh,00h
        mov al,color
        mov cx,col
        mov dx,row
        int 10h
        endm

SetCursor macro row,col  ;設定游標位置
          mov dh,row
          mov dl,col
          mov bx,00h
          mov ah,02h
          int 10h
          endm

SetChar	macro Char,type,times  ;寫入字元及屬性
	mov ah,09h
	mov al,Char
	mov bh,0
	mov bl,type
	mov cx,times
	int 10h
	endm

printstr13h macro str,atr,len,row,col,cursor_move  ;繪圖模式輸出字串
	    mov ax,ds
	    mov es,ax
        mov bp,offset str
	    mov ah,13h
	    mov al,cursor_move
            mov bh,00
	    mov bl,atr	    
            mov cx,len
	    mov dh,row
	    mov dl,col
	    int 10h
	    endm

MUS_RESET macro		;滑鼠重置		 	
	  mov ax,0000h
	  int 33h
	  endm

MUS_SHOW macro		;顯示滑鼠游標 
	 mov ax,0001h
	 int 33h
	 endm
			
MUS_HIND macro 		;隱藏滑鼠游標
	 mov ax,0002h
	 int 33h
	 endm
			
MUS_GET03 macro 	;取得滑鼠狀態與游標位置
	  mov ax,0003h
	  int 33h
	  endm
SET_MUS	macro	Col,Row	;設定滑鼠游標位置
	mov ax,0004h
	mov dx,Row
	mov cx,Col
	int 33h
	endm

MUS_range_x macro max,min	;設定滑鼠水平游標的範圍
	    mov ax,0007h
            mov dx,max
	    mov cx,min
	    int 33h
            endm

MUS_range_y macro max,min	;設定滑鼠垂直游標的範圍
       	    mov ax,0008h
	    mov dx,max
	    mov cx,min
            int 33h
	    endm


.8086
.model small
.stack 1024
.data


loser 		db 	10,13,"Your Hit Rate is : ","$" 
losee 		db 	10,13,"(press y to play,other to left)$"	
rules 		db 	"SHOT 8 MAN DON'T MISS!",10,13,"$"
rules1 		db	"press any key to continue$"
kill_str	db	"KILL : ","$"
miss_str	db	10,13,"MISS : ","$"
level_up	db	10,13,"LEVEL UP!",10,13,'$'

db_tmp	db	?
dw_tmp	dw	?
color	db	?
MUS_CX	dw	0
MUS_DX	dw	0
enemy_dx	dw	300
enemy_Cx	dw	300
counter	dw	0
kill	dw	0
miss_count	dw	0
rate	dw	0
level	dw	30

.code
.startup
	
	MUS_RESET
	MUS_SHOW

gamestart:
	SetMode		12h
	SetColor	00h
	MUS_SHOW
	Printstr	rules
	Printstr	rules1
	Getchar
	MUS_RESET
	MUS_range_x	610,30			;mouse horixontal range
	MUS_range_y	450,30			;mouse vertical range

	mov	kill,0
	mov	miss_count,0
	mov 	MUS_CX,290
	mov 	MUS_DX,450
	SET_MUS	MUS_CX,MUS_DX			;initial position
again:
	inc	counter
	mov	ax,level
	cmp	counter,ax			;判斷小人是否需要刷新
	je	enemy_call			
	jmp	skip

enemy_call:
	call	Call_Enemy			;刷新小人位置

skip:
	SetMode		12h
	SetColor	00h

	PrintStr 	kill_str
	mov	ax,kill				;顯示擊殺次數
	call	valueToASCII

	PrintStr 	miss_str		;顯示落空次數
	mov	ax,miss_count
	call	valueToASCII
	
	call	print_Bullseye			;顯示小人

	call	SCANIN				;判斷是否被關閉
	cmp	al,65h
	jz	Exit
	cmp	al,45h
	jz	Exit

	MUS_GET03				;擷取游標資訊
	
	mov	MUS_CX,CX			;將游標位置儲存
	mov	MUS_DX,DX

	cmp	bx,1				;判斷是否按下左鍵
	jne	no_shot
	call	Shot				;顯示開火畫面
no_shot:
	call	print_Concentric		;顯示準心
	call	Delay
	cmp	kill,8				;判斷是否擊殺8次
	je	Finish
	
	jmp	again
Finish:
	SetMode 12h				;螢幕更新
	SetColor 00h
	
	mov	ax,kill				;計算命中率
	mov	bx,miss_count
	add	bx,ax
	mov	cx,100
	mul	cx
	div	bx
	mov	rate,ax
	Printstr loser
	mov	ax,rate
	call	valueToASCII
	PrintChar '%'
	cmp	rate,60				;判斷是否升級
	ja	win
	jmp	lose
win:
	Printstr	level_up
	Printstr	rules1
	Getchar
	mov	ax,level			;難度增加,減少刷新時間
	sub	ax,6
	mov	level,ax
	mov	kill,0
	mov	miss_count,0
	jmp	again
	
lose:
	Printstr losee
	Getchar
	cmp al,'y'
	je gamestart
Exit:
	
	SetMode	03h	;設定文字模式03h
	mov ax,4c00h
	int 21h

.exit

Shot	proc	near
	
	call	Fire

	mov	cx,enemy_cx
	mov	dx,enemy_dx

	cmp	cx,MUS_CX
	ja	miss
	add	cx,30
	cmp	cx,MUS_CX
	jb	miss
	cmp	dx,MUS_DX
	ja	miss
	add	dx,30
	cmp	dx,MUS_DX
	jb	miss

	inc	kill
	call	Die
	jmp	break1
miss:
	inc	miss_count
break1:
	ret
Shot	endp

Fire	proc	near

	mov	color,01h	

	mov	cx,MUS_CX	;左上圓
	mov	dx,MUS_DX

	sub	dx,8
	WrPixel	cx,dx,color	;0,8
	sub	cx,4
	add	dx,1
	WrPixel	cx,dx,color	;4,7
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;5,6
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;6,5
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;7,4
	sub	cx,1
	add	dx,4
	WrPixel	cx,dx,color	;8,0
	
	mov	cx,MUS_CX	;右上圓
	mov	dx,MUS_DX

	sub	dx,8
	WrPixel	cx,dx,color	;0,8
	add	cx,4
	add	dx,1
	WrPixel	cx,dx,color	;4,7
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;5,6
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;6,5
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;7,4
	add	cx,1
	add	dx,4
	WrPixel	cx,dx,color	;8,0
	
	mov	cx,MUS_CX	;左下圓
	mov	dx,MUS_DX

	add	dx,8
	WrPixel	cx,dx,color	;0,8
	sub	cx,4
	sub	dx,1
	WrPixel	cx,dx,color	;4,7
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;5,6
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;6,5
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;7,4
	sub	cx,1
	sub	dx,4
	WrPixel	cx,dx,color	;8,0

	mov	cx,MUS_CX	;右下圓
	mov	dx,MUS_DX


	add	dx,8
	WrPixel	cx,dx,color	;0,8
	add	cx,4
	sub	dx,1
	WrPixel	cx,dx,color	;4,7
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;5,6
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;6,5
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;7,4
	add	cx,1
	sub	dx,4
	WrPixel	cx,dx,color	;8,0
	
	
	ret
Fire	endp


Die	proc	near

	mov	enemy_dx,480
	mov	enemy_cx,640
	
	ret
Die	endp


SCANIN	proc	near
	mov	ah,06h
	mov	dl,0ffh
	int	21h
	ret
SCANIN	endp

Delay	proc	near
	mov	cx,0
L3:
	mov	bp,0800h
L4:
	dec	bp
	cmp	bp,0
	jnz	L4
	loop	L3
	ret
Delay	endp


print_Bullseye	proc	near
	mov	cx,enemy_cx
	mov	dx,enemy_dx
	mov	dw_tmp,0
L_h:
	WrPixel	cx,dx,color
	inc	dx
	inc	dw_tmp
	cmp	dw_tmp,10
	jne	L_h
	mov	dw_tmp,0
arm:
	WrPixel	cx,dx,color
	inc	cx
	inc	dw_tmp
	cmp	dw_tmp,30
	jne	arm
	mov	dw_tmp,0
R_h:
	
	WrPixel	cx,dx,color
	dec	dx
	inc	dw_tmp
	cmp	dw_tmp,10
	jne	R_h

	mov	db_tmp,0
	mov	dx,enemy_dx
	add	cx,10
	
head1:
	mov	dw_tmp,0
	mov	cx,enemy_cx
	add	cx,10
	inc	dx
	inc	db_tmp
head2:
	WrPixel	cx,dx,color
	inc	cx
	inc	dw_tmp
	cmp	dw_tmp,10
	jne	head2
	inc	db_tmp
	cmp	db_tmp,10
	jne	head1
	
	mov	cx,enemy_cx
	mov	dx,enemy_dx
	mov	dw_tmp,0
	
	add	cx,15
	inc	dx
body:
	WrPixel	cx,dx,color
	inc	dx
	inc	dw_tmp
	cmp	dw_tmp,19
	jne	body

	mov	cx,enemy_cx
	mov	dx,enemy_dx
	mov	dw_tmp,0
	add	dx,30
	
L_f:
	WrPixel	cx,dx,color
	dec	dx
	inc	dw_tmp
	cmp	dw_tmp,10
	jne	L_f
	mov	dw_tmp,0
leg:
	WrPixel	cx,dx,color
	inc	cx
	inc	dw_tmp
	cmp	dw_tmp,30
	jne	leg
	mov	dw_tmp,0
R_f:
	WrPixel	cx,dx,color
	inc	dx
	inc	dw_tmp
	cmp	dw_tmp,10
	jne	R_f
	
	



	ret
print_Bullseye	endp

Call_Enemy	proc	near

	mov	counter,0
	mov ah,2cH
	int 21h

	mov	al,dl
	mov	ah,0
	mov	bl,2
	div	bl
	mov	ah,0
	mov	bl,10
	div	bl
	mov	bl,ah
	mov	ah,0
	mov	bh,0
	mov	cx,100
	mul	cx
	cmp	ax,400
	ja	big_dx
	cmp	ax,100
	jb	small_dx
	mov	enemy_dx,ax
conti:
	mov	ax,bx
	mul	cx
	cmp	ax,500
	ja	big_cx
	cmp	ax,100
	jb	small_cx
	mov	enemy_cx,ax
	jmp	break

big_dx:
	mov	enemy_dx,400
	jmp	conti
small_dx:
	mov	enemy_dx,100
	jmp	conti
big_cx:
	mov	enemy_cx,500
	jmp	break
small_cx:
	mov	enemy_cx,100
	jmp	break
break:

	ret
Call_Enemy	endp


print_Concentric	proc	near
	mov	color,04h	

	mov	cx,MUS_CX	;左上圓
	mov	dx,MUS_DX

	sub	dx,30
	WrPixel	cx,dx,color	;0,30
	sub	cx,7
	add	dx,1
	WrPixel	cx,dx,color	;7,29
	sub	cx,4
	add	dx,1
	WrPixel	cx,dx,color	;11,28
	sub	cx,2
	add	dx,1
	WrPixel	cx,dx,color	;13,27
	sub	cx,2
	add	dx,1
	WrPixel	cx,dx,color	;15,26
	sub	cx,2
	add	dx,1
	WrPixel	cx,dx,color	;17,25
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;18,24
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;19,23
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;20,22
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;21,21
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;22,20
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;23,19
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;24,18
	sub	cx,1
	add	dx,2
	WrPixel	cx,dx,color	;25,16
	sub	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;26,15
	sub	cx,1
	add	dx,2
	WrPixel	cx,dx,color	;27,13
	sub	cx,1
	add	dx,3
	WrPixel	cx,dx,color	;28,10
	sub	cx,1
	add	dx,3
	WrPixel	cx,dx,color	;29,7
	
	mov	cx,MUS_CX	;右上圓
	mov	dx,MUS_DX

	sub	dx,30
	WrPixel	cx,dx,color	;0,30
	add	cx,7
	add	dx,1
	WrPixel	cx,dx,color	;7,29
	add	cx,4
	add	dx,1
	WrPixel	cx,dx,color	;11,28
	add	cx,2
	add	dx,1
	WrPixel	cx,dx,color	;13,27
	add	cx,2
	add	dx,1
	WrPixel	cx,dx,color	;15,26
	add	cx,2
	add	dx,1
	WrPixel	cx,dx,color	;17,25
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;18,24
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;19,23
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;20,22
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;21,21
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;22,20
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;23,19
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;24,18
	add	cx,1
	add	dx,2
	WrPixel	cx,dx,color	;25,16
	add	cx,1
	add	dx,1
	WrPixel	cx,dx,color	;26,15
	add	cx,1
	add	dx,2
	WrPixel	cx,dx,color	;27,13
	add	cx,1
	add	dx,3
	WrPixel	cx,dx,color	;28,10
	add	cx,1
	add	dx,3
	WrPixel	cx,dx,color	;29,7
	
	mov	cx,MUS_CX	;左下圓
	mov	dx,MUS_DX

	add	dx,30
	WrPixel	cx,dx,color	;0,30
	sub	cx,7
	sub	dx,1
	WrPixel	cx,dx,color	;7,29
	sub	cx,4
	sub	dx,1
	WrPixel	cx,dx,color	;11,28
	sub	cx,2
	sub	dx,1
	WrPixel	cx,dx,color	;13,27
	sub	cx,2
	sub	dx,1
	WrPixel	cx,dx,color	;15,26
	sub	cx,2
	sub	dx,1
	WrPixel	cx,dx,color	;17,25
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;18,24
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;19,23
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;20,22
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;21,21
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;22,20
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;23,19
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;24,18
	sub	cx,1
	sub	dx,2
	WrPixel	cx,dx,color	;25,16
	sub	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;26,15
	sub	cx,1
	sub	dx,2
	WrPixel	cx,dx,color	;27,13
	sub	cx,1
	sub	dx,3
	WrPixel	cx,dx,color	;28,10
	sub	cx,1
	sub	dx,3
	WrPixel	cx,dx,color	;29,7

	
	mov	cx,MUS_CX	;右下圓
	mov	dx,MUS_DX

	add	dx,30
	WrPixel	cx,dx,color	;0,30
	add	cx,7
	sub	dx,1
	WrPixel	cx,dx,color	;7,29
	add	cx,4
	sub	dx,1
	WrPixel	cx,dx,color	;11,28
	add	cx,2
	sub	dx,1
	WrPixel	cx,dx,color	;13,27
	add	cx,2
	sub	dx,1
	WrPixel	cx,dx,color	;15,26
	add	cx,2
	sub	dx,1
	WrPixel	cx,dx,color	;17,25
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;18,24
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;19,23
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;20,22
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;21,21
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;22,20
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;23,19
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;24,18
	add	cx,1
	sub	dx,2
	WrPixel	cx,dx,color	;25,16
	add	cx,1
	sub	dx,1
	WrPixel	cx,dx,color	;26,15
	add	cx,1
	sub	dx,2
	WrPixel	cx,dx,color	;27,13
	add	cx,1
	sub	dx,3
	WrPixel	cx,dx,color	;28,10
	add	cx,1
	sub	dx,3
	WrPixel	cx,dx,color	;29,7

	mov	cx,MUS_CX	;準心
	mov	dx,MUS_DX
	
	sub	cx,30
	mov	bx,MUS_CX
	sub	bx,10
	mov	dw_tmp,bx
L1:
	WrPixel	cx,dx,color	
	inc	cx
	cmp	cx,dw_tmp
	jne	L1
	
	mov	cx,MUS_CX
	add	cx,30
	mov	bx,MUS_CX
	add	bx,10
	mov	dw_tmp,bx

L2:
	WrPixel	cx,dx,color	
	dec	cx
	cmp	cx,dw_tmp
	jne	L2

	mov	cx,MUS_CX	;準心
	mov	dx,MUS_DX
	
	sub	dx,30
	mov	bx,MUS_DX
	sub	bx,10
	mov	dw_tmp,bx
L3:
	WrPixel	cx,dx,color	
	inc	dx
	cmp	dx,dw_tmp
	jne	L3
	
	mov	dx,MUS_DX
	add	dx,30
	mov	bx,MUS_DX
	add	bx,10
	mov	dw_tmp,bx
L4:
	WrPixel	cx,dx,color	
	dec	dx
	cmp	dx,dw_tmp
	jne	L4
	call	Delay
	ret
print_Concentric	endp

valueToASCII proc    
	mov cx,0
	mov bl,10
 Hex2Asc:
	div bl
	mov dl,ah
	add dl,30h
	push dx
	inc cx	
	mov ah,0
	cmp al,0
	jne Hex2Asc
 addSpace:
	cmp cx,3
	je keepPnt
	mov dl,' '
	push dx
	inc cx
	jmp addSpace	
 keepPnt:
	pop ax
	PrintChar al
	loop keepPnt
	ret
valueToASCII endp

end


