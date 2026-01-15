#!/usr/bin/env bash

if [ $# -ne 1 ]; then
    FILENAME="exo2_unmodified.S"
else
    FILENAME="$1"
fi

RISCV_GCC=riscv-none-elf-gcc
RISCV_LD=riscv-none-elf-ld
RISCV_OBJCPY=riscv-none-elf-objcopy

(
    $RISCV_GCC -c -g -mabi=ilp32 -march=rv32i -O0 "$FILENAME" -o exo2.o &&
    echo "Successfully compiled '$FILENAME' to object file." &&

    $RISCV_LD --build-id=none -Bstatic -T firmware_riscv.ld -Map firmware.map exo2.o -o firmware.elf &&
    echo "Successfully linked '$FILENAME'." &&

    $RISCV_OBJCPY -j .text -O verilog --verilog-data-width 4 firmware.elf imem.hex &&
    echo "Successfully generated instruction memory hex file." &&

    $RISCV_OBJCPY -j .rodata -j .data --change-section-address .data-0x10000 --change-section-address .rodata-0x10000 -O verilog --verilog-data-width 4 firmware.elf dmem.hex &&
    echo "Successfully generated data memory hex file."
) || (
    echo "An error occurred in the compilation process!"
    exit 1
)