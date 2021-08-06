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

; <-- [byte RAX] stpcpy([byte RDI] s1, ro [byte RSI] s2) -->
vstpcpy:
	vpxor xmm0, xmm0
	xor ecx, ecx
.loopv:
	vmovdqu ymm1, [rsi+rcx]
	vpcmpeqb ymm2, ymm1, ymm0
	vpmovmskb eax, ymm2
	test eax, eax
	jne .exit
	vmovdqu [rdi+rcx], ymm1
	add rcx, 32
	jmp .loopv
.loop:
	inc rcx
.exit:
	movzx edx, byte [rsi+rcx]
	mov [rdi+rcx], dl
	test edx, edx
	jne .loop
	lea rax, [rdi+rcx]
	ret
; -----> endof stpcpy <-----

; <-- [byte RAX] stpncpy([byte RDI] s1, ro [byte RSI] s2, RDX n) -->
vstpncpy:
	xor ecx, ecx
	mov r8, rdx
	and r8, VLPN
	je .loop
	vpxor xmm0, xmm0
.loopv:
	vmovdqu ymm1, [rsi+rcx]
	vpcmpeqb ymm2, ymm1, ymm0
	vpmovmskb eax, ymm2
	test eax, eax
	jne .stopv
	vmovdqu [rdi+rcx], ymm1
	add rcx, 32
	cmp rcx, r8
	jb .loopv
	jmp .loop
.stopv:
	movzx eax, byte [rsi+rcx]
	mov [rdi+rcx], al
	inc rcx
	test eax, eax
	jne .stopv
	lea rax, [rdi+rcx-1]
	ret
.loop:
	cmp rcx, rdx
	je .exit
	movzx eax, byte [rsi+rcx]
	mov [rdi+rcx], al
	inc rcx
	test eax, eax
	jne .loop
	dec rcx
.exit:
	lea rax, [rdi+rcx]
	ret
; -----> endof stpncpy <-----

; <-- [byte RAX] strcat([byte RDI] s1, ro [byte RSI] s2) -->
vstrcat:
	mov rax, rdi
	vpxor xmm0, xmm0
	sub rdi, 32
.skipv:
	add rdi, 32
	vpcmpeqb ymm1, ymm0, [rdi]
	vpmovmskb ecx, ymm1
	bsf ecx, ecx
	je .skipv
	add rdi, rcx
.loopv:
	vmovdqu ymm1, [rsi]
	vpcmpeqb ymm2, ymm1, ymm0
	vpmovmskb ecx, ymm2
	bsf ecx, ecx
	jne .loop
	vmovdqu [rdi], ymm1
	add rdi, 32
	add rsi, 32
	jmp .loopv
.loop:
	movzx edx, byte [rsi]
	mov [rdi], dl
	inc rdi
	inc rsi
	test edx, edx
	jne .loop
	ret
; -----> endof strcat <-----

; <-- [byte RAX] strncat([byte RDI] s1, ro [byte RSI] s2, RDX n) -->
vstrncat:
	push rdi
	vpxor xmm0, xmm0
	sub rdi, 32
.skipv:
	add rdi, 32
	vpcmpeqb ymm1, ymm0, [rdi]
	vpmovmskb ecx, ymm1
	bsf ecx, ecx
	je .skipv
	add rdi, rcx
	xor ecx, ecx
	mov r8, rdx
	and r8, VLPN
	je .loop
.loopv:
	vmovdqu ymm1, [rsi+rcx]
	vpcmpeqb ymm2, ymm1, ymm0
	vpmovmskb eax, ymm2
	test eax, eax
	jne .stopv
	vmovdqu [rdi+rcx], ymm1
	add rcx, 32
	cmp rcx, r8
	jb .loopv
.loop:
	cmp rcx, rdx
	je .exit
	movzx eax, byte [rsi+rcx]
	mov [rdi+rcx], al
	inc rcx
	test eax, eax
	jne .loop
.exit:
	pop rax
	ret
.stopv:
	movzx eax, byte [rsi+rcx]
	mov [rdi+rcx], al
	inc rcx
	test eax, eax
	jne .stopv
	pop rax
	ret
; -----> endof strncat <-----

; <-- EAX strcmp(ro [byte RDI] s1, ro [byte RSI] s2) -->
vstrcmp:
	vpxor xmm0, xmm0
	mov rcx, -32
