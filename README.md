# Pong game written in boot sector

# Size
512 bytes

# Run
nasm -f bin pong.asm -o boot.bin

qemu-system-x86_64 boot.bin