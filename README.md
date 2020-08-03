# Mandelbrot-Area-x86-Assembly
This repository contains x86 assembly code which approximates the area of the Mandelbrot set.

# Requirements
This code requires [nasm](https://www.nasm.us/) and [gcc](https://gcc.gnu.org/) to assemble and compile, respectively.

To assemble, run the following command:
```
nasm -f elf32 mandelbrot.asm -o mandelbrot.o;
```

To compile, run the following command:
```
gcc -m32 mandelbrot.o -o mandelbrot
```