.loopv:
	add rcx, 32
	vmovdqu ymm1, [rdi+rcx]
	vmovdqu ymm2, [rsi+rcx]
	vpcmpeqb ymm3, ymm1, ymm0
	vpmovmskb eax, ymm3
	test eax, eax
	jne .loop
	vpcmpeqb ymm3, ymm2, ymm0
	vpmovmskb eax, ymm3
	test eax, eax
	jne .loop
	vpcmpeqb ymm3, ymm2, ymm1
	vpmovmskb eax, ymm3
	not eax
	je .loopv
	bsf eax, eax
	add rcx, rax
	movzx eax, byte [rdi+rcx]
	movzx edx, byte [rsi+rcx]
.exit:
	sub eax, edx
	ret
.loop:
	movzx eax, byte [rdi+rcx]
	movzx edx, byte [rsi+rcx]
	test eax, eax
	je .exit
	inc rcx
	sub eax, edx
	je .loop
	ret
; -----> endof strcmp <-----

; <-- EAX strncmp(ro [byte RDI] s1, ro [byte RSI] s2, EDX n) -->
vstrncmp:
	xor eax, eax
	xor ecx, ecx
	mov r8, rdx
	and rdx, VLPN
	je .loop
	vpxor xmm0, xmm0
	sub rcx, 32
.loopv:
	add rcx, 32
	cmp rcx, rdx
	je .loop
	vmovdqu ymm1, [rdi+rcx]
	vmovdqu ymm2, [rsi+rcx]
	vpcmpeqb ymm3, ymm1, ymm0
	vpmovmskb eax, ymm3
	test eax, eax
	jne .stopv
	vpcmpeqb ymm3, ymm2, ymm0
	vpmovmskb eax, ymm3
	test eax, eax
	jne .stopv
	vpcmpeqb ymm3, ymm2, ymm1
	vpmovmskb eax, ymm3
	not eax
	je .loopv
	bsf eax, eax
	add rcx, rax
	movzx eax, byte [rdi+rcx]
	movzx edx, byte [rsi+rcx]
.exit:
	sub eax, edx
	ret
.stopv:
	movzx eax, byte [rdi+rcx]
	movzx edx, byte [rsi+rcx]
	test eax, eax
	je .exit
	inc rcx
	sub eax, edx
	je .stopv
	ret
.loop:
	cmp rcx, r8
	je .stop
	movzx eax, byte [rdi+rcx]
	movzx edx, byte [rsi+rcx]
	test eax, eax
	je .exit
	inc rcx
	sub eax, edx
	je .loop
.stop:
	ret
; -----> endof strncmp <-----

; <-- [byte RAX] strchr(ro [byte RDI], ESI c) -->
vstrchr:
    vpxor xmm0, xmm0
    vmovd xmm1, esi
    vpbroadcastb ymm1, xmm1
    sub rdi, 32
.loopv:
    add rdi, 32
    vmovdqu ymm2, [rdi]
    vpcmpeqb ymm3, ymm2, ymm0
    vpmovmskb eax, ymm3
    test eax, eax
    jne .loop
    vpcmpeqb ymm3, ymm2, ymm1
    vpmovmskb eax, ymm3
    bsf eax, eax
    je .loopv
    add rax, rdi
    ret
.loop:
    movzx eax, byte [rdi]
    cmp eax, esi
    je .exit
    inc rdi
    test eax, eax
    jne .loop
	xor eax, eax
	ret
.exit:
    mov rax, rdi
    ret
; -----> endof strchr <-----

; <-- [byte RAX] strrchr(ro [byte RDI] s, ESI c) -->
vstrrchr:
	vpxor xmm0, xmm0
	vmovd xmm1, esi
	vpbroadcastb ymm1, xmm1
	mov rcx, -32
.skipv:
	add rcx, 32
	vpcmpeqb ymm2, ymm0, [rdi+rcx]
	vpmovmskb eax, ymm2
	bsf eax, eax
	je .skipv
	add rcx, rax
	mov r8, rcx
	and r8, VLPN
	je .stop
	inc rcx
	mov rdx, rcx
	sub rdx, r8
.loopv:
	sub rcx, 32
	vpcmpeqb ymm2, ymm1, [rdi+rcx]
	vpmovmskb eax, ymm2
	bsr eax, eax
	jne .stopv
	cmp rcx, rdx
	ja .loopv
	jmp .stop
.stopv:
	add rcx, rax
	lea rax, [rdi+rcx]
	ret
.loop:
	dec rcx
