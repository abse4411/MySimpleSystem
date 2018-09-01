assume cs:code

code segment
str1	db "Install success!",0
str2	db "install error!" ,0
start: 
	mov ax,cs			;write the bootup program to the soft disk
	mov es,ax
	mov bx,offset bootup		
	mov ax,0301h				
	mov cx,1
	mov dx,0
	int 13h

	cmp ah,0
	jne error
	cmp al,1
	jne error

	mov bx,offset system  	;write the mysystem to the soft disk
	mov ax,0302h				
	mov cx,2
	mov dx,0
	int 13h

	cmp ah,0
	jne error
	cmp al,2
	jne error

	mov cl,2
	mov si,offset str1
	jmp short suc
error:	mov cl,4
	mov si,offset str2
suc:	mov ax,cs
	mov ds,ax
	mov dh,12
	mov dl,35
	call showstr

	mov ax,4c00h
       	int 21h
;___________________________________copy mysystem to safety memory area , 
;___________________________________in order to be not overwritten by other boot programs .
bootup:
	mov ax,0
	mov es,ax
	mov bx,7e00h  
	mov ax,0202h
	mov cx,2
	mov dx,0
	int 13h
	mov ax,7e00h
	jmp ax                  
;___________________________________my system
system:
	jmp begin
f0	db 'Welcome to XF System!',0		;menu
f1	db '1) restart pc',0
f2	db '2) start system',0
f3	db '3) clock',0
f4	db '4) set clock',0
f5	db 'Enter number(1~4) to execute.',0
pz	db 9,8,7,4,2,0
strtable	dw f1-f0,f2-f1,f3-f2,f4-f3,f5-f4
funtable	dw resart-system+7e00h,startsys-system+7e00h, showtime-system+7e00h,settime-system+7e00h

begin:	mov ax,cs
	mov ds,ax
	mov dl,0

main:	mov bx,f0-system+7e00h
	call cls

	mov dh,0
	mov bx,strtable-system+7e00h
	mov si,f0-system+7e00h
	mov cx,6
ms:	push cx		;this loop for printing menu
	mov cl,2
	call showstr
	pop cx
	add si,cs:[bx]
	add bx,2
	inc dh
	loop ms

ssub:	mov ah,0		;check input
	int 16h
	sub al,49
	cmp al,3
	ja ssub

	mov bh,0
	mov bl,al
	add bl,bl
	add bx,funtable-system+7e00h
	call cls
	call word ptr cs:[bx]
	jmp short main
	retf
;___________________________________restart pc
resart:	
	mov ax,0ffffh
	mov bx,0
	push ax
	push bx
	retf			
;___________________________________start system from hard disk
startsys:	
	mov bx,7c00h  
	mov ax,0201h
	mov cx,0001h
	mov dx,0080h
	int 13h
      	mov ax,7c00h	
	jmp ax
;___________________________________show now date and time
showtime:jmp short stbegin
timeb	db 'Now time is : 20'
time	db 'YY/MM/DD HH:MM:SS',0
color	db 2

stbegin:	push ax
	push bx
	push cx
	push dx
	push si
	mov dh,12
	mov dl,23

sts:	mov si,time-system+7e00h
	mov bx,pz-system+7e00h
	mov cx,6

strlp:	mov al,cs:[bx]
	out 70h,al
	in al,71h
	push cx
	mov ah,al
	mov cl,4
	shr al,cl
	pop cx
	and ah,00001111b
	mov [si],ax
	add byte ptr cs:[si],30h
	add byte ptr cs:[si+1],30h
	add bx,1
	add si,3
	loop strlp
	
	in al,60h
	cmp al,3bh
	je cc
	cmp al,1
	je stok
	mov si,timeb-system+7e00h
	mov cl,cs:[color-system+7e00h]
	call showstr
	jmp short sts

cc:	inc byte ptr cs:[color-system+7e00h]
	jmp short sts

stok:	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
;________________________________set time by a string(YYMMDDHHMMSS) , don't check legality . 
settime:
	jmp  setbegin
setstr	db 'Enter a string to set time :',0
result	db '000000000000',0

setbegin:	push si
	push bx
	push dx
	push es
	push ds
	push ax

	mov ax,cs
	mov ds,ax
	mov si,setstr-system+7e00h
	mov cl,2
	mov dx,0
	call showstr
	mov si,result-system+7e00h
	mov dx,0100h
	call showstr

	mov ax,0b800h
	mov es,ax
	mov bx,160+0
	mov si,result-system+7e00h
sets:	mov ah,0
	int 16h
	cmp al,20h
	jb nochar
	cmp al,'0'
	jb sets
	cmp al,'9'
	ja sets
	cmp bx,160+11*2
	ja sets
	mov es:[bx],al
	mov cs:[si],al
	mov byte ptr es:[bx+1],2
	inc si
	add bx,2
	jmp short sets

	
nochar:	cmp ah,0eh
	je backspace
	cmp ah,1ch
	je enter
	cmp ah,1h
	je setok
	jmp short sets

enter:	mov si,result-system+7e00h
	call savetime
	jmp short setok

backspace:cmp bx,160
	je sets
	sub bx,2
	dec si
	mov byte ptr es:[bx],'0'
	mov byte ptr cs:[si],'0'
	jmp short sets

setok:	pop ax
	pop ds
	pop es
	pop dx
	pop bx
	pop si
	ret
;________________________________save time
savetime:
	push ax
	push bx
	push cx
	push si

	mov bx,pz-system+7e00h
	mov cx,6
saves:	mov ah,[si+1]
	mov al,[si]
	sub al,48
	sub ah,48
	push cx
	mov cl,4
	shl al,cl
	pop cx
	add ah,al
	mov al,cs:[bx]
	out 70h,al
	mov al,ah
	out 71h,al	
	inc bx
	add si,2
	loop saves
	
	pop si
	pop cx
	pop bx
	pop ax
	ret
;________________________________clear screen
cls:	
	push bx
	push ds
	push cx

	mov bx,0b800h
	mov ds,bx
	mov bx,0
	mov cx,2000
clss:	mov word ptr [bx],0
	add bx,2
	loop clss

	pop cx
	pop ds
	pop bx
	ret
;________________________________show a string
;________________________________dh , dl : row,col
;________________________________cl:color
;________________________________ds:si  the first address of the string which ends with 0(ascii=0)
showstr:	push ax
	push bx
	push cx
	push dx
	push si
	push es

	mov ax,160
	mul dh
	mov dh,0
	add ax,dx
	add ax,dx
	mov bx,ax
	mov ax,0b800h
	mov es,ax
	mov al,cl
	mov ch,0

strs:	mov cl,[si]
	jcxz strok
	mov es:[bx],cl
	mov es:[bx+1],al
	inc si
	add bx,2
	jmp short strs
	
strok:	pop es
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
;___________________________________
sysend:nop
code ends
end start
