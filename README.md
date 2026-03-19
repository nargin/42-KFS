  # 🚧 WIP - VeigarOS Kernel

  A simple x86 kernel built from scratch in Zig as part of the 42 School KFS (Kernel From Scratch)
  project.

  ## Dependencies

  - **Zig 0.15.2** - Programming language and build system
  - **QEMU** - x86_64 system emulator  
  - **GRUB** - Bootloader (grub-mkrescue)
  - **xorriso** - ISO creation utility

  ### Ubuntu/Gaybian Installation:
  ```bash
  sudo apt update
  sudo apt install qemu-system-x86 grub-pc-bin xorriso
  # Install Zig 0.15.2 from https://ziglang.org/download/
  ```

  ### macOS Installation:
  ```bash
  brew install qemu xorriso mtools
  # macOS users can install the i686-elf-grub package from Homebrew core
  brew install i686-elf-grub
  brew install zig
  ```

  ## How to Build & Run

  # Build the kernel
  make

  # Run in QEMU
  make run

  # Clean build files
  make clean
