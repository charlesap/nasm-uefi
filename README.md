# nasm-uefi
bare-bones nasm uefi application

build with:
* nasm -f bin shoe.asm -o shoe.efi
* dd if=toe.bin of=shoe.efi bs=1 seek=20480 conv=notrunc
* sudo mount disk.iso mnt
* sudo cp shoe.efi mnt/EFI/BOOT/BOOTX64.EFI
* sudo umount mnt

get asm listing with:
* objdump -Mintel -d shoe.efi

show the bytes of the payload:
* hexdump -ve '1/1 "%.2x "' toe.bin

Launch QEMU with:

* /usr/bin/qemu-system-x86_64 -machine accel=kvm -name guest=uefiguest -machine pc,accel=kvm,usb=off,dump-guest-core=off  -smp 2,sockets=2,cores=1,threads=1 -uuid 515645b7-ab3a-4e82-ba62-25751e4b523f -bios ./OVMF.fd -m 1G  -vga qxl -spice port=5900,addr=127.0.0.1,disable-ticketing -drive file=disk.iso -serial stdio

Launch the Spice viewer with:
* remote-viewer spice://localhost:5900




