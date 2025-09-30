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

  Features

  - ✅ GRUB multiboot compliant
  - ✅ VGA text mode display
  - ✅ Keyboard input handling
  - ✅ Multiple terminal screens (F1-F4)
  - ✅ Basic UI with scrolling
  - 🚧 Working on: GDT implementation, memory management

  Project Structure

  kernel/
  ├── main.zig           # Kernel entry point
  ├── drivers/           # Hardware drivers (VGA, keyboard)
  ├── arch/x86/          # x86-specific code
  ├── ui/                # User interface code
  └── utils/             # Shared types and constants

  Assignment Progress

  - ✅ KFS-1: Basic bootable kernel with screen output
  - 🚧 KFS-2: GDT & Stack management (in progress)

  Notes

  This is a learning project for understanding low-level system programming and kernel development
  concepts.
