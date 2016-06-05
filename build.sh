#!/bin/bash

rm -f *.rom

BASE=atommc2-3.0

AVR_A000_ROM=${BASE}-a000-avr.rom
AVR_E000_ROM=${BASE}-e000-avr.rom
PIC_A000_ROM=${BASE}-a000-pic.rom
PIC_E000_ROM=${BASE}-e000-pic.rom


echo Assembling AVR
ca65 -l atomm2.a000.lst -o a000.o -DAVR atommc2.asm
ca65 -l atomm2.e000.lst -o e000.o -DAVR -D EOOO atommc2.asm

echo Linking AVR
ld65 a000.o -o ${AVR_A000_ROM} -C atommc2-a000.lkr 
ld65 e000.o -o ${AVR_E000_ROM} -C atommc2-e000.lkr 

echo Removing AVR object files
rm -f *.o

echo Assembling PIC
ca65 -l atomm2.a000.lst -o a000.o atommc2.asm
ca65 -l atomm2.e000.lst -o e000.o -D EOOO atommc2.asm

echo Linking PIC
ld65 a000.o -o ${PIC_A000_ROM} -C atommc2-a000.lkr 
ld65 e000.o -o ${PIC_E000_ROM} -C atommc2-e000.lkr 

echo Removing PIC object files
rm -f *.o

for i in ${AVR_A000_ROM} ${AVR_E000_ROM} ${PIC_A000_ROM} ${PIC_E000_ROM}
do
    truncate -s 4096 $i
    md5sum $i
done

