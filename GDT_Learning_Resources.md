# GDT Learning Resources

## Core Concepts
- [OSDev Wiki - GDT](https://wiki.osdev.org/GDT) - Best starting point, explains what GDT is and why you need it
- [OSDev Wiki - GDT Tutorial](https://wiki.osdev.org/GDT_Tutorial) - Step-by-step implementation guide

## Understanding x86 Segmentation
- [Intel Software Developer Manual Vol 3A, Chapter 3](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html) - Official but dense
- [GDT Explained Simply](http://www.jamesmolloy.co.uk/tutorial_html/4.-The%20GDT%20and%20IDT.html) - Good conceptual overview

## Zig-Specific Examples
- Search GitHub for "zig kernel gdt" to see real implementations
- [Zig bare metal examples](https://github.com/ZigEmbeddedGroup/microzig) - Has x86 low-level code patterns

## Key Topics to Understand First
1. **What is segmentation** - Why x86 has this legacy system
2. **Descriptor format** - How to encode segment properties in 8 bytes  
3. **Privilege levels** - Ring 0 (kernel) vs Ring 3 (user)
4. **Flat memory model** - Modern approach using 0-4GB segments

## Practical Learning Path
1. Read OSDev GDT page to understand the "why"
2. Study the descriptor bit layout diagram
3. Look at a simple C implementation first
4. Adapt to Zig syntax (packed structs work great)

The OSDev wiki is really your best friend here - it's written specifically for kernel developers and covers all the gotchas.