# 512-Byte Boot Sector Pong Game


No OS, no drivers — just x86 assembly and BIOS.
512 bytes exactly. Boots in QEMU.

# Size
512 bytes

# Run
nasm -f bin pong.asm -o boot.bin
qemu-system-x86_64 boot.bin


#Controls
W/S (paddle), C (colors), R (reset)
