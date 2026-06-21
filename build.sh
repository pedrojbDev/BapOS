#!/usr/bin/env bash
set -e

export PATH="$HOME/Documents/MyOS/toolchain/opt/cross/bin:$PATH"

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
KERNEL_DIR="$PROJECT_ROOT/kernel"
ISO_DIR="$PROJECT_ROOT/isodir"

echo "[1/5] Montando boot.s..."
i686-elf-as "$KERNEL_DIR/boot.s" -o "$KERNEL_DIR/boot.o"

echo "[2/5] Compilando kernel.c..."
i686-elf-gcc -c "$KERNEL_DIR/kernel.c" -o "$KERNEL_DIR/kernel.o" \
    -std=gnu99 \
    -ffreestanding \
    -O2 \
    -Wall \
    -Wextra

echo "[3/5] Linkando kernel.elf..."
i686-elf-gcc \
    -T "$KERNEL_DIR/linker.ld" \
    -o "$KERNEL_DIR/kernel.elf" \
    -ffreestanding \
    -O2 \
    -nostdlib \
    "$KERNEL_DIR/boot.o" \
    "$KERNEL_DIR/kernel.o" \
    -lgcc

echo "[4/5] Atualizando estrutura da ISO..."
mkdir -p "$ISO_DIR/boot/grub"
cp "$KERNEL_DIR/kernel.elf" "$ISO_DIR/boot/kernel.elf"

echo "[5/5] Gerando BapOS.iso..."
grub2-mkrescue -o "$PROJECT_ROOT/BapOS.iso" "$ISO_DIR"

echo
echo "Build concluído com sucesso."
echo "ISO gerada em: $PROJECT_ROOT/BapOS.iso"
