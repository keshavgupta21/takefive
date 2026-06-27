# Comprehensive Guide to 32-Bit RISC-V Assembly Programming (RV32I)

This guide provides a thorough introduction to programming in 32-bit RISC-V assembly language, focusing on the RV32I base integer instruction set. It starts with content from [this cheat sheet](https://projectf.io/posts/riscv-cheat-sheet/) and expands it into a complete, structured reference. The guide is organized for easy navigation, with clear sections, tables for listings, explanations, examples, and notes. It draws from official specifications and tutorials to ensure accuracy and completeness. Beginners can follow sequentially, while experienced users can reference specific sections.

Key assumptions:
- We use the GNU Assembler (GAS) syntax, common for RISC-V tools.
- Examples assume a bare-metal or simple simulator environment (e.g., RARS, Spike, or QEMU).
- RV32I is the base; extensions like M (multiply/divide) are noted but not required unless specified.
- Code snippets are testable in simulators; error handling and overflows are ignored in basic ops as per the ISA.

## 1. Introduction to RISC-V and RV32I

RISC-V is an open-source instruction set architecture (ISA) developed at UC Berkeley, designed for simplicity, modularity, and extensibility. Unlike proprietary ISAs (e.g., x86, ARM), RISC-V is free to implement and royalty-free. The "RV32I" variant specifies a 32-bit address space with integer instructions only (no floating-point or vector ops in base).

- **Key Features**: Load-store architecture (operations on registers, memory access separate), fixed 32-bit instruction length, little-endian memory by default.
- **Privilege Levels**: User (U), Supervisor (S), Machine (M). This guide focuses on unprivileged (user-mode) assembly.
- **History and Versions**: RV32I is part of the unprivileged ISA. The latest ratified spec (as of 2024) is available in the [RISC-V Instruction Set Manual Volume I](https://courses.grainger.illinois.edu/ece391/su2025/docs/unpriv-isa-20240411.pdf). It includes 47 instructions for basic computation, control flow, and memory.
- **Why Learn RV32I?**: It's a compiler target, supports OSes, and is used in embedded systems, IoT, and research.

To get started:
- Install the RISC-V GNU toolchain (riscv64-unknown-elf-gcc).
- Use simulators: RARS (educational), Spike (official), or QEMU for emulation.

## 2. Registers

RV32I has 32 general-purpose registers (GPRs), each 32 bits wide, named x0 to x31. Registers hold data for computations; memory access is via loads/stores.

- **x0 (zero)**: Hardwired to 0. Writing to it is ignored.
- **Program Counter (pc)**: Holds the current instruction address (not a GPR; implicitly managed).

Registers follow the Application Binary Interface (ABI) convention for interoperability (e.g., with C code). The ABI names and usages are:

| Register | ABI Name | Description | Saved By |
|----------|----------|-------------|----------|
| x0       | zero     | Always 0 (immutable). | - |
| x1       | ra       | Return address (for function returns). | Caller |
| x2       | sp       | Stack pointer (points to top of stack). | Callee |
| x3       | gp       | Global pointer (for global variables). | - |
| x4       | tp       | Thread pointer (for thread-local storage). | - |
| x5-x7    | t0-t2    | Temporaries (scratch registers). | Caller |
| x8-x9    | s0/fp-s1 | Saved registers (callee must preserve). s0 often used as frame pointer (fp). | Callee |
| x10-x17  | a0-a7    | Function arguments/return values (a0-a1 for returns). | Caller |
| x18-x27  | s2-s11   | Saved registers (callee must preserve). | Callee |
| x28-x31  | t3-t6    | Temporaries (scratch registers). | Caller |

- **Notes**: Caller-saved means the calling function saves if needed; callee-saved means the called function preserves. Stack grows downward (sp decreases). Use ra for jal/jalr returns. [^2]

Example: Moving value between registers (pseudo-instruction mv):
```
mv a0, t0  # a0 = t0 (actually addi a0, t0, 0)
```

## 3. Instruction Formats

All RV32I instructions are 32 bits, aligned on 4-byte boundaries (misalignment causes exceptions). There are 6 formats:

| Format | Purpose | Bit Layout (31..0) |
|--------|---------|--------------------|
| R (Register) | Register-register ops | funct7 (31-25), rs2 (24-20), rs1 (19-15), funct3 (14-12), rd (11-7), opcode (6-0) |
| I (Immediate) | Register-immediate ops, loads, jumps | imm[11:0] (31-20), rs1 (19-15), funct3 (14-12), rd (11-7), opcode (6-0) |
| S (Store) | Stores | imm[11:5] (31-25), rs2 (24-20), rs1 (19-15), funct3 (14-12), imm[4:0] (11-7), opcode (6-0) |
| B (Branch) | Conditional branches | imm[12] (31), imm[10:5] (30-25), rs2 (24-20), rs1 (19-15), funct3 (14-12), imm[4:1] (11-8), imm[11] (7), opcode (6-0) |
| U (Upper Immediate) | Large immediates | imm[31:12] (31-12), rd (11-7), opcode (6-0) |
| J (Jal) | Unconditional jumps | imm[20] (31), imm[10:1] (30-21), imm[11] (20), imm[19:12] (19-12), rd (11-7), opcode (6-0) |

- **Immediates**: Sign-extended in I/S/B (for negatives). U/J for 20-bit values (shifted left by 12 for U, 1 for J).
- **Opcodes**: Fixed for categories (e.g., 0110011 for R-type arithmetic).
- **funct3/funct7**: Select specific ops within format. [^3][^4]

## 4. Instructions

Instructions are grouped by purpose, as in the cheat sheet. Each table includes mnemonic, format, usage, operation, and notes. Pseudo-instructions (p) are assembler expansions (not real opcodes). All ops are on 32-bit values; no flags (use slt for comparisons).

### 4.1 Arithmetic

| Instr | Format | Usage | Operation | Notes/Guide |
|-------|--------|-------|-----------|-------------|
| add | R | add rd, rs1, rs2 | rd = rs1 + rs2 (overflow ignored) | Basic addition. |
| addi | I | addi rd, rs1, imm | rd = rs1 + sext(imm) | Imm is 12-bit signed. Use for sub imm (negative imm). |
| neg (p) | - | neg rd, rs2 | rd = 0 - rs2 | Expands to sub rd, zero, rs2. |
| sub | R | sub rd, rs1, rs2 | rd = rs1 - rs2 (overflow ignored) | Basic subtraction. |

- **Extensions**: mul, mulh, div, rem require RV32M (not base). [^5]
- **Example**:
  ```
  addi t0, zero, 5   # t0 = 5
  add t1, t0, t0     # t1 = 10
  sub t2, t1, t0     # t2 = 5
  ```

### 4.2 Bitwise Logic

| Instr | Format | Usage | Operation | Notes/Guide |
|-------|--------|-------|-----------|-------------|
| and | R | and rd, rs1, rs2 | rd = rs1 & rs2 | Bitwise AND. |
| andi | I | andi rd, rs1, imm | rd = rs1 & sext(imm) | Imm signed, but bitwise. |
| not (p) | - | not rd, rs1 | rd = ~rs1 | Expands to xori rd, rs1, -1. |
| or | R | or rd, rs1, rs2 | rd = rs1 \| rs2 | Bitwise OR. |
| ori | I | ori rd, rs1, imm | rd = rs1 \| sext(imm) | - |
| xor | R | xor rd, rs1, rs2 | rd = rs1 ^ rs2 | Bitwise XOR. |
| xori | I | xori rd, rs1, imm | rd = rs1 ^ sext(imm) | - |

- **Example**:
  ```
  ori t0, zero, 0x0F  # t0 = 15 (0b1111)
  andi t1, t0, 0x03   # t1 = 3 (0b0011)
  not t2, t1          # t2 = ~3 (all bits inverted)
  ```

### 4.3 Shift

| Instr | Format | Usage | Operation | Notes/Guide |
|-------|--------|-------|-----------|-------------|
| sll | R | sll rd, rs1, rs2 | rd = rs1 << (rs2 & 0x1F) | Logical left shift (zeros fill). |
| slli | I | slli rd, rs1, shamt | rd = rs1 << shamt | Shamt is 5-bit unsigned imm. |
| srl | R | srl rd, rs1, rs2 | rd = rs1 >> (rs2 & 0x1F) unsigned | Logical right (zeros fill). |
| srli | I | srli rd, rs1, shamt | rd = rs1 >> shamt unsigned | - |
| sra | R | sra rd, rs1, rs2 | rd = rs1 >> (rs2 & 0x1F) arithmetic | Sign bit fills (for signed). |
| srai | I | srai rd, rs1, shamt | rd = rs1 >> shamt arithmetic | - |

- **Notes**: Shift amount limited to 0-31 (lower 5 bits). [^6]
- **Example**:
  ```
  addi t0, zero, 16  # t0 = 16 (0b10000)
  slli t1, t0, 2     # t1 = 64 (0b1000000)
  srli t2, t1, 1     # t2 = 32 (0b100000)
  ```

### 4.4 Load Immediate

| Instr | Format | Usage | Operation | Notes/Guide |
|-------|--------|-------|-----------|-------------|
| lui | U | lui rd, imm | rd = imm << 12 | Loads upper 20 bits (lower 12 zero). For large constants. |
| auipc | U | auipc rd, imm | rd = pc + (imm << 12) | PC-relative address building. |

- **Pseudo**: li rd, imm (loads any 32-bit imm, expands to lui + addi if needed).
- **Example**:
  ```
  lui t0, 0x12345  # t0 = 0x12345000
  addi t0, t0, 0x678  # t0 = 0x12345678
  auipc t1, 0      # t1 = current pc
  ```

### 4.5 Load and Store

RISC-V is load/store: only these access memory. Address = rs1 + sext(imm). Byte-addressable, little-endian.

| Instr | Format | Usage | Operation | Notes/Guide |
|-------|--------|-------|-----------|-------------|
| lb | I | lb rd, imm(rs1) | rd = sext(M[rs1 + imm]:byte) | Load signed byte. |
| lbu | I | lbu rd, imm(rs1) | rd = zext(M[rs1 + imm]:byte) | Unsigned byte. |
| lh | I | lh rd, imm(rs1) | rd = sext(M[rs1 + imm]:half) | Signed halfword (16-bit). |
| lhu | I | lhu rd, imm(rs1) | rd = zext(M[rs1 + imm]:half) | Unsigned half. |
| lw | I | lw rd, imm(rs1) | rd = M[rs1 + imm]:word | Load word (32-bit). |
| sb | S | sb rs2, imm(rs1) | M[rs1 + imm]:byte = rs2[7:0] | Store byte. |
| sh | S | sh rs2, imm(rs1) | M[rs1 + imm]:half = rs2[15:0] | Store half. |
| sw | S | sw rs2, imm(rs1) | M[rs1 + imm]:word = rs2 | Store word. |

- **Notes**: Imm is 12-bit signed (-2048 to 2047). Alignment: natural (e.g., lw on 4-byte boundary) or exception. No floating loads in base.
- **Pseudo**: la rd, label (load address, expands to auipc + addi).
- **Example** (assume .data section with label):
  ```
  .data
  val: .word 0xABCDEF01
  .text
  la t0, val       # t0 = address of val
  lw t1, 0(t0)     # t1 = 0xABCDEF01
  addi t1, t1, 1   # t1 += 1
  sw t1, 0(t0)     # store back
  ```

### 4.6 Jump and Function Calls

| Instr | Format | Usage | Operation | Notes/Guide |
|-------|--------|-------|-----------|-------------|
| jal | J | jal rd, imm | rd = pc + 4; pc = pc + sext(imm) | Jump and link (imm 20-bit, shifted <<1 for even offsets). |
| jalr | I | jalr rd, imm(rs1) | rd = pc + 4; pc = (rs1 + sext(imm)) & ~1 | Indirect jump (clear LSB for alignment). |
| ret (p) | - | ret | pc = ra | Expands to jalr zero, 0(ra). |

- **Notes**: Imm for jal is ±1MB. Use for functions (save pc in ra). [^3]
- **Example** (simple function):
  ```
  jal ra, func  # call func, save return in ra
  ...
  func:
    addi a0, a0, 1  # do something
    jalr zero, 0(ra)  # return (or ret)
  ```

### 4.7 Branch (Conditional)

Branches compare rs1/rs2 and jump if true. Offset = sext(imm) <<1 (±4KB).

| Instr | Format | Usage | Operation | Notes/Guide |
|-------|--------|-------|-----------|-------------|
| beq | B | beq rs1, rs2, imm | if (rs1 == rs2) pc += sext(imm)<<1 | Equal. |
| bne | B | bne rs1, rs2, imm | if (rs1 != rs2) pc += sext(imm)<<1 | Not equal. |
| blt | B | blt rs1, rs2, imm | if (rs1 < rs2 signed) pc += sext(imm)<<1 | Less than. |
| bltu | B | bltu rs1, rs2, imm | if (rs1 < rs2 unsigned) pc += sext(imm)<<1 | Unsigned less. |
| bge | B | bge rs1, rs2, imm | if (rs1 >= rs2 signed) pc += sext(imm)<<1 | Greater or equal. |
| bgeu | B | bgeu rs1, rs2, imm | if (rs1 >= rs2 unsigned) pc += sext(imm)<<1 | Unsigned >=. |

- **Pseudo**: beqz rs, imm (beq rs, zero, imm), bltz rs, imm (blt rs, zero, imm), etc.
- **Example** (loop):
  ```
  addi t0, zero, 5  # counter = 5
  loop:
    addi t0, t0, -1  # counter--
    bnez t0, loop    # if !=0, loop
  ```

### 4.8 Set (Compare)

| Instr | Format | Usage | Operation | Notes/Guide |
|-------|--------|-------|-----------|-------------|
| slt | R | slt rd, rs1, rs2 | rd = (rs1 < rs2 signed) ? 1 : 0 | Set if less than. |
| sltu | R | sltu rd, rs1, rs2 | rd = (rs1 < rs2 unsigned) ? 1 : 0 | Unsigned. |
| slti | I | slti rd, rs1, imm | rd = (rs1 < sext(imm) signed) ? 1 : 0 | Immediate. |
| sltiu | I | sltiu rd, rs1, imm | rd = (rs1 < sext(imm) unsigned) ? 1 : 0 | Unsigned imm. |

- **Pseudo**: seqz rd, rs (sltiu rd, rs, 1), snez rd, rs (sltu rd, zero, rs).
- **Example**:
  ```
  addi t0, zero, -5
  slti t1, t0, 0   # t1 = 1 ( -5 < 0 )
  sltiu t2, t0, 0  # t2 = 0 (unsigned -5 is large)
  ```

### 4.9 Counters and Misc

| Instr | Format | Usage | Operation | Notes/Guide |
|-------|--------|-------|-----------|-------------|
| fence | I | fence pred, succ | Memory barrier (order loads/stores). | For synchronization; pred/succ specify types (e.g., iorw). |
| fence.i | I | fence.i | Instruction fence (sync after code mod). | Imm/rs1/rd=0. |
| ecall | I | ecall | Environment call (syscall/trap). | To higher privilege. |
| ebreak | I | ebreak | Environment break (debugger). | - |

- **Counters** (via rdtime, etc., but in Zicsr extension; base has no direct).
- **NOP (p)**: addi zero, zero, 0.
- **Notes**: ecall for OS calls (e.g., exit: li a0, 0; li a7, 93; ecall). [^2]

## 5. Pseudo-Instructions

Assemblers expand these for convenience:

| Pseudo | Expansion | Description |
|--------|-----------|-------------|
| mv rd, rs | addi rd, rs, 0 | Move register. |
| li rd, imm | lui/addi or similar | Load immediate (any size). |
| la rd, label | auipc + addi | Load address. |
| j label | jal zero, label | Jump (no link). |
| call label | auipc + jalr | Far call. |
| nop | addi zero, zero, 0 | No operation. |

- Use freely; assembler handles. [^3]

## 6. Assembler Directives

Directives control assembly (not executed). Common in GAS:

| Directive | Usage | Description |
|-----------|-------|-------------|
| .text | .text | Start code section. |
| .data | .data | Start data section. |
| .global label | .global main | Export symbol (e.g., entry point). |
| .equ name, value | .equ CONST, 42 | Define constant. |
| .byte/.half/.word | .word 0x1234 | Allocate byte/half/word. |
| .string "text" | .string "Hello" | Allocate null-terminated string. |
| .align n | .align 4 | Align to 2^n bytes. |
| .section name | .section .bss | Custom section (e.g., zero-init). |

- **Example**:
  ```
  .global _start
  .text
  _start:  # entry point
    ...
  .data
  msg: .string "Hello, RISC-V!\n"
  ```

From tutorials and manual. [^2]

## 7. Memory Model and Alignment

- **Memory**: 32-bit address space (4GB). Little-endian (LSB first).
- **Alignment**: Loads/stores must align (e.g., lw on mod4=0) or trap.
- **Stack**: Grows down; push: addi sp, sp, -4; sw ra, 0(sp).
- **Heap/Global**: Use gp for globals.

## 8. Calling Convention (ABI)

- **Arguments**: In a0-a7; excess on stack.
- **Returns**: In a0-a1.
- **Preservation**: Callee saves s0-s11; caller saves t*, a*, ra if needed.
- **Prologue/Epilogue**: For functions:
  ```
  func:
    addi sp, sp, -16  # allocate frame
    sw ra, 12(sp)     # save ra
    sw s0, 8(sp)      # save s0
    ... 
    lw s0, 8(sp)
    lw ra, 12(sp)
    addi sp, sp, 16
    ret
  ```

From ABI specs in manual. [^2]

## 9. Examples

### 9.1 Hello World (Syscall)

Assumes environment with ecall for print (e.g., a7=64 for write, a0=fd=1, a1=addr, a2=len).
```
.global _start
.text
_start:
    la a1, msg      # a1 = msg addr
    li a2, 13       # len=13
    li a0, 1        # fd=1 (stdout)
    li a7, 64       # syscall: write
    ecall
    li a0, 0        # exit code
    li a7, 93       # syscall: exit
    ecall
.data
msg: .string "Hello World!\n"
```

- Run in simulator: Outputs "Hello World!"

### 9.2 Factorial (Recursive)

```
.global _start
.text
_start:
    li a0, 5        # compute 5!
    jal ra, fact
    # result in a0
    li a7, 93
    ecall           # exit

fact:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)    # save n
    li t0, 1
    ble a0, t0, base  # if n <=1
    addi a0, a0, -1
    jal ra, fact    # fact(n-1)
    lw t0, 0(sp)    # restore n
    mul a0, a0, t0  # n * fact(n-1) (needs RV32M)
    j done
base:
    li a0, 1
done:
    lw ra, 4(sp)
    addi sp, sp, 8
    ret
```

- Notes: Uses mul (M extension); alternative: loop for base.

### 9.3 Loop Sum (1 to N)

```
addi t0, zero, 10  # N=10
addi t1, zero, 0   # sum=0
loop:
  add t1, t1, t0   # sum += N
  addi t0, t0, -1  # N--
  bnez t0, loop    # repeat if N!=0
# t1 = 55
```

From tutorials. [^7]

## 10. Advanced Topics

- **Traps/Interrupts**: ecall for syscalls; mcause CSR for handling (privileged).
- **CSRs**: Access via csrr(w/i/s/c) (Zicsr extension).
- **Extensions**: Add M for mul/div, A for atomics, F/D for float.
- **Debugging**: Use gdb with riscv-gnu-toolchain; ebreak for breakpoints.
- **Optimization**: Use pseudo-ops, align code, minimize branches.

## 11. Tools and Resources

- **Assembler/Linker**: riscv64-unknown-elf-as/ld (GNU).
- **Simulator**: RARS (GUI, educational), Spike (CLI, accurate).
- **Emulator**: QEMU-riscv32.
- **Further Reading**: Official ISA Manual [^1], tutorials[^7].

This guide covers RV32I basics; practice with simulators for mastery.

[^1]: https://courses.grainger.illinois.edu/ece391/su2025/docs/unpriv-isa-20240411.pdf
[^2]: https://shakti.org.in/docs/risc-v-asm-manual.pdf
[^3]: https://five-embeddev.com/riscv-user-isa-manual/Priv-v1.12/rv32.html
[^4]: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf
[^5]: https://projectf.io/posts/riscv-cheat-sheet/
[^6]: https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html
[^7]: https://riscv-programming.org/