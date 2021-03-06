RaspberryPi
===========
<br />
Raspberry Pi Bare Metal Code by krom (Peter Lemon).<br />
<br />
All code compiles out of box with the FASMARM assembler by revolution:<br />
http://arm.flatassembler.net<br />
I have included binaries of all the demos.<br />
<br />
Special thanks to Dex (Craig Bamford), who helped me get my 1st pixel on the screen =D<br />
Please check out DexOS, a lightning fast bare metal OS, & his Raspberry Pi port of DexBasic:<br />
http://www.dex-os.com<br />
http://www.dex-os.com/DexBasic/DexBasic.htm<br />
<br />
Also special thanks to phire, who helped me get my 1st triangle on the screen using the GPU =D<br />
<br />
For more information about coding the ARM CPU please visit my webpage that I run with SimonB:<br />
http://gbadev.org<br />
http://forum.gbadev.org<br />
<br />
Howto Compile:<br />
All the code compiles into a single binary (kernel.img) file.<br />
Using FASMARM open up kernel.asm and click the Run/Compile button.<br />
<br />
Howto Run:<br />
I only test with the latest bleeding edge firmware:<br />
https://github.com/raspberrypi/firmware/tree/master/boot<br />
<br />
You will need these 2 files:<br />
bootcode.bin<br />
start.elf<br />
<br />
You will need to create a "cmdline.txt" file that contains the line:<br />
coherent_pool=2M cma=2M smsc95xx.turbo_mode=Y<br />
<br />
You will need to create a "config.txt" file that contains the lines:<br />
disable_overscan=1<br />
disable_pvt=1<br />
force_turbo=1<br />
framebuffer_swap=0<br />
gpu_mem_256=160<br />
gpu_mem_512=316<br />
cma_lwm=16<br />
cma_hwm=32<br />
<br />
Check http://www.raspberrypi.org/documentation/configuration/config-txt.md for more info about config options.<br />
Check https://github.com/PeterLemon/RaspberryPi/tree/master/boot for .txt files.<br />
<br />
Once you have all these files ready, you can copy them & a kernel.img file to the root of an SD card.<br />
<br />
All of my demos use a maximum resolution of 640x480, they have been tested using composite & HDMI.<br />
<br />
All sound demos output to the 3.5" Phone Jack. Thanks to ne7 for the sound sample.<br />
