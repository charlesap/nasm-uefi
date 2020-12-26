disk.iso : shoe-x64.efi shoe-aa64.efi shoe-aa32.efi shoe-rv64.efi shoe-rv32.efi
	mkdir -p mnt ;\
	   mount disk.iso mnt ;\
           cp shoe-x64.efi mnt/EFI/BOOT/BOOTX64.EFI ;\
           cp shoe-aa64.efi mnt/EFI/BOOT/BOOTAA64.EFI ;\
           cp shoe-aa32.efi mnt/EFI/BOOT/BOOTAA32.EFI ;\
           cp shoe-rv64.efi mnt/EFI/BOOT/BOOTRV64.EFI ;\
           cp shoe-rv32.efi mnt/EFI/BOOT/BOOTRV32.EFI ;\
           umount mnt

shoe-x64.efi : shoe-x64.asm toe-x64.bin
		nasm -f bin shoe-x64.asm -o shoe-x64.efi ;\
                dd if=toe-x64.bin of=shoe-x64.efi bs=1 seek=20480 conv=notrunc

shoe-aa64.efi : shoe-aa64.S toe-aa64.bin
	        /home/arm/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-as shoe-aa64.S -o shoe-aa64.efi ;\
                dd if=toe-aa64.bin of=shoe-x8664.efi bs=1 seek=20480 conv=notrunc

shoe-aa32.efi : shoe-aa32.S toe-aa32.bin
	        /home/arm/gcc-arm-none-eabi-9-2019-q4-major/arm-none-eabi/bin/as -mcpu=cortex-m4  shoe-aa32.S -o shoe-aa32.efi ;\
                dd if=toe-aa32.bin of=shoe-x8664.efi bs=1 seek=20480 conv=notrunc

shoe-rv64.efi : shoe-rv64.S toe-rv64.bin
		/home/riscv/bin/riscv64-unknown-elf-as shoe-rv64.S -o shoe-rv64.efi ;\
                dd if=toe-rv64.bin of=shoe-x8664.efi bs=1 seek=20480 conv=notrunc

shoe-rv32.efi : shoe-rv32.S toe-rv32.bin
	        /home/riscv/bin/riscv64-unknown-elf-as shoe-rv32.S -o shoe-rv32.efi ;\
                dd if=toe-rv32.bin of=shoe-x8664.efi bs=1 seek=20480 conv=notrunc

clean : 
	rm shoe-x64.efi shoe-aa64.efi shoe-aa32.efi shoe-rv64.efi shoe-rv32.efi 

