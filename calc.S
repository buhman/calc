        .macro _err arg
        lea \arg, %rdi
        call perror@plt
        jmp end
        .endm

        .macro _push arg
        sub $0x8, %rbx
        mov \arg, (%rbx)
        .endm

        .macro _pop arg
        mov (%rbx), \arg
        add $0x8, %rbx
        .endm

        .text
        .globl main
        .set frame_size, 0x80
        .set stack_base, -0x30
        .set buflen, 20
        .set buf, (stack_base + buflen)
        .set ptr, (buf + 8)
main:
        push %rbp
        mov %rsp, %rbp
        sub $frame_size, %rsp
        lea stack_base(%rbp), %rbx

        mov $0, %r12
l0:
        mov $0, %edi
        lea buf(%rbp), %rsi
        mov $buflen, %rdx

        call read@plt

        cmp $0, %rax
        jge l1
        _err .nop(%rip)

l1:
        # zero-terminate
        movb $0, buf(%rbp, %rax)

        lea buf(%rbp), %rdi
        lea ptr(%rbp), %rsi
        mov $10, %edx

        call strtoll@plt

        mov ptr(%rbp), %rcx
        movzbl (%rcx), %ecx
        # %al == '\n'
        cmp $'\n', %cl
        # invalid
        jne op0

        ## avoid stack overflow
        lea (8 - frame_size)(%rbp), %rcx
        cmp %rcx, %rbx
        jne _push

        lea .over(%rip), %rdi
        call printf@plt
        jmp l0

_push:
        _push %r12
        mov %rax, %r12

        jmp status

op0:
        ## print
        cmp $'p', %cl
        jne ophelp

        jmp print

ophelp:
        ## help
        cmp $'h', %cl
        jne opop

        lea .help(%rip), %rdi
        call printf@plt

        jmp l0
opop:
        ## avoid stack underflow
        lea stack_base(%rbp), %rax
        cmp %rax, %rbx
        jne opadd

        lea .under(%rip), %rdi
        call printf@plt

        jmp l0
opadd:
        ## add
        cmp $'+', %cl
        jne opsub

        _pop %rax
        add %rax, %r12

        jmp status
opsub:
        ## sub
        cmp $'-', %cl
        jne opdiv

        _pop %rax
        sub %rax, %r12
        jmp status

opdiv:
        ## div
        cmp $'/', %cl
        jne opmul

        _pop %rcx
        mov %r12, %rax
        ## sign-extend rax to rdx
        cqo
        idivq %rcx
        mov %rax, %r12
        jmp status

opmul:
        ## mul
        cmp $'*', %cl
        jne opswap

        _pop %rax
        imul %rax, %r12
        jmp status

opswap:
        ## swap
        cmp $'s', %cl
        jne opnop

        _pop %rax
        _push %r12
        mov %rax, %r12
        jmp status

opnop:
        lea .nop(%rip), %rdi
        call puts@plt

        jmp l0

print:
        lea .status(%rip), %rdi
        lea (8 - frame_size)(%rbp), %rsi
        mov %rbx, %rdx
        call printf@plt
status:
        lea .sh(%rip), %rdi
        mov %r12, %rsi
        call printf@plt

        mov %rbx, %r13
istack:
        lea stack_base(%rbp), %rax
        cmp %rax, %r13
        je estack

        lea .se(%rip), %rdi
        mov (%r13), %rsi
        call printf@plt

        add $0x8, %r13
        jmp istack
estack:
        lea .st(%rip), %rdi
        call printf@plt
        jmp l0
end:
        add $frame_size, %rsp
        pop %rbp
        ret

        .section .rodata
.under:
        .string "stack underflow\n"
.over:
        .string "stack overflow\n"
.nop:
        .string "nop"
.status:
        .string "> top: %p; rbx: %p\n"
.sh:
        .string ">> %lld"
.st:
        .string "\n"
.se:
        .string " %lld"
.help:
        .string "'[0-9]+': push; 's': swap; 'h': help; 'p': print\n\
'/': idiv; '*': imul; '-': sub; '+': add\n"
