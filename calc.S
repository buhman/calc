        .macro _err
        lea .nop(%rip), %rdi
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
main:
        push %rbp
        mov %rsp, %rbp
        sub $0x80, %rsp
        lea -0x30(%rbp), %rbx

        mov $0, %r12
l0:
        mov $0, %edi
        lea -0x13(%rbp), %rsi
        mov $19, %rdx

        call read@plt

        cmp $0, %rax
        jge l1
        _err

l1:
        # zero-terminate
        movb $0, -0x13(%rbp, %rax)

        lea -0x13(%rbp), %rdi
        lea -0x8(%rbp), %rsi
        mov $10, %edx

        call strtoll@plt

        mov -0x8(%rbp), %rcx
        movzbl (%rcx), %ecx
        # %al == '\n'
        cmp $0xa, %cl
        # invalid
        jne op0

        ## avoid stack overflow
        lea -0x78(%rbp), %rcx
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
        ## p
        cmp $0x70, %cl
        jne ophelp

        jmp print

ophelp:
        ## h
        cmp $0x68, %cl
        jne opop

        lea .help(%rip), %rdi
        call printf@plt

        jmp l0
opop:
        ## avoid stack underflow
        lea -0x30(%rbp), %rax
        cmp %rax, %rbx
        jne opadd

        lea .under(%rip), %rdi
        call printf@plt

        jmp l0
opadd:
        ## +
        cmp $0x2b, %cl
        jne opsub

        _pop %rax
        add %rax, %r12

        jmp status
opsub:
        ## -
        cmp $0x2d, %cl
        jne opdiv

        _pop %rax
        sub %rax, %r12
        jmp status

opdiv:
        ## %
        cmp $0x25, %cl
        jne opmul

        _pop %rcx
        mov %r12, %rax
        ## sign-extend rax to rdx
        cqo
        idivq %rcx
        mov %rax, %r12
        jmp status

opmul:
        ## *
        cmp $0x2a, %cl
        jne opswap

        _pop %rax
        imul %rax, %r12
        jmp status

opswap:
        ## s
        cmp $0x73, %cl
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
        lea -0x78(%rbp), %rsi
        mov %rbx, %rdx
        call printf@plt
status:
        lea .sh(%rip), %rdi
        mov %r12, %rsi
        call printf@plt

        mov %rbx, %r13
istack:
        lea -0x30(%rbp), %rax
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
        add $0x80, %rsp
        pop %rbp
        ret

        .section .rodata
.under:
        .string "stack underflow\n"
.over:
        .string "stack overflow\n"
.nop:
        .string "nop\n"
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
'%': idiv; '*': imul; '-': sub; '+': add\n"
