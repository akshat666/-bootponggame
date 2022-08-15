use16
org 0x7c00


jmp init_game           ; Jump to initializing the game

;;Constants
VIDEOMEM equ 0xB800     ; Video memory location set to char colour
ROWLENGTH equ 160       ; 80 chars * 2 bytes for each char
PLAYERX equ 4           ; Player X position 
CPUX equ 154
KEY_W equ 0X11
KEY_S equ 0X1F
KEY_C equ 0X2E
KEY_R equ 0X13
SCREENH equ 25
SCREENW equ 80
PADDLEH equ 5

;;Variables
drawColour:     db 0xF0
playerY:        dw 10        ; Start player Y position 10 rows down
cpuY:           dw 10        ; Start cpu Y position 10 rows down
ballX:          dw 66        ; Ball X position 
ballY:          dw 7         ; Ball Y position
ballVeloX:      db -1        ; Ball velocity X
ballVeloY:      db 1         ; Ball velocity Y


;; =================== LOGIC START ===================

init_game:

    ;; Setup video mode
    mov ax, 0x003                   ; Set video mode BIOS interupt 10h AH00h; AL = 03h text mode 80x25 chars, 16 colour VGA
    int 10h

    ;; Set up video memory
    mov ax, VIDEOMEM
    mov es, ax                      ;ES:di <- B800:0000

;; Game loop
game_loop:

    ;;Clear screen in every loop
    xor ax,ax
    xor di, di
    mov cx, 80*25
    rep stosw               ; Copy cx times ax to [ES:DI] pointer location

    ;;Draw middle line
    mov ah, [drawColour]    ; Define white bg , black fg
    mov di, 78              ; move di counter - 39 (80/2) is the middle of the screen * 2 bytes for char = 78
    mov cl, 13              ; For 13 vertical lines - 'Dash' line - draw on each row (25/2)    
    
    draw_middle_loop:
        stosw
        add di, ROWLENGTH*2 - 2     ; Only draw every other row (80 char * 2 bytes * 2 rows) 
        loop draw_middle_loop


    ;; Draw player paddle
    imul di, [playerY], ROWLENGTH   ; Y positon is Y no of rows * length of row
    add di, PLAYERX
    mov cl, PADDLEH
    draw_player_loop:
        stosw
        add di, ROWLENGTH - 2 
        loop draw_player_loop

    ;; Draw cpu paddle
    imul di, [cpuY], ROWLENGTH   ; Y positon is Y no of rows * length of row
    add di, CPUX
    mov cl, PADDLEH

    draw_cpu_loop:
        stosw
        add di, ROWLENGTH - 2 
        loop draw_cpu_loop


    ;; Player input
    mov ah, 1
    int 0x16
    jz move_cpu_up

    cbw                             ; Zero out AH in one byte
    int 0x16

    cmp ah, KEY_W
    je w_pressed
    cmp ah, KEY_S
    je s_pressed
    cmp ah, KEY_C
    je c_pressed
    cmp ah, KEY_R
    je r_pressed

    jmp move_cpu_up

    ;; Move paddle up
    w_pressed:
        dec word [playerY]
        jge move_cpu_up
        inc word [playerY]
        jmp move_cpu_up

    ;;Move paddle down
    s_pressed:
        cmp word [playerY], SCREENH - PADDLEH
        jge move_cpu_up
        inc word [playerY]
        jmp move_cpu_up


    ;; Change paddle and mid line colour
    c_pressed:
        add byte [drawColour], 0x10
        jmp move_cpu_up

    ;; Reset game to initial values
    r_pressed:
        int 0x19                    ; Relad the boot sector



    ;; Move CPU
    move_cpu_up:
        mov bx, [cpuY]
        cmp bx, [ballY]             ; CPU paddle top of ball ?
        jle move_cpu_down           ; If yes, continue
        dec word [cpuY]             ; No ? move cpu up
        jnz move_ball
        inc word [cpuY]             ; Cpu hit top area - come down

    move_cpu_down:
        add bx, PADDLEH
        cmp bx, [ballY]             ; Bottom of CPU paddle below the ball ?
        jge move_ball               ; Yes - continue
        inc word [cpuY]             ; No? Move cpu down
        cmp word [cpuY], 24         ; Cpu paddle at bottom ?
        jl move_ball
        dec word [cpuY]


    ;; Draw ball
    move_ball:
        ;; Draw ball in current position
        imul di, [ballY], ROWLENGTH   ; Y positon is Y no of rows * length of row
        add di, [ballX]
        mov word [es:di], 0x2020
    
        ; ;; Move ball to next position
        mov bl, [ballVeloX]
        add [ballX], bl
        mov bl, [ballVeloY]
        add [ballY], bl
        
    ;; Check hit top
    check_hit_top:
        cmp word [ballY], 0
        jg check_hit_bottom
        neg byte [ballVeloY]
        jmp end_collision_checks

    check_hit_bottom: 
        cmp word [ballY], 25
        jl check_hit_player
        neg byte [ballVeloY]
        jmp end_collision_checks

    check_hit_player:
        cmp word [ballX], PLAYERX
        jne check_hit_cpu
        mov bx, [playerY]
        mov bx, [ballY]
        jg check_hit_cpu
        add bx, PADDLEH
        cmp word bx, [ballY]
        jl check_hit_cpu
        neg byte [ballVeloX]

    check_hit_cpu:


    end_collision_checks:


;; Move ball

    ; Deply timer for next cycle
    mov bx, [0x46C]
    inc bx
    inc bx

    delay:
        cmp [0x46C], bx
        jl delay

jmp game_loop

; win or lose condition


;; =================== LOGIC END ===================

times 510 - ($ - $$) db 0
dw 0xaa55                     ; End of boot sector