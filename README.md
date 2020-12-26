# asm-uefi
bare-bones assembly uefi shoe loader

assemble for x8664 with:
* nasm -f bin shoe-x8664.asm -o shoe-x8664.efi
* dd if=toe-x8664.bin of=shoe-x8664.efi bs=1 seek=20480 conv=notrunc

assemble for rv64 with:
* /home/riscv/bin/riscv64-unknown-elf-as shoe-rv64.S -o shoe-rv64.efi

assemble for aa64 with:
* /home/arm/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-as shoe-aa64.S -o shoe-aa64.efi

assemble for aa32 with:
* /home/arm/gcc-arm-none-eabi-9-2019-q4-major/arm-none-eabi/bin/as -mcpu=cortex-m4  shoe-aa32.S -o shoe-aa32.efi


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

riscv64:
/opt/qemu-risc6/riscv64-softmmu/qemu-system-riscv64    -nographic    -machine virt    -smp 4    -m 2G    -kernel ./Fedora-Minimal-Rawhide-20191123.n.1-fw_payload-uboot-qemu-virt-smode.elf    -bios none    -object rng-random,filename=/dev/urandom,id=rng0    -device virtio-rng-device,rng=rng0    -device virtio-blk-device,drive=hd0    -drive file=Fedora-Minimal-Rawhide-20191123.n.1-sda.raw,format=raw,id=hd0    -device virtio-net-device,netdev=usernet    -netdev user,id=usernet,hostfwd=tcp::10000-:22

Launch the Spice viewer with:
* remote-viewer spice://localhost:5900




