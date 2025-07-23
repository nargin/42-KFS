# VeigarOS Kernel

<p align="center">
  <img width="720" height="457" alt="image" src="https://github.com/user-attachments/assets/76b3e3ae-d001-453f-b678-20211b84d7ad" />
</p>


A minimal x86 operating system kernel written in Zig, designed for learning and educational purposes. This kernel fully complies with the 42 School KFS_1 (Kernel from Scratch) project requirements. The kernel features a multi-screen interface, keyboard input, scrollable logs, and VGA text-mode display.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Building](#building)
- [Running](#running)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [KFS_1 Assignment Compliance](#kfs_1-assignment-compliance)
- [Technical Details](#technical-details)
- [Compilation Flags](#compilation-flags)
- [Linker Script Details](#linker-script-details)
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
# Build kernel binary only (Zig compilation)
zig build

# Build bootable ISO (complete build process)
make all

# Clean build artifacts
make clean
```

### KFS_1 Build Process Details

The build system follows KFS_1 requirements for multi-language compilation:

**Step 1: Zig Kernel Compilation**
```bash
# Executed by: zig build
# Compiles: src/*.zig → zig-out/bin/kernel.elf
# Flags: Freestanding, i386 target, size-optimized
# Linker: Custom boot/linker.ld script
```

**Step 2: ISO Creation**
```bash
# Executed by: make all
mkdir -p isodir/boot/grub
cp zig-out/bin/kernel.elf isodir/boot/
cp boot/grub.cfg isodir/boot/grub/
grub-mkrescue -o kernel.iso isodir \
    --install-modules="multiboot" \
    --compress=xz \
    --locales="" \
    --themes="" \
    --fonts=""
```

**Build System Compliance**:
- ✅ **Makefile Required**: Complete Makefile with proper targets
- ✅ **Multi-language Support**: Handles Zig compilation + GRUB integration  
- ✅ **Correct Flags**: All KFS_1 equivalent flags applied
- ✅ **Custom Linking**: Uses boot/linker.ld for memory layout
- ✅ **Bootable Output**: Creates GRUB-compatible ISO image

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

## KFS_1 Assignment Compliance

This kernel implementation fully satisfies all mandatory requirements of the KFS_1 subject:

### ✅ Mandatory Requirements

- **GRUB Bootable Kernel**: Uses GRUB multiboot specification with proper boot configuration
- **ASM Boot Code**: Multiboot header and assembly entry point implemented in Zig inline assembly
- **Basic Kernel Library**: Memory operations, string handling, I/O functions, and VGA display interface
- **Screen Interface**: Complete VGA text mode implementation with character and string output
- **Custom Linker Script**: GNU LD linker script with proper memory layout and section alignment
- **i386 Architecture**: Targets x86 (32-bit) with proper CPU feature configuration
- **Proper Compilation**: Freestanding compilation with kernel-appropriate flags
- **Size Limit**: 1.1MB ISO (well under 10MB requirement)
- **Makefile**: Complete build system supporting multiple languages

### ✅ Bonus Features Implemented

- **Scroll and Cursor Support**: Hardware VGA cursor control and scrollable content
- **Colors Support**: Full VGA color attribute system with themed interface
- **Printf/Printk Helpers**: Formatted output using `std.fmt.bufPrint`
- **Keyboard Input**: Complete PS/2 keyboard driver with character processing
- **Multiple Screens**: 4-screen interface (Main, Status, Logs, About) with F1-F4 navigation

### Technical Compliance Details

**Language Choice**: Zig chosen for kernel-friendly features:
- No runtime dependencies (freestanding compilation)
- Compile-time memory safety without runtime overhead
- Direct hardware access capabilities
- Cross-compilation support for x86 target

**Boot Process**: Follows multiboot specification:
- Magic number: `0x1BADB002`
- Flags: `ALIGN | MEMINFO` (0x00000003)
- Checksum: `-(MAGIC + FLAGS)`
- Entry point: `_start` with proper stack setup

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
- **Target Architecture**: i386 (x86 32-bit) - **MANDATORY per KFS_1**
- **Boot Protocol**: Multiboot specification v1 (magic: 0x1BADB002)
- **Display**: VGA text mode (80x25 characters, direct buffer access at 0xB8000)
- **Input**: PS/2 keyboard controller (ports 0x60/0x64)
- **CPU Features**: Disabled MMX/SSE/AVX (soft-float enabled)

### KFS_1 Architecture Compliance

**i386 (x86) Mandatory Architecture**:
```zig
// Explicit i386 targeting in build.zig:
.cpu_arch = std.Target.Cpu.Arch.x86,    // 32-bit x86 (i386)
```

**Multiboot Header Structure**:
```zig
const ALIGN = 1 << 0;           // Page alignment flag
const MEMINFO = 1 << 1;         // Memory info flag  
const MAGIC = 0x1BADB002;       // Multiboot magic number
const FLAGS = ALIGN | MEMINFO;  // Combined flags

const MultibootHeader = packed struct {
    magic: i32 = MAGIC,         // Must be 0x1BADB002
    flags: i32,                 // Feature flags
    checksum: i32,              // -(magic + flags)
    padding: u32 = 0,
};
```

**VGA Hardware Access**:
```zig
// Direct VGA buffer manipulation:
pub const VGA_BUFFER = @as([*]volatile u16, @ptrFromInt(0xB8000));
pub const VGA_WIDTH = 80;      // Standard VGA text width
pub const VGA_HEIGHT = 25;     // Standard VGA text height

// Hardware cursor control via VGA registers:
fn setCursorPosition(x: usize, y: usize) void {
    const pos: u16 = @intCast(y * VGA_WIDTH + x);
    outb(0x3D4, 0x0F);          // Cursor low byte register
    outb(0x3D5, @intCast(pos & 0xFF));
    outb(0x3D4, 0x0E);          // Cursor high byte register  
    outb(0x3D5, @intCast((pos >> 8) & 0xFF));
}
```

**Assembly Entry Point**:
```zig
export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\ movl %[stack_top], %%esp    # Set stack pointer
        \\ movl %%esp, %%ebp           # Set base pointer
        \\ call %[kmain:P]             # Call kernel main
        :
        : [stack_top] "i" (@as([*]align(16) u8, @ptrCast(&stack_bytes)) + @sizeOf(@TypeOf(stack_bytes))),
          [kmain] "X" (&kmain),
    );
}
```

### Build Configuration
- **Optimization**: Size-optimized with frame pointer omission
- **Linking**: Custom linker script with kernel code model
- **Debug Info**: Stripped for minimal binary size
- **Threading**: Single-threaded kernel design

## Compilation Flags

The kernel uses Zig's target configuration to achieve the equivalent of KFS_1 required C++ compilation flags:

### Required KFS_1 Flags (C++ Reference)
```bash
# Original C++ flags from KFS_1 subject:
-fno-builtin      # Disable built-in functions
-fno-exception    # Disable C++ exceptions
-fno-stack-protector  # Disable stack protection
-fno-rtti         # Disable runtime type information
-nostdlib         # Don't link standard library
-nodefaultlibs    # Don't use default libraries
```

### Zig Implementation Equivalents
```zig
// In build.zig - Zig target configuration:
const target_query = std.Target.Query{
    .cpu_arch = std.Target.Cpu.Arch.x86,        // i386 architecture
    .os_tag = std.Target.Os.Tag.freestanding,   // Equivalent to -nostdlib
    .abi = std.Target.Abi.none,                 // No ABI dependencies
    .cpu_features_sub = disabled_features,       // Disable MMX/SSE/AVX
    .cpu_features_add = enabled_features,        // Enable soft-float
};

// Build configuration:
.code_model = .kernel,          // Kernel code model
.strip = true,                  // Remove debug symbols
.single_threaded = true,        // No threading support
.omit_frame_pointer = true,     // Equivalent to -fomit-frame-pointer
```

### Disabled CPU Features (Freestanding Compliance)
```zig
// Explicitly disabled for kernel compatibility:
disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));

// Enabled for freestanding operation:
enabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));
```

### Compilation Compliance
- **No Built-in Functions**: Zig freestanding mode provides no implicit dependencies
- **No Exceptions**: Zig has no exception system (uses error unions instead)
- **No Stack Protector**: Disabled by freestanding target
- **No RTTI**: Zig has compile-time type reflection, no runtime overhead
- **No Standard Library**: `freestanding` OS tag prevents std lib linking
- **No Default Libraries**: Custom linker script controls all linking

## Linker Script Details

Custom GNU LD linker script (`boot/linker.ld`) following KFS_1 requirements:

```ld
ENTRY(_start)                    # Entry point symbol

