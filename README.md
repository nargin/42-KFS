  # 🚧 WIP - VeigarOS Kernel

  A simple x86 kernel built from scratch in Zig as part of the 42 School KFS (Kernel From Scratch)
  project.

  ## Dependencies

  - **Zig 0.15.1** - Programming language and build system
  - **QEMU** - x86_64 system emulator  
  - **GRUB** - Bootloader (grub-mkrescue)
  - **xorriso** - ISO creation utility

  ### Ubuntu/Debian Installation:
  ```bash
  sudo apt update
  sudo apt install qemu-system-x86 grub-pc-bin xorriso
  # Install Zig 0.15.1 from https://ziglang.org/download/

  How to Build & Run

  # Build the kernel
  make

  # Run in QEMU
  make run

  # Clean build files
  make clean
