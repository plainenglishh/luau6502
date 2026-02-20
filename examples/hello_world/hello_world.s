.segment "CODE"
.org $FF00

start:
    ldx 0               ; use x to offset into msg

print_loop:
    lda msg,x           ; index msg+x
    beq done            ; if null char, go to done
    sta $6000           ; write char to 0x6000 (mapped to stdio.write)
    inx                 ; inc x index
    jmp print_loop      ; go back

done:
    .byte $02           ; jam

msg: 
    .asciiz "HELLO, WORLD!"

.segment "VECTORS"
.org $FFFC
.word start ; reset vector
