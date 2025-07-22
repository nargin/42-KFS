# VeigarOS Kernel

<p align="center">
  <img width="720" height="457" alt="image" src="https://github.com/user-attachments/assets/76b3e3ae-d001-453f-b678-20211b84d7ad" />
</p>


A minimal x86 operating system kernel written in Zig, designed for learning and educational purposes. The kernel features a multi-screen interface, keyboard input, scrollable logs, and VGA text-mode display.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Building](#building)
- [Running](#running)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Technical Details](#technical-details)
- [Size Optimizations](#size-optimizations)
- [Development](#development)

## Overview

VeigarOS is a freestanding x86 kernel that boots via GRUB and provides a basic interactive terminal interface. The kernel is designed to be minimal yet functional, demonstrating core OS concepts like hardware abstraction, input handling, and memory management.

## Features

- **Multi-screen Interface**: Four different screens accessible via F1-F4 keys
  - F1: Main terminal with interactive input
  - F2: System status and information
  - F3: Kernel logs with scrolling
  - F4: About screen
- **Interactive Input**: Full keyboard support with cursor movement
- **Scrollable Content**: Navigate through command history and logs using arrow keys
- **VGA Text Mode**: 80x25 character display with color support
- **Hardware Cursor**: Proper VGA cursor positioning and visibility control
- **Input Safety**: Bounds checking prevents buffer overflows and crashes
- **Size Optimized**: Ultra-compact kernel (17KB) and ISO (4.1MB)

## Architecture

The kernel follows a modular architecture with clear separation of concerns:

```
src/
├── main.zig        # Kernel entry point and main loop
├── vga.zig         # VGA hardware abstraction layer
├── screens.zig     # Screen rendering and management
├── input.zig       # Input handling and processing
└── keyboard.zig    # PS/2 keyboard driver
```

### Core Modules

- **main.zig**: Multiboot compliant entry point, initialization, and event loop
- **vga.zig**: Direct VGA buffer manipulation and hardware cursor control
- **screens.zig**: Multi-screen rendering, data persistence, and scrolling logic
- **input.zig**: Character input processing, arrow key handling, and screen switching
- **keyboard.zig**: Low-level PS/2 keyboard driver with scancode translation

## Requirements

### System Dependencies

Ubuntu/Debian:
```bash
sudo apt-get install -y zig qemu-system-x86 grub-pc-bin grub-common xorriso make
```

Arch Linux:
```bash
sudo pacman -S zig qemu-system-x86 grub xorriso make
```

### Minimum Versions
- Zig 0.11.0 or higher
- GRUB 2.0 or higher
- QEMU 3.0 or higher
- xorriso 1.4.0 or higher

## Building

### Standard Build
```bash
# Build kernel binary only
zig build

# Build bootable ISO
make all

# Clean build artifacts
make clean
```

### Size-Optimized Build
```bash
# Build with maximum size optimization
zig build --release=small

# Build optimized ISO (4.1MB instead of 12MB)
make clean && zig build --release=small && make all
```

### Build Flags

**Zig Build Options:**
- `--release=small` - Optimize for minimum binary size
- `--release=fast` - Optimize for execution speed  
- `--release=safe` - Optimize with safety checks enabled
- `--summary=[mode]` - Control build output verbosity
- `-j<N>` - Set number of parallel build jobs

**Make Targets:**
- `make all` - Build complete bootable ISO
- `make clean` - Remove all build artifacts
- `make run` - Build and run in QEMU emulator
- `make re` - Clean, build, and run (rebuild everything)

## Running

### QEMU Emulation
```bash
# Run with default settings
make run

# Manual QEMU invocation with custom options
qemu-system-x86_64 -cdrom kernel.iso -vga std -m 512M -serial stdio -no-reboot -no-shutdown
```

### Real Hardware
The generated `kernel.iso` can be written to USB drives or burned to CD/DVD for testing on real hardware.

**USB Flash Drive:**
```bash
sudo dd if=kernel.iso of=/dev/sdX bs=4M status=progress
```

**CD/DVD Burning:**
```bash
brasero kernel.iso
# or
cdrecord -v dev=/dev/sr0 kernel.iso
```

## Usage

### Screen Navigation
- **F1**: Main terminal screen with input capability
- **F2**: System status and kernel information
- **F3**: Scrollable kernel logs
- **F4**: About screen with project information

### Input Controls
- **Arrow Keys**: 
  - Left/Right: Move cursor within input field (F1 only)
  - Up/Down: Scroll through content on Main and Logs screens
- **Enter**: Submit input command (F1 only)
- **Backspace**: Delete characters from input
- **Printable Characters**: Type into input field

### Screen-Specific Features

**Main Screen (F1):**
- Interactive command input with 71-character limit
- Command history with 25-entry scrollable buffer
- Real-time input display with hardware cursor

**Logs Screen (F3):**
- 50-entry scrollable log buffer
- Automatic logging of user inputs
- Visual scroll indicators showing position

## Project Structure

```
KFS/
├── src/                    # Source code
│   ├── main.zig           # Kernel entry and main loop
│   ├── vga.zig            # VGA hardware layer
│   ├── screens.zig        # Screen management
│   ├── input.zig          # Input handling
│   └── keyboard.zig       # Keyboard driver
├── boot/                  # Boot configuration
│   ├── grub.cfg          # GRUB bootloader config
│   └── linker.ld         # Linker script
├── build.zig             # Zig build configuration
├── Makefile              # Build automation
└── README.md             # This file
```

## Technical Details

### Memory Layout
- **Kernel Load Address**: 2MB physical (0x200000)
- **Stack Size**: 16KB allocated in BSS section
- **VGA Buffer**: 0xB8000 (direct memory mapping)
- **Character Buffers**: Statically allocated arrays

### Hardware Interface
- **Target Architecture**: x86 (32-bit)
- **Boot Protocol**: Multiboot specification
- **Display**: VGA text mode (80x25 characters)
- **Input**: PS/2 keyboard controller (ports 0x60/0x64)
- **CPU Features**: Disabled MMX/SSE/AVX (soft-float enabled)

### Build Configuration
- **Optimization**: Size-optimized with frame pointer omission
- **Linking**: Custom linker script with kernel code model
- **Debug Info**: Stripped for minimal binary size
- **Threading**: Single-threaded kernel design

## Size Optimizations

The kernel implements several size optimization techniques:

### Kernel Binary Optimizations
- **Release Mode**: `--release=small` for maximum size reduction
- **Symbol Stripping**: Debug symbols removed from final binary
- **Frame Pointer Omission**: Reduces stack frame overhead
- **Buffer Reduction**: Minimized screen and log buffer sizes
- **String Optimization**: Shortened text strings and messages

### ISO Image Optimizations
- **Minimal GRUB**: Only essential multiboot module included
- **XZ Compression**: Maximum compression for all components
- **No Internationalization**: Removed locales and fonts
- **No Themes**: Stripped visual customization components
- **Direct Boot**: Simplified boot configuration without menus

### Results
- **Kernel Binary**: 17KB (down from 463KB)
- **ISO Image**: 4.1MB (down from 12MB)
- **Total Reduction**: Over 95% size reduction achieved

## Development

### Code Style
- **Minimal Imports**: Only essential standard library usage
- **Direct Hardware Access**: No abstraction layers where possible
- **Static Allocation**: Compile-time memory allocation preferred
- **Modular Design**: Clear separation between hardware and logic layers

### Testing
```bash
# Quick functionality test
timeout 5s qemu-system-x86_64 -cdrom kernel.iso -display none

# Interactive testing
make run
```

### Debugging
- **Serial Output**: Kernel logs available via QEMU serial console
- **QEMU Monitor**: Access via Ctrl+Alt+2 during execution
- **Memory Inspection**: Use QEMU memory commands for debugging

### Adding Features
When extending the kernel:
1. Keep size optimization in mind
2. Test on both emulator and real hardware
3. Maintain modular architecture
4. Update buffer sizes if needed
5. Verify input bounds checking

## Advanced Build Options

### Custom QEMU Options
```bash
# Run with custom memory and display settings
qemu-system-x86_64 -cdrom kernel.iso \
    -vga std \
    -m 1024M \
    -serial stdio \
    -no-reboot \
    -no-shutdown \
    -cpu pentium3
```

### ISO Customization
The Makefile supports several GRUB optimization flags:
- `--install-modules="multiboot"` - Include only essential modules
- `--compress=xz` - Maximum compression
- `--locales=""` - Remove internationalization
- `--themes=""` - Remove visual themes
- `--fonts=""` - Remove custom fonts

### Cross-Platform Building
The kernel targets x86 architecture and should build on any system with the required dependencies. The Zig compiler handles cross-compilation automatically.

## Troubleshooting

### Common Build Issues
- **Missing zig**: Install Zig compiler for your platform
- **GRUB not found**: Install grub-pc-bin and grub-common packages
- **ISO creation fails**: Install xorriso package
- **QEMU not launching**: Install qemu-system-x86 package

### Runtime Issues
- **Black screen**: Check VGA compatibility settings in QEMU
- **No keyboard input**: Ensure PS/2 keyboard emulation is enabled
- **Crashes on real hardware**: Verify BIOS compatibility and boot settings

## License

This project is for educational purposes. Feel free to study, modify, and experiment with the code.

## Contributors

- Robin (Original implementation)
- Claude (AI assistant contributions)

---

For questions or issues, please refer to the source code or create an issue in the project repository.
