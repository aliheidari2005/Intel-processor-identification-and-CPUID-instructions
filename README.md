x86 CPUID Feature & Topology Explorer

A modular, low-level Assembly language project designed to interact directly with x86 hardware using the CPUID instruction.

This project implements various CPU identification algorithms based on Intel® Processor Identification and the CPUID Instruction (Application Note 485). Unlike standard tools, this repository breaks down each CPUID function into standalone assembly modules, making it an educational resource for understanding system programming, register manipulation, and hardware topology detection.

🚀 Project Overview

The goal of this project is to demystify how Operating Systems identify underlying hardware. Each module focuses on a specific "Leaf" of the CPUID instruction:

Key Features Implemented:

Core Detection: Validates CPUID instruction support by manipulating the EFLAGS ID bit (Bit 21).

Cache Hierarchy (Leaf 04h): Extracts deterministic cache parameters (Line Size, Associativity, Sets) to calculate exact L1/L2/L3 cache sizes.

Processor Topology (Leaf 0Bh): Parses the Extended Topology Enumeration to identify Threads, Cores, and Packages (x2APIC).

Feature Detection (Leaf 01h): Decodes standard feature flags (FPU, SSE, MMX, etc.) and processor signature.

Power Management (Leaf 06h): Detects Digital Thermal Sensors (DTS), Turbo Boost, and Always Running APIC Timer (ARAT).

Performance Monitoring (Leaf 0Ah): Enumerates Architectural Performance Monitoring features (PMU).

Extended Features: Supports extended functions like Processor Brand String, Physical/Virtual Address sizes, and Invariant TSC.

Example Output

Here is a sample output from running the tools on an Intel Core i7 processor:

1. Cache Hierarchy Analysis (./leaf_04_cache)

--- CPUID (EAX=4, ECX=0) ---
EAX: 0x1C004121 (Type: Data, Level: 1, Cores: 8)
EBX: 0x01C0003F (LineSize: 64, Ways: 8)
ECX: 0x0000003F (Sets: 64)
Calculated Size: 32 KB

--- CPUID (EAX=4, ECX=2) ---
EAX: 0x1C004143 (Type: Unified, Level: 2, Cores: 8)
EBX: 0x03C0003F (LineSize: 64, Ways: 16)
ECX: 0x000003FF (Sets: 1024)
Calculated Size: 1024 KB (1 MB)

--- End of Cache List ---


2. Topology Detection (./leaf_0B_topology)

--- Extended Topology Enumeration ---
Level 0 (SMT/Thread): 2 logical processors per core.
Level 1 (Core):       8 logical processors per package.
x2APIC ID:            0x00000003


📂 Repository Structure

The project follows a Separation of Concerns principle. The directory structure below is organized using professional naming conventions for clarity:

x86-cpuid-project/
├── src/                          # Source Code (Assembly Modules)
│   ├── check_cpuid_support.asm   # EFLAGS verification
│   ├── leaf_00_vendor.asm        # Vendor ID (GenuineIntel)
│   ├── leaf_01_features.asm      # Standard Features
│   ├── leaf_02_descriptors.asm   # Legacy Descriptors
│   ├── leaf_04_cache.asm         # Deterministic Cache Params
│   ├── leaf_05_mwait.asm         # MONITOR/MWAIT
│   ├── leaf_06_power.asm         # Power Management
│   ├── leaf_09_dca.asm           # Direct Cache Access
│   ├── leaf_0A_pmu.asm           # Performance Monitoring
│   ├── leaf_0B_topology.asm      # Extended Topology
│   ├── ext_80_max_func.asm       # Max Extended Function
│   ├── ext_86_l2_cache.asm       # Extended L2 Cache
│   ├── ext_87_invariant.asm      # Invariant TSC
│   ├── ext_88_addr_size.asm      # Address Sizes
│   └── util_real_freq.asm        # Frequency Utility
│
├── docs/                         # Documentation
│   ├── Intel_App_Note_485.pdf    # Official Datasheet
│   └── Project_Presentation.pdf  # Presentation Slides
│
├── bin/                          # Executables (Auto-generated)
├── build.sh                      # Automation Build Script
└── README.md                     # This Document


🛠️ Prerequisites

To build and run this project, you need a Linux environment with the following tools:

NASM (Netwide Assembler)

GCC (GNU Compiler Collection - used for linking C library functions like printf)

To install dependencies on Ubuntu/Debian:

sudo apt update
sudo apt install nasm gcc gcc-multilib


(Note: gcc-multilib is required to link 32-bit assembly on 64-bit systems).

📦 How to Build & Run

Option 1: Automated Build (Recommended)

You can compile all modules at once using the provided script:

# 1. Make the script executable
chmod +x build.sh

# 2. Run the build script
./build.sh

# 3. Run any tool from the bin folder
./bin/leaf_04_cache
./bin/leaf_0B_topology


Option 2: Manual Compilation

If you want to compile a specific module manually (e.g., the Cache Detector):

# Assemble
nasm -f elf32 src/leaf_04_cache.asm -o leaf_04.o

# Link
gcc -m32 leaf_04.o -o leaf_04

# Run
./leaf_04


📚 References

Intel® 64 and IA-32 Architectures Software Developer’s Manual

Intel® Application Note 485: Processor Identification and the CPUID Instruction.

👨‍💻 Author

Developed by [Your Name] as a research project on x86 System Architecture and Low-level Programming.
