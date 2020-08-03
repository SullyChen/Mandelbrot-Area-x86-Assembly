global main
extern printf

section .data
  zr dd 0.0 ;real part of z
  zi dd 0.0 ;imaginary part of z
  cr dd 0.6 ;real part of c
  ci dd 0.5 ;imaginary part of c

  precision dd 255 ;how many iterations to run per pixel

  magnitude dd 0.0 ;magnitude squared of complex number

  area dd 0

  pixel_num dd 262144 ;512*512

  msg db "The computed area of the mandelbrot set is: %f", 0x0a, 0x00

section .text

main:
  ;set FPU rounding mode to round up
  sub esp, 2
  fstcw [esp]
  mov ax, [esp]
  and ah, 11110011b
  or ah, 00000100b
  mov [esp], ax
  fldcw [esp]
  add esp, 2

  call compute

  ;lastly, compute area
  fstp st0 ;clear FPU register
  fild dword [area]
  mov [area], dword __float32__(0.00003433227) ; 9/512^2
  fld dword [area]
  fmul
  fstp dword [area]

  ;print result
  sub ebp, 8
  fld dword [area]
  fstp qword [esp] ;printf takes a double, so float must be converted first
  push msg
  call printf
  add esp, 12

  ;return 0
  mov eax, 1
  mov ebx, 0
  int 0x80

;computes cr and ci
compute_px:
  push ebp
  mov ebp, esp
  fstp st0 ;clear FPU registers

  ;compute cr
  mov eax, dword [pixel_num]
  and eax, dword 511 ;compute modulo 512

  mov [cr], dword __float32__(0.005859375) ;transform constant 3/512
  fld dword [cr]
  mov [cr], eax ;pixel x-coordinate
  fild dword [cr]
  fmul

  mov [cr], dword __float32__(-2.2) ;translation factor
  fld dword [cr]
  fadd
  fstp dword [cr]

  ;compute ci
  mov eax, dword [pixel_num]
  shr eax, 9 ;divide by 512
  mov [ci], dword eax
  fild dword [ci]
  mov [ci], dword __float32__(0.005859375) ;transform constant 3/512
  fld dword[ci]
  fmul
  mov [ci], dword __float32__(-1.5) ;translation factor
  fld dword [ci]
  fadd
  fstp dword [ci]

  mov esp, ebp
  pop ebp
  ret

iterate:
  push ebp
  mov ebp, esp

  fstp st0 ;pop stack

  ;compute zr^2, push to stack
  fld dword [zr]
  fld dword [zr]
  fmul
  sub esp, 4 ;allocate stack
  fstp dword [esp]

  ;perform zr^2 - zi^2 + cr, overwrite stack
  fld dword [zi]
  fld dword [zi]
  fmul
  fld dword [esp]
  fsub st0, st1
  fld dword [cr]
  fadd
  fstp dword [esp]

  ;perform zi=2*zr*zi + ci
  fld dword [zr]
  fld dword [zi]
  fmul
  push __float32__(2.0)
  fld dword [esp]
  add esp, 4
  fmul
  fld dword [ci]
  fadd
  fstp dword [zi]

  mov eax, dword [esp]
  mov [zr], eax
  pop esp

  mov esp, ebp
  pop ebp
  ret

compute_abs:
  push ebp
  mov ebp, esp

  fstp st0 ;clear FPU registers

  ;perform magnitude = zr^2 + zi^2
  fld dword [zr]
  fld dword [zr]
  fmul
  fld dword [zi]
  fld dword [zi]
  fmul
  fadd
  fstp dword [magnitude]

  mov esp, ebp
  pop ebp
  ret

compute:
  push ebp
  mov ebp, esp

  main_loop:
    ;zero variables
    mov [zr], dword __float32__(0.0)
    mov [zi], dword __float32__(0.0)
    mov [cr], dword __float32__(0.0)
    mov [ci], dword __float32__(0.0)
    mov [magnitude], dword __float32__(0.0)

    call compute_px ;compute current pixel coord

    ;iterate pixel value
    mov ecx, [precision]
    for:
      call iterate ;compute one iteration
      call compute_abs ;compute magnitude after iteration

      ;check if magnitude is greater or equal to 4, if so, break
      fstp st0 ;zero FPU register
      fld dword [magnitude]
      fistp dword [magnitude] ;convert magnitude to int, rounding down
      mov eax, [magnitude]
      cmp eax, dword 4
      jge loop_check ;if magnitude is greater than 4, jump to loop check
    loop for ;keep iterating if magnitude is less than 4

    ;if magnitude remained under 4, code will reach this area increment statement
    inc dword [area]

    loop_check:
    dec dword [pixel_num] ;move on to next pixel

    ;check to make sure we aren't done processing pixels
    mov eax, dword [pixel_num]
    cmp eax, 0
  jge main_loop ; jump if pixel_num >= 0, otherwise return

  mov esp, ebp
  pop ebp
  ret