SECTIONS {
    . = 2M;                      # Load address at 2MB (0x200000)

    .text : ALIGN(4K) {          # Code section (4KB aligned)
        KEEP(*(.multiboot))      # Preserve multiboot header
        *(.text)                 # All code sections
    }
 
    .rodata : ALIGN(4K) {        # Read-only data (4KB aligned)
        *(.rodata)
    }
 
    .data : ALIGN(4K) {          # Initialized data (4KB aligned)
        *(.data)
    }
 
    .bss : ALIGN(4K) {           # Uninitialized data (4KB aligned)
        *(COMMON)
        *(.bss)
    }
}
```

### Linker Script Compliance
- **Custom Linker Required**: Cannot use host system's default linker script
- **GNU LD Compatible**: Uses standard GNU LD syntax and directives
- **Memory Layout Control**: Explicit section placement and alignment
- **Multiboot Preservation**: `KEEP(*(.multiboot))` prevents garbage collection
- **Kernel Load Address**: 2MB physical address as per x86 conventions

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
- **ISO Image**: 1.1MB (down from 12MB) - **WELL UNDER 10MB KFS_1 LIMIT**
- **Total Reduction**: Over 90% size reduction achieved
- **KFS_1 Compliance**: 1.1MB ÷ 10MB limit = 11% utilization

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
2. Test thoroughly in QEMU emulator
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

## License

This project is for educational purposes. Feel free to study, modify, and experiment with the code.

## Contributors

- Robin (Original implementation)
- Claude (AI assistant contributions)

---

For questions or issues, please refer to the source code or create an issue in the project repository.
