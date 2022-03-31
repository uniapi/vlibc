;
; Copyright (c) 2022 Ali Muhammed. All rights reserved.
;         Use is subject to license terms.
;            See LICENSE for details.
;

%ifndef VSTRING_S
%define VSTRING_S


; <-- [byte RAX] memccpy([byte RDI] s1, ro [byte RSI] s2, EDX c, RCX n) -->
vmemccpy:
	vmovd xmm0, edx
	vpbroadcastb zmm0, xmm0
	xor eax, eax
	mov rdx, rcx
	and rdx, 0xFFFFFFFFFFFFFFC0
	je .v
.vloop:
	vmovdqu8 zmm1, [rsi+rax]
	vpcmpub k1, zmm1, zmm0, 0
	ktestq k1, k1
	jne .vstop
	vmovdqu8 [rdi+rax], zmm1
	add rax, 64
	cmp rax, rdx
	jb .vloop
.v:
	sub rcx, rdx
	je .exit
	xor edx, edx
	dec rdx
	shl rdx, cl
	not rdx
	kmov k1, rdx
	vmovdqu8 zmm1 {k1}, [rsi+rax]
	vpcmpub k0 {k1}, zmm0, zmm1, 0
	ktestq k0, k0
	je .vld
	kmovq k1, k0
.vstop:
	xor edx, edx
	dec rdx
	kmov rcx, k1
	bsf rcx, rcx
	inc rcx
	shl rdx, cl
	not rdx
	kmov k1, rdx
.vld:
	vmovdqu8 [rdi+rax] {k1}, zmm1
.exit:
	mov rax, rdi
	ret
; -----> endof memccpy <-----

; <-- [byte RAX] memchr[ro [byte RDI], ESI c, RDX n) -->
vmemchr:
	movd xmm0, esi
	vpbroadcastb zmm0, xmm0
	xor eax, eax
	xor esi, esi
	mov rcx, rdx
	and rdx, 0xFFFFFFFFFFFFFFC0
	je .v
.vloop:
	vpcmpub k1, zmm0, [rdi+rsi], 0
	ktestq k1, k1
	jne .vstop
	add rsi, 64
	cmp rdx, rsi
	jb .vloop
.v:
	sub rcx, rdx
	je .exit
	xor edx, edx
	dec rdx
	shl rdx, cl
	not rdx
	kmov k1, rdx
	vpcmpub k1 {k1}, zmm0, [rdi+rsi], 0
	ktestq k1, k1
	je .exit
.vstop:
	kmov rax, k1
	bsf rax, rax
	add rax, rdi
	add rax, rsi
.exit:
	ret
; -----> endof memchr <-----

; <-- EAX memcmp(ro [byte RDI] s1, ro [byte RSI] s2, RDX n) -->
vmemcmp:
	mov rcx, rdx
	and rdx, 0xFFFFFFFFFFFFFFC0
	je .v
	mov rax, rdx
	xor edx, edx
.vloop:
	vmovdqu8 zmm0, [rdi+rdx]
	vpcmpub k0, zmm0, [rsi+rdx], 0b100
	ktestq k0, k0
	jne .vstop
	add rdx, 64
	cmp rdx, rax
	jb .vloop
.v:
	xor eax, eax
	sub rcx, rdx
	je .exit
	vmovdqu8 zmm0, [rdi+rdx]
	dec rax
	shl rax, cl
	not rax
	kmov k1, rax
	vpcmpub k0 {k1}, zmm0, [rsi+rdx], 0b100
.vstop:
	kmov rax, k0
	bsf rax, rax
	add rdx, rax
	movzx eax, byte [rdi+rdx]
	movzx ecx, byte [rsi+rdx]
	sub eax, ecx
.exit:
	ret
; -----> endof memcmp <-----

; <-- [byte RAX] memcpy([byte RDI] s1, ro [byte RSI] s2, RDX n) -->
vmemcpy:
	mov rcx, rdx
	and rdx, 0xFFFFFFFFFFFFFFC0
	je .v
	xor eax, eax
.vloop:
	vmovdqu8 zmm0, [rsi+rax]
	vmovdqu8 [rdi+rax], zmm0
	add rax, 64
	cmp rax, rdx
	jb .vloop
.v:
	sub rcx, rdx
	je .exit
	xor eax, eax
	dec rax
	shl rax, cl
	not rax
	kmov k1, rax
	vmovdqu8 zmm0 {k1}, [rsi+rdx]
	vmovdqu8 [rdi+rdx] {k1}, zmm0
.exit:
	mov rax, rdi
	ret
; -----> endof memcpy <-----

; <-- [byte RAX] memset([byte RDI] s, ESI c, RDX n) -->
vmemset:
	vmovd xmm0, esi
	vpbroadcastb zmm0, xmm0
	xor eax, eax
	mov rcx, rdx
	and rdx, 0xFFFFFFFFFFFFFFC0
	je .vstop
.vloop:
	vmovdqu8 [rdi+rax], zmm0
	add rax, 64
	cmp rax, rdx
	jb .vloop
.vstop:
	sub rcx, rdx
	je .exit
	xor edx, edx
	dec rdx
	shl rdx, cl
	not rdx
	kmov k1, rdx
	vmovdqu8 [rdi+rax] {k1}, zmm0
.exit:
	mov rax, rdi
	ret
; -----> endof memset <-----

; <-- bzero([byte RDI] s, RSI n) -->
vbzero:
    vpxor xmm0, xmm0
	mov rcx, rsi
    and rsi, 0xFFFFFFFFFFFFFFC0
    je .v
    xor edx, edx
.vloop:
    vmovdqu8 [rdi+rdx], zmm0
    add rdx, 64
    cmp rdx, rsi
    jb .vloop
.v:
	sub rcx, rsi
	je .exit
	xor edx, edx
	dec rdx
	shl rdx, cl
	not rdx
	kmov k1, rdx
	vmovdqu8 [rdi+rsi] {k1}, zmm0
.exit:
    ret
; -----> endof bzero <-----

%endif
