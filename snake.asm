BITS 16
[ORG 0x7c00]

;;
;; Constants
SCREEN_Y equ 25
SCREEN_X equ 80
VIDEO_SEG equ 0B800h
APPLE_CHR equ 4020h
SNAKE_CHR equ 0A020h
SNAKEARRAY_Y equ 1000h
SNAKEARRAY_X equ 2000h
UP equ 0
DOWN equ 1
LEFT equ 2
RIGHT equ 3
WIN_CONDI equ 10

;;
;; Variables
Snake_Y dw 12
Snake_X dw 40
Apple_Y dw 12
Apple_X dw 20
Snake_Length dw 1
Direction dw 1

;;
;; Start with far jump
start: jmp 0:Init_Game

;;
;; Set Initial Game State
Init_Game:
        mov ax, 0003h
        int 10h                                                                 ; set video mode
        mov ax, VIDEO_SEG
        mov es, ax

        mov ah, 02h
        mov dx, 2600h
        int 10h                                                                 ; cursor disappear
        
        mov ax, word [Snake_Y]
        mov [SNAKEARRAY_Y], ax
        mov ax, word [Snake_X]
        mov [SNAKEARRAY_X], ax

        call Delay
        jmp game_loop

Set_Background:
        mov ax, 9020h
        xor di, di
        mov cx, SCREEN_Y * SCREEN_X
        rep stosw
        ret
        
Draw_Snake_Pos:                
        xor di, di
        xor ax, ax
        xor bx, bx
        xor cx, cx
        mov ax, SNAKE_CHR
        mov cx, [Snake_Length]
        .snake_draw:
                imul di, [SNAKEARRAY_Y+bx], SCREEN_X*2
                imul dx, [SNAKEARRAY_X+bx], 2
                add di, dx
                stosw
                inc bx
                inc bx
        loop .snake_draw
        ret

Draw_Apple_Pos:
        xor di, di
        xor ax, ax
        imul di, [Apple_Y], SCREEN_X*2
        imul dx, [Apple_X], 2
        add di, dx
        mov ax, APPLE_CHR
        stosw
        ret

Handle_Keystroke:
        mov ah, 1
        int 16h
        jz .done

        xor ah, ah
        int 16h

        cmp al, 'w'
        je .w_pressed
        cmp al, 's'
        je .s_pressed
        cmp al, 'd'
        je .d_pressed
        cmp al, 'a'
        je .a_pressed

        .w_pressed:
                xor ax, ax
                mov [Direction], byte 1
                ret

        .s_pressed:
                xor ax, ax
                mov [Direction], byte 2
                ret

        .d_pressed:
                xor ax, ax
                mov [Direction], byte 4
                ret

        .a_pressed:
                xor ax, ax
                mov [Direction], byte 3
                ret

        .done:
        ret

Delay:
        pusha
        pushf

        mov ah, 00h
        int 1Ah
        mov di, 2                                                               ; delay ~1.65 seconds 
        mov ah, 0
        int 1Ah
        mov bx, dx

        .delay_time:
                mov ah, 0
                int 1Ah
                sub dx, bx
                cmp di, dx
                ja .delay_time
                
        popf
        popa
        ret

Move_Snake:
        cmp [Direction], byte 1
        je .move_up

        cmp [Direction], byte 2
        je .move_down

        cmp [Direction], byte 3
        je .move_left

        cmp [Direction], byte 4
        je .move_right

        jmp .done
        
                                                                                ; We need to reposition the entire snake for the drawing process. 
        .move_up:                                                               ; We start at the back of the Array in this case we use the snake
                mov ax, [Snake_Y]                                               ; length
                dec ax                                                          ; Starting at the end, since we need to move the snakepart to the
                mov [Snake_Y], ax                                               ; prior snakepart
                jmp .prepare_loop_snake

        .move_down:
                mov ax, [Snake_Y]
                inc ax
                mov [Snake_Y], ax
                jmp .prepare_loop_snake

        .move_left:
                mov ax, [Snake_X]
                dec ax
                mov [Snake_X], ax
                jmp .prepare_loop_snake

        .move_right:
                mov ax, [Snake_X]
                inc ax
                mov [Snake_X], ax
                jmp .prepare_loop_snake      

        .prepare_loop_snake:
                xor bx, bx
                xor cx, cx
                imul bx, [Snake_Length], 2
                mov cx, [Snake_Length]
                .loop_snake:
                        mov ax, [SNAKEARRAY_Y-2+bx]
                        mov word [SNAKEARRAY_Y+bx], ax
                        mov ax, [SNAKEARRAY_X-2+bx]
                        mov word [SNAKEARRAY_X+bx], ax
                        cmp ax, [Snake_X]
                        jne .skip_y
                        mov ax, [SNAKEARRAY_Y+bx]
                        cmp ax, [Snake_Y]
                        je .lose
                        .skip_y:
                        dec bx
                        dec bx
                loop .loop_snake
                xor ax, ax
                mov ax, [Snake_Y]
                mov word [SNAKEARRAY_Y], ax
                mov ax, [Snake_X]
                mov word [SNAKEARRAY_X], ax

        .done:
        ret

        .lose:
                jmp .lose

Check_Wall:
        cmp [Snake_Y], byte -1
        je .check_for_up

        cmp [Snake_Y], byte 25
        je .check_for_down

        cmp [Snake_X], byte -1
        je .check_for_left

        cmp [Snake_X], byte 80
        je .check_for_right

        jmp .done

        .check_for_up:
                cmp [Direction], byte 1
                je .check_for_up
                ret

        .check_for_down:
                cmp [Direction], byte 2
                je .check_for_down
                ret

        .check_for_left:
                cmp [Direction], byte 3
                je .check_for_left
                ret

        .check_for_right:
                cmp [Direction], byte 4
                je .check_for_right
                ret

        .done:
        ret

Check_Apple_Collision:
        xor ax, ax
        mov ax, [Apple_Y]
        cmp [Snake_Y], ax
        jne .done

        .compare_x:
                xor ax, ax
                mov ax, [Apple_X]
                cmp [Snake_X], ax
                jne .done
                inc word [Snake_Length]

                .set_new_apple_coordinates:
                        xor ah, ah
                        int 01AH
                        mov ax, dx
                        xor dx, dx
                        mov cx, SCREEN_X
                        div cx
                        mov word [Apple_X], dx

                        xor ah, ah
                        int 01AH
                        mov ax, dx
                        xor dx, dx
                        mov cx, SCREEN_Y
                        div cx
                        mov word [Apple_Y], dx

        .done:
        ret

Check_Win_Condition:
        mov al, byte [Snake_Length]
        cmp al, WIN_CONDI
        je .win
        jne .done

        .win:
	        jmp .win

        .done:
                ret

game_loop:
        call Set_Background
        call Draw_Snake_Pos
        call Draw_Apple_Pos
        call Handle_Keystroke
        call Move_Snake
        call Check_Apple_Collision
        call Check_Win_Condition
        call Check_Wall
        call Delay
               
        jmp game_loop

times 510-($-$$)       db 0
db 055h
db 0AAh
