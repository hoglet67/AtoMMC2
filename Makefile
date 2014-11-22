#
# Makefile for AtomMMC.
#

#ASM=beebasm
ASM=atasm
SRC=cat.asm cfgcmd.asm cli.asm crc.asm exec.asm fatinfo.asm file.asm help.asm info.asm ir.asm \
load.asm run.asm save.asm util.asm DateTime.asm

all: AtomMMC

AtomMMC: $(SRC) 
	AsmDateTime -ATAsm > DateTime.asm
	$(ASM) -v -r -f255 -oatommc2.rom cli.asm > trace.lst
#	$(ASM) -i RamutilsBeeb.asm -do RAMUTIL.SSD -v > RamUtils.txt