.stop:
	movzx eax, byte [rdi+rcx]
	cmp eax, esi
	je .exit
	test rcx, rcx
	jne .loop
	xor eax, eax
	ret
.exit:
	lea rax, [rdi+rcx]
	ret
; -----> endof strrchr <-----

; <-- [byte RAX] strcpy([byte RDI] s1, ro [byte RSI] s2) -->
vstrcpy:
    xor ecx, ecx
	vpxor xmm0, xmm0
    jmp .loopv
.vcpy:
    vmovdqu [rdi+rcx], ymm1
    add rcx, 32
.loopv:
    vmovdqu ymm1, [rsi+rcx]
    vpcmpeqb ymm2, ymm1, ymm0
    vpmovmskb eax, ymm2
    test eax, eax
    je .vcpy
    bsf eax, eax
    lea rax, [rcx+rax]
.loop:
    mov dl, [rsi+rcx]
    mov [rdi+rcx], dl
    inc rcx
    cmp rcx, rax
    jbe .loop
    mov rax, rdi
    ret
; -----> endof strcpy <-----

; <-- [byte RAX] strncpy([byte RDI] s1, ro [byte RSI] s2, RDX n) -->
vstrncpy:
    xor ecx, ecx
    mov r8, rdx
	and r8, VLPN
    je .loop
    vpxor xmm0, xmm0
.loopv:
    vmovdqu ymm1, [rsi+rcx]
    vpcmpeqb ymm2, ymm1, ymm0
    vpmovmskb eax, ymm2
    test eax, eax
    jne .stopv
    vmovdqu [rdi+rcx], ymm1
    add rcx, 32
    cmp rcx, r8
    jb .loopv
.loop:
    cmp rcx, rdx
    je .exit
    movzx eax, byte [rsi+rcx]
    mov [rdi+rcx], al
    inc rcx
    test eax, eax
    jne .loop
.exit:
    mov rax, rdi
    ret
.stopv:
    movzx eax, byte [rsi+rcx]
    mov [rdi+rcx], al
    inc rcx
    test eax, eax
    jne .stopv
    mov rax, rdi
    ret
; -----> endof strncpy <-----

; <-- RAX strlen(ro [byte RDI] s) -->
vstrlen:
	vpxor xmm0, xmm0
	mov rcx, -32
.loop:
	add rcx, 32
	vpcmpeqb ymm1, ymm0, [rdi+rcx]
	vpmovmskb eax, ymm1
	bsf eax, eax
	je .loop
	add rax, rcx
	ret
; -----> endof strlen <-----

; <-- RAX strnlen(ro [byte RDI] s, RSI n) -->
vstrnlen:
	xor eax, eax
	mov rcx, rsi
	and rcx, VLPN
	je .loop
	vpxor xmm0, xmm0
.loopv:
	vpcmpeqb ymm1, ymm0, [rdi+rax]
	vpmovmskb edx, ymm1
	bsf edx, edx
	jne .stopv
	add rax, 32
	cmp rax, rcx
	jb .loopv
	jmp .loop
.stopv:
	add rax, rdx
	ret
.loop:
	cmp rax, rsi
	je .exit
	movzx edx, byte [rdi+rax]
	inc rax
	test edx, edx
	jne .loop
	dec rax
.exit:
	ret
; -----> endof strnlen <-----

; <-- RAX strlcpy([byte RDI] s1, ro [byte RSI] s2, RDX n) -->
vstrlcpy:
	vpxor xmm0, xmm0
	mov rax, -32
	xor r8, r8
.loopv:
	add rax, 32
	vmovdqu ymm1, [rsi+rax]
	vpcmpeqb ymm2, ymm1, ymm0
	vpmovmskb ecx, ymm2
	bsf ecx, ecx
	jne .stopv
	cmp rax, rdx
	jae .loopv
	add r8, rax
	vmovdqu [rdi+r8], ymm1
	jmp .loopv
.stopv:
	add rax, rcx
	test rdx, rdx
	je .exit
	cmp rax, rdx
	cmovb r9, rax
	cmovae r9, rdx
.loop:
	cmp r8, r9
	je .stop
	movzx ecx, byte [rsi+r8]
	mov [rdi+r8], cl
	test ecx, ecx
	je .exit
	inc r8
	jmp .loop
.stop:
	lea rcx, [r8-1]
	cmp rdx, rax
	cmova rcx, r8
	xor edx, edx
	mov [rdi+rcx], dl
.exit:
	ret
; -----> endof strlcpy <-----

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
