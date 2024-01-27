ASM=nasm

SRC_DIR=snake

SRCFILES := snake.asm

.Phony: clean, .force-rebuild

all: snake.bin

snake.bin: snake.asm
	@nasm -fbin snake.asm -o snake.bin
	@sudo dd if=snake.bin of=/dev/fd0
	@qemu-system-i386 -fda snake.bin

clean:
	@rm snake.bin
