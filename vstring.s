;
; Copyright (c) 2021 Ali Muhammed. All rights reserved.
;         Use is subject to license terms.
;            See LICENSE for details.
;

%ifndef VSTRING_S
%define VSTRING_S

%define VLPN	0xFFFFFFFFFFFFFFE0

; <-- [byte RAX] memccpy([byte RDI] s1, [byte RSI] s2, EDX c, RCX n) -->
vmemccpy:
    push rbx
    xor eax, eax
    mov r9, rcx
	and rcx, VLPN
    je .loop
    xor r8, r8
    vmovd xmm0, edx
    vpbroadcastb ymm0, xmm0
.loopv:
    vmovdqu ymm1, [rsi+r8]
    vpcmpeqb ymm2, ymm1, ymm0
    vpmovmskb eax, ymm2
    test eax, eax
    jne .stopv
    vmovdqu [rdi+r8], ymm1
    add r8, 32
    cmp r8, rcx
    jb .loopv
    xor eax, eax
.loop:
    cmp rcx, r9
    je .exit
    movzx ebx, byte [rsi+rcx]
    mov [rdi+rcx], bl
    inc rcx
    cmp ebx, edx
    jne .loop
    lea rax, [rdi+rcx]
.exit:
    pop rbx
    ret
.stopv:
    bsf eax, eax
    lea rcx, [r8+rax+1]
    lea rax, [rdi+rcx]
.cpy:
    dec rcx
    mov dl, [rsi+rcx]
    mov [rdi+rcx], dl
    cmp rcx, r8
    ja .cpy
    pop rbx
    ret
; -----> endof memccpy <-----

; <-- [byte RAX] memchr(ro [byte RDI] s, ESI c, RDX n) -->
vmemchr:
    mov rcx, rdx
    and rcx, VLPN
    je .stop
    vmovd xmm0, esi
    vpbroadcastb ymm0, xmm0
    mov r8, -32
.loopv:
    add r8, 32
    cmp rcx, r8
    je .stop
    vpcmpeqb ymm1, ymm0, [rdi+r8]
    vpmovmskb eax, ymm1
    bsf eax, eax
    je .loopv
    lea rcx, [r8+rax]
.exit:
    lea rax, [rdi+rcx]
    ret
.loop:
    movzx eax, byte [rdi+rcx]
    cmp eax, esi
    je .exit
    inc rcx
.stop:
    cmp rcx, rdx
    jb .loop
    xor eax, eax
    ret
; -----> endof memchr <-----

; <-- EAX memcmp([byte RDI] s1, [byte RSI] s2, RDX n) -->
vmemcmp:
	mov r9, rdx
	and r9, VLPN
    mov r8, -32
.loopv:
    add r8, 32
    cmp r8, r9
    je .stop
    vmovdqu ymm0, [rdi+r8]
    vpcmpeqb ymm0, [rsi+r8]
    vpmovmskb eax, ymm0
    not eax
    je .loopv
    bsf eax, eax
    add r8, rax
    movzx eax, byte [rdi+r8]
    movzx ecx, byte [rsi+r8]
.exit:
    sub eax, ecx
    ret
.loop:
    movzx eax, byte [rdi+r8]
    movzx ecx, byte [rsi+r8]
    cmp eax, ecx
    jne .exit
    inc r8
.stop:
    cmp r8, rdx
    jne .loop
    xor eax, eax
    ret
; -----> endof memcmp <-----

; <-- [byte RAX] memcpy([byte RDI] s1, ro [byte RSI] s2, RDX n) -->
vmemcpy:
	xor ecx, ecx
	mov rax, rdx
	and rax, VLPN
	je .exit
.loopv:
	vmovdqu ymm0, [rsi+rcx]
	vmovdqu [rdi+rcx], ymm0
	add rcx, 32
	cmp rcx, rax
	jb .loopv
	jmp .exit
.loop:
	mov al, [rsi+rcx]
	mov [rdi+rcx], al
	inc rcx
.exit:
	cmp rcx, rdx
	jne .loop
	mov rax, rdi
	ret
; -----> endof memcpy <-----

; <-- [byte RAX] memmove([byte RDI] s1, ro [byte RSI] s2, RDX n) -->
vmemmove:
	mov rcx, rdx
	and rcx, VLPN
	je .exit
.loopv:
	sub rdx, 32
	vmovdqu ymm0, [rsi+rdx]
	vmovdqu [rdi+rdx], ymm0
	cmp rdx, rcx
	ja .loopv
	jmp .exit
.loop:
	dec rdx
	mov al, [rsi+rdx]
	mov [rdi+rdx], al
.exit:
	test rdx, rdx
	ja .loop
	mov rax, rdi
	ret
; -----> endof memmove <-----

; <-- [byte RAX] memset([byte RDI] s, ESI c, RDX n) -->
vmemset:
	mov rax, rdi
	mov rcx, rdx
	and rcx, VLPN
	jmp .loopout
.loop:
	dec rdx
	mov [rax+rdx], sil
.loopout:
	cmp rdx, rcx
	ja .loop
	test rcx, rcx
	je .exit
	vmovd xmm0, esi
	vpbroadcastb ymm0, xmm0
.loopv:
	sub rcx, 0h20
	vmovdqu [rax+rcx], ymm0
	test rcx, rcx
	jne .loopv
.exit:
	ret
; -----> endof memset <-----

; <-- bzero([byte RDI] s, RSI n) -->
vbzero:
	xor eax, eax
	mov rcx, rsi
	and rcx, VLPN
	jmp .stop
.loop:
	dec rsi
	mov [rdi+rsi], al
.stop:
	cmp rsi, rcx
	ja .loop
	vpxor xmm0, xmm0
	jmp .exit
.loopv:
	sub rcx, 32
	vmovdqu [rdi+rcx], ymm0
.exit:
	test rcx, rcx
	jne .loopv
	ret
; -----> endof bzero <-----

%undef VLPN

%endif
