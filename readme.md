# SodiumOS 
SodiumOS is a LFS (linux from scratch) distro.
## _To compile and boot_
**Follow these steps:**
> 1. Clone the linux kernel from the root folder
> 2. Compile all the files correctly
I can't list all the dependencies and for now compiling is manual.
There are many guides on the internet for cloning and compiling the linux kernel.
As for the two nim files and go init, you need the **Go** and **Nim** toolchains installed on your host system (e.g., `dnf install golang nim` or `apt install golang nim`).

__*NOTE: DO NOT COMPILE COMMANDS.NIM*__
> 3. Pack the initramfs directory
Head into the initramfs directory and run `find . | cpio -o -H newc | gzip > ../sodium.cpio.gz`
This command packs it into one file and compresses it.
> 4. boot
Configure your bootloader (like GRUB) to point to your kernel and `sodium.cpio.gz`, or launch it directly in a VM like QEMU
## Every compiled file should be statically linked

Soon i'll add a makefile to automate this