# 🚀 **x86 CPUID Feature & Topology Explorer**

*A modular low-level Assembly project for exploring CPUID features on
x86 processors.*

------------------------------------------------------------------------

## 📑 **Table of Contents**

-   [Overview](#-overview)
-   [Features](#-features)
-   [Example Output](#-example-output)
-   [Repository Structure](#-repository-structure)
-   [Requirements](#-requirements)
-   [Build & Run](#-build--run)
-   [References](#-references)
-   [Author](#-author)

------------------------------------------------------------------------

## 📘 **Overview**

The **x86 CPUID Feature & Topology Explorer** is a modular
Assembly-based project designed to interact directly with processor
hardware using the **CPUID instruction**.

Each CPUID *leaf* is implemented as an independent assembly module,
making this repository ideal for:

-   Students learning low-level programming\
-   OS developers exploring hardware introspection\
-   Anyone studying Intel CPU microarchitecture\
-   Engineers analyzing cache, topology, and performance features

This project is based on **Intel® Application Note 485** and the
**Intel® SDM**.

------------------------------------------------------------------------

## 🔍 **Features**

### ✔ Core & Instruction Support Detection

-   Verifies CPUID support by toggling **EFLAGS.ID (bit 21)**.

### ✔ Cache Hierarchy Analysis (Leaf 04h)

Extracts: - Cache Level (L1/L2/L3)\
- Line size\
- Associativity\
- Set count\
- Number of cores per cache

### ✔ Processor Topology Detection (Leaf 0Bh)

Extracts: - SMT Thread count\
- Core count\
- Package information\
- x2APIC ID

### ✔ Standard CPU Feature Flags (Leaf 01h)

Detects features such as: - FPU\
- MMX\
- SSE, SSE2, SSE3\
- Hyper-Threading\
- Processor Signature

### ✔ Power Management (Leaf 06h)

Detects: - Digital Thermal Sensor\
- Turbo Boost\
- ARAT

### ✔ Performance Monitoring (Leaf 0Ah)

Enumerates PMU capabilities.

### ✔ Extended CPUID Functions

-   Processor Brand String\
-   Physical/Virtual Address Sizes\
-   Invariant TSC\
-   Extended L2 Cache Parameters

------------------------------------------------------------------------

## 📸 **Example Output**

### **Cache Hierarchy Example (`./leaf_04_cache`)**

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

### **Topology Example (`./leaf_0B_topology`)**

    --- Extended Topology Enumeration ---
    Level 0 (SMT/Thread): 2 logical processors per core.
    Level 1 (Core):       8 logical processors per package.
    x2APIC ID:            0x00000003

------------------------------------------------------------------------

## 📁 **Repository Structure**

    x86-cpuid-project/
    ├── src/
    │   ├── check_cpuid_support.asm
    │   ├── leaf_00_vendor.asm
    │   ├── leaf_01_features.asm
    │   ├── leaf_02_descriptors.asm
    │   ├── leaf_04_cache.asm
    │   ├── leaf_05_mwait.asm
    │   ├── leaf_06_power.asm
    │   ├── leaf_09_dca.asm
    │   ├── leaf_0A_pmu.asm
    │   ├── leaf_0B_topology.asm
    │   ├── ext_80_max_func.asm
    │   ├── ext_86_l2_cache.asm
    │   ├── ext_87_invariant.asm
    │   ├── ext_88_addr_size.asm
    │   └── util_real_freq.asm
    │
    ├── docs/
    │   ├── Intel_App_Note_485.pdf
    │   └── Project_Presentation.pdf
    │
    ├── bin/
    ├── build.sh
    └── README.md

------------------------------------------------------------------------

## 🛠 **Requirements**

You need a Linux system with:

-   **NASM**
-   **GCC**
-   **gcc-multilib** (for 32-bit linking on 64-bit systems)

Install on Ubuntu/Debian:

``` bash
sudo apt update
sudo apt install nasm gcc gcc-multilib
```

------------------------------------------------------------------------

## ⚙️ **Build & Run**

### **Option 1 --- Automated Build (Recommended)**

``` bash
chmod +x build.sh
./build.sh
```

Run a module:

``` bash
./bin/leaf_04_cache
./bin/leaf_0B_topology
```

------------------------------------------------------------------------

### **Option 2 --- Manual Build Example**

``` bash
# Assemble
nasm -f elf32 src/leaf_04_cache.asm -o leaf_04.o

# Link
gcc -m32 leaf_04.o -o leaf_04

# Run
./leaf_04
```

------------------------------------------------------------------------

## 📚 **References**

-   **Intel® 64 and IA-32 Architectures Software Developer's Manual**\
-   **Intel® Application Note 485 --- Processor Identification and the
    CPUID Instruction**

------------------------------------------------------------------------

## 👤 **Author**

Developed by **\[Ali Heidari\]**\
*Research project on x86 low-level programming & system architecture.*
