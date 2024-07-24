# PicoOS
A kernel for the RP2040 microcontroller

The kernel is loaded on the Flash Rom of the raspberry Pico,
His goal is to load a file on an SD card to execute it.
There will be syscalls to do anything.
Still in development.

All comments are in French, sorry for that.

# Boot process

When the Raspberry Pico turns on, 
A 256 bytes second stage is loaded by the bootrom (bootFlash.asm),
It will copy all the content of the flash rom to the RAM (adress 0x20000000)
Then gives control to it.

# Compilation Instructions

To compile on Flash :
  - Make sure that the two first lines of code are uncommented
  - Use FASMARM (An assembler for ARM) with this command : fasmarm kernel.asm kernel.bin
  - Download the python script uf2conv.py and do : python uf2conv.py kernel.bin --base 0x10000000 --family RP2040 --convert --output picoos.uf2

# Wiring

I'll make a shematic soon. But informations about what should be wired to what are in the code. 
