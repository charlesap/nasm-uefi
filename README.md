# asm-uefi
bare-bones assembly uefi shoe loader

assemble with:
* nasm -f bin shoex8664.asm -o shoex8664.efi
* dd if=toex8664.bin of=shoex8664.efi bs=1 seek=20480 conv=notrunc


combine with:
* sudo mount disk.iso mnt
* sudo cp shoex8664.efi mnt/EFI/BOOT/BOOTX64.EFI
* sudo cp shoeamd64.efi mnt/EFI/BOOT/BOOTAA64.EFI
* sudo cp shoeamd32.efi mnt/EFI/BOOT/BOOTAA32.EFI
* sudo cp shoeriscv64.efi mnt/EFI/BOOT/BOOTRV64.EFI
* sudo cp shoeriscv32.efi mnt/EFI/BOOT/BOOTRV32.EFI
* sudo umount mnt

get asm listing with:
* objdump -Mintel -d shoe.efi

show the bytes of the payload:
* hexdump -ve '1/1 "%.2x "' toe.bin

Launch QEMU with:

x86-64:
* /usr/bin/qemu-system-x86_64 -machine accel=kvm -name guest=uefiguest -machine pc,accel=kvm,usb=off,dump-guest-core=off  -smp 2,sockets=2,cores=1,threads=1 -uuid 515645b7-ab3a-4e82-ba62-25751e4b523f -bios ./OVMF.fd -m 1G  -vga qxl -spice port=5900,addr=127.0.0.1,disable-ticketing -drive file=disk.iso -serial stdio

aarch64:
/opt/qemu-risc6/aarch64-softmmu/qemu-system-aarch64 -m 1024 -cpu cortex-a57 -M virt -name guest=uefiguest -bios ./AARCH64-FLASH.img  -smp 2,sockets==1,threads=1 -uuid 515645b7-ab3a-4e82-ba62-25751e4b523f -m 1G -display gtk -monitor stdio -drive file=disk.iso

Launch the Spice viewer with:
* remote-viewer spice://localhost:5900




