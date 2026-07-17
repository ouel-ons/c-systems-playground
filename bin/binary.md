# The Binary Masterclass
### From "why two states?" to reverse engineering ELF binaries

---

## PART 1 — Why Binary Exists

### The core idea
Computers are built from **transistors** — tiny electronic switches that can be either ON or OFF. A transistor is reliable at distinguishing two very different voltage levels (say, ~0V and ~5V), but it's unreliable at distinguishing ten finely-spaced voltage levels. Noise, heat, and manufacturing variance would constantly cause misreads.

So the question "why binary?" really means: **why build on the physical property that is cheapest to make reliable?**

### Why not base 10, base 3, or base 100?
- **Base 10 (decimal):** would require reliably distinguishing 10 voltage levels per wire. Possible in theory, terrible in practice — noise margins shrink as you add levels, so error rates skyrocket.
- **Base 3 (balanced ternary):** interestingly, information-theoretically base *e* (~2.718) is the most "efficient" radix for representing numbers per unit of engineering cost, and base 3 is the closest integer to it. Some early Soviet computers (Setun) actually used ternary logic. But binary components (transistors, relays) were simpler and cheaper to mass-produce, so binary won the engineering race, not the math race.
- **Base 100:** would need 100 distinguishable voltage levels on a single wire — essentially impossible to do reliably and cheaply at nanometer transistor scales.

### Digital vs Analog
- **Analog** signals vary continuously (like a dimmer switch or your voice's sound wave).
- **Digital** signals are discretized into a finite set of states — in practice, two: HIGH and LOW.

### From electricity to information
1. A transistor gate is either conducting (current flows) or not.
2. We *define* "conducting" = 1, "not conducting" = 0 (or vice versa, depending on logic family).
3. Groups of these 1s and 0s are interpreted according to agreed-upon rules (encodings) as numbers, characters, instructions, colors, sounds — literally anything.

That's the entire trick: **electricity gives us reliable two-state switches; binary gives us a numbering system that maps perfectly onto two states; everything else (text, images, video, programs) is just an agreed-upon interpretation layered on top.**

---

## PART 2 — Number Systems

All positional number systems work the same way — only the **base** (radix) changes.

### Decimal (base 10)
Digits 0–9. Each position is a power of 10.

```
    523
  = 5×10² + 2×10¹ + 3×10⁰
  = 500 + 20 + 3
  = 523
```

### Binary (base 2)
Digits 0–1. Each position is a power of 2.

```
    101101₂
  = 1×2⁵ + 0×2⁴ + 1×2³ + 1×2² + 0×2¹ + 1×2⁰
  = 32 + 0 + 8 + 4 + 0 + 1
  = 45₁₀
```

**Quick conversion trick (binary → decimal):** write powers of 2 above each bit, add up the ones where the bit is 1.

**Decimal → binary (repeated division by 2):**
```
45 ÷ 2 = 22 r 1
22 ÷ 2 = 11 r 0
11 ÷ 2 =  5 r 1
 5 ÷ 2 =  2 r 1
 2 ÷ 2 =  1 r 0
 1 ÷ 2 =  0 r 1
Read remainders bottom-to-top: 101101
```

### Hexadecimal (base 16)
Digits 0–9, then A=10, B=11, C=12, D=13, E=14, F=15.

**Why programmers love hex:** each hex digit represents exactly **4 bits** (a nibble), so hex is a compact, human-friendly shorthand for binary. Converting hex↔binary is trivial (just expand/collapse groups of 4), unlike decimal↔binary.

```
Hex:    A    3    F
Binary: 1010 0011 1111
```

`0xA3F` = `1010 0011 1111₂` = 2623₁₀. One byte = exactly 2 hex digits (e.g. `0xFF` = 255 = `11111111`), which is why hex is the default way to display memory dumps, colors (`#FF00FF`), and machine code.

### Octal (base 8)
Digits 0–7. Each octal digit = exactly 3 bits.

Still shows up in **Unix file permissions**:
```
rwxr-xr--  →  111 101 100  →  7 5 4  →  chmod 754
```
- `7` = rwx (4+2+1)
- `5` = r-x (4+0+1)
- `4` = r-- (4+0+0)

### Conversion cheat sheet

| Decimal | Binary | Hex | Octal |
|---|---|---|---|
| 0 | 0000 | 0 | 0 |
| 1 | 0001 | 1 | 1 |
| 2 | 0010 | 2 | 2 |
| 3 | 0011 | 3 | 3 |
| 4 | 0100 | 4 | 4 |
| 5 | 0101 | 5 | 5 |
| 6 | 0110 | 6 | 6 |
| 7 | 0111 | 7 | 7 |
| 8 | 1000 | 8 | 10 |
| 9 | 1001 | 9 | 11 |
| 10 | 1010 | A | 12 |
| 11 | 1011 | B | 13 |
| 12 | 1100 | C | 14 |
| 13 | 1101 | D | 15 |
| 14 | 1110 | E | 16 |
| 15 | 1111 | F | 17 |

---

## PART 3 — Binary Arithmetic

### Addition
Same as decimal, but you carry at 2 instead of 10.
```
  0+0 = 0
  0+1 = 1
  1+1 = 10   (0, carry 1)
  1+1+1 = 11 (1, carry 1)
```
Example:
```
   0111  (7)
 + 0101  (5)
 ------
   1100  (12)
```
Work right to left: 1+1=10 (write 0, carry 1) → 1+0+1(carry)=10 (write 0, carry 1) → 1+1+1(carry)=11 (write 1, carry 1) → 0+0+1(carry)=1.

### Subtraction
Can be done with borrowing directly, but in real CPUs, subtraction is almost always implemented as **addition of the negative** using two's complement (see Part 8) — this lets the ALU reuse the same adder circuit for both operations.

### Multiplication
Binary long multiplication is just shifting and adding — this is exactly why `x << n` is equivalent to `x × 2ⁿ`.
```
   1011   (11)
 ×  101   (5)
 ------
   1011        (1011 × 1)
+ 00000        (1011 × 0, shifted 1)
+101100        (1011 × 1, shifted 2)
--------
 0110111  = 55
```

### Division
Binary long division works like decimal long division, just with only 0s and 1s as possible quotient digits at each step.

### Overflow and Carry
- **Carry out**: when an addition produces a result that doesn't fit in the available bits (e.g., adding two 8-bit numbers gives a 9-bit result). Matters for **unsigned** overflow.
- **Overflow flag**: set when the *signed* result is mathematically wrong — e.g., adding two positive numbers and getting a negative result due to running out of room in the sign bit.
- **Borrow**: the subtraction equivalent of carry — "borrowing" from the next higher bit when subtracting a larger digit from a smaller one.

These flags are why CPUs have a **status register** — every arithmetic instruction sets flags (Carry, Overflow, Zero, Sign) that later instructions (like conditional jumps) can react to.

---

## PART 4 — Powers of Two

Memorize these — they appear *everywhere* in computing (buffer sizes, memory addressing, network subnet math, integer limits).

| Power | Value |
|---|---|
| 2⁰ | 1 |
| 2¹ | 2 |
| 2² | 4 |
| 2³ | 8 |
| 2⁴ | 16 |
| 2⁵ | 32 |
| 2⁶ | 64 |
| 2⁷ | 128 |
| 2⁸ | 256 |
| 2⁹ | 512 |
| 2¹⁰ | 1,024 (≈ "1K") |
| 2¹¹ | 2,048 |
| 2¹² | 4,096 |
| 2¹³ | 8,192 |
| 2¹⁴ | 16,384 |
| 2¹⁵ | 32,768 |
| 2¹⁶ | 65,536 (≈ "64K"; max value+1 of a 16-bit unsigned int) |
| 2²⁰ | ≈ 1,048,576 ("1M") |
| 2³⁰ | ≈ 1,073,741,824 ("1G") |
| 2³² | 4,294,967,296 (max unsigned 32-bit range) |
| 2⁶⁴ | 18,446,744,073,709,551,616 (max unsigned 64-bit range) |

**Why they matter:** a 32-bit unsigned integer can hold values `0` to `2³²-1` = 4,294,967,295. This is *the* reason 32-bit systems max out around 4GB of addressable memory, why IPv4 has ~4.3 billion addresses, and why 16-bit color channels go up to 65,535.

---

## PART 5 — Bits: Units of Digital Information

| Unit | Size | Notes |
|---|---|---|
| Bit | 1 binary digit | smallest unit of information |
| Nibble | 4 bits | exactly one hex digit |
| Byte | 8 bits | smallest *addressable* unit in almost all modern systems |
| Word | Architecture-dependent (often 16 or 32 bits) | the CPU's "natural" data size |
| Double word (dword) | 32 bits | |
| Quad word (qword) | 64 bits | |

### MSB and LSB
In `10110101`:
- **MSB (Most Significant Bit)** = the leftmost bit (here, `1`), carrying the most numeric weight (2⁷).
- **LSB (Least Significant Bit)** = the rightmost bit, carrying the least weight (2⁰) — this is also the bit that tells you if a number is odd or even.

Bit ordering matters enormously in networking and file formats (see Endianness, Part 11).

---

## PART 6 — Bytes

A byte (8 bits) became the standard addressable unit largely because it's the smallest size that can represent a full character set (like ASCII, which needs 7 bits, rounded up to 8) while keeping memory addressing schemes efficient.

- `char` in C is defined to be exactly 1 byte.
- `uint8_t` is an unsigned 8-bit integer — 1 byte, range 0–255.
- **ASCII** encodes English letters, digits, and symbols in 7 bits (0–127), with the 8th bit historically used for parity checking or extended character sets.
- Memory and files are fundamentally **byte-oriented**: even though CPUs may fetch words or cache lines at once internally, every address you can point to refers to a byte.

---

## PART 7 — Binary Representation: How Computers Store Everything

Everything in a computer reduces to bytes interpreted a certain way:

| Data type | How it's represented |
|---|---|
| Integers | Two's complement binary (Part 8) |
| Characters | ASCII / Unicode code points (Part 10) |
| Negative numbers | Sign bit + two's complement |
| Floating point | IEEE-754 (Part 9) |
| Images | Grids of pixel values (RGB bytes) + compression metadata |
| Video | Sequences of compressed image frames + audio streams |
| Audio | Sampled amplitude values (PCM) at a sample rate |
| Programs | Machine code — binary opcodes the CPU decodes directly |
| Pointers | Just integers holding a memory address |

The unifying insight: **there is no inherent "type" stored in RAM.** A given sequence of bytes is only an integer, a float, or a character because *the program reading it* has agreed to interpret it that way. This is also the root cause of most memory-corruption security bugs — tricking a program into misinterpreting attacker-controlled bytes as something else (like code).

---

## PART 8 — Signed Numbers

### The problem
With `n` bits you can represent 2ⁿ distinct patterns. If half should represent negative numbers, how do you encode the sign?

### Sign-magnitude (early, mostly abandoned)
Use the MSB purely as a sign flag; the rest is magnitude.
```
1000 0101 = -5   (sign bit 1, magnitude 0000101)
0000 0101 = +5
```
Problem: two representations of zero (`+0` and `-0`), and arithmetic circuits get complicated.

### One's complement
Negate a number by flipping every bit.
```
 5 = 0000 0101
-5 = 1111 1010
```
Still has the dual-zero problem (`00000000` and `11111111` both mean zero), and requires an "end-around carry" correction during addition.

### Two's complement — what every modern CPU actually uses
Negate a number by flipping every bit **and adding 1**.
```
 5 = 0000 0101
~5 = 1111 1010   (flip bits)
-5 = 1111 1011   (+1)
```
**Why CPUs use two's complement:**
1. There's exactly **one representation of zero**.
2. **Addition and subtraction use the exact same circuit** — subtracting is just adding the two's complement. `a - b == a + (~b + 1)`.
3. The MSB still conveniently tells you the sign.

For an 8-bit signed number, range is **-128 to 127** (asymmetric because zero eats one of the positive slots).

**Worked example: representing -42 in an 8-bit signed byte**
```
 42 = 0010 1010
~42 = 1101 0101   (flip every bit)
-42 = 1101 0110   (add 1)
```
Verify: `1101 0110` → MSB is 1 (negative). Two's-complement decode: flip bits (`0010 1001`), add 1 (`0010 1010` = 42), so the value is -42. ✓

### Unsigned overflow
If an 8-bit unsigned integer holds `255` (`1111 1111`) and you add `1`, the result "wraps around" to `0` — the 9th bit (carry) is simply discarded. This is why unsigned integer overflow is *defined* behavior in most languages (it wraps), while signed overflow is often **undefined behavior** in C/C++ (compilers are allowed to assume it never happens, which has caused real security bugs when it does).

---

## PART 9 — Floating Point (IEEE-754)

Floating point represents huge ranges of magnitude (from atomic scales to astronomical) using a fixed number of bits, by borrowing the idea of **scientific notation**: `value = sign × mantissa × 2^exponent`.

### Layout (32-bit single precision)
| Sign | Exponent | Mantissa (Fraction) |
|---|---|---|
| 1 bit | 8 bits | 23 bits |

```
value = (-1)^sign × 1.mantissa × 2^(exponent - 127)
```
(127 is the "bias" — it lets the exponent field, which is unsigned, represent both positive and negative exponents.)

64-bit double precision uses 1 sign bit, 11 exponent bits, 52 mantissa bits — much more precision and range.

### Special values
- **Exponent = 0, mantissa = 0** → zero (with sign, so +0 and -0 both exist)
- **Exponent = all 1s, mantissa = 0** → ±Infinity
- **Exponent = all 1s, mantissa ≠ 0** → NaN ("Not a Number" — result of 0/0, √(-1), etc.)
- **Exponent = 0, mantissa ≠ 0** → denormal numbers (extremely small values, sacrificing precision to represent numbers closer to zero than normal encoding allows)

### Why 0.1 + 0.2 ≠ 0.3
`0.1` and `0.2` cannot be represented *exactly* in binary — just like ⅓ can't be represented exactly in decimal. Binary floating point can only exactly represent sums of powers of 2. `0.1` in binary is an infinitely repeating fraction (`0.0001100110011...`), so it gets rounded to the nearest representable value. Adding two of these rounded approximations produces a result that's *extremely* close to but not exactly `0.3` — hence `0.1 + 0.2 == 0.30000000000000004` in most languages.

**Rounding modes** (round-to-nearest-even, round toward zero, etc.) determine how IEEE-754 handles values that fall between two representable numbers — this is why floating-point results can differ subtly across languages/compilers depending on rounding mode settings.

---

## PART 10 — Characters

### ASCII
7 bits, 128 code points (0–127): control characters (0–31), digits, uppercase/lowercase letters, punctuation. `'A'` = 65 = `0100 0001`.

### Extended ASCII
Uses the 8th bit to add another 128 characters (accented letters, box-drawing symbols) — but different vendors defined different extended sets, causing compatibility chaos (this is part of why Unicode exists).

### Unicode
A single universal standard assigning a unique **code point** to every character in every writing system (currently 149,000+ characters). A code point like U+0041 (`A`) or U+1F600 (😀) is just a number — the question is how to *encode* that number into bytes.

### UTF-8, UTF-16, UTF-32
- **UTF-32**: fixed 4 bytes per character. Simple but wastes space for common text.
- **UTF-16**: 2 bytes per character usually, 4 bytes for rarer characters (via "surrogate pairs"). Used internally by Windows, Java, JavaScript strings.
- **UTF-8**: **variable-width**, 1–4 bytes per character:
  - ASCII characters (0–127) encode in exactly 1 byte, **identical to ASCII itself**.
  - Higher code points use 2–4 bytes, with leading bits in the first byte indicating how many bytes follow.

**Why UTF-8 dominates:** it's fully backward-compatible with ASCII (any valid ASCII file is already valid UTF-8), it's compact for English/Western text (the most common content on the historical web), it's self-synchronizing (you can tell where a character starts just by looking at any byte), and it has no byte-order ambiguity (unlike UTF-16/32, which need a byte-order mark).

---

## PART 11 — Binary and Memory

### The mental model
```
Address:  0x0100
              ↓
        [ 8 bits: 01101001 ]
```
Every byte in RAM has a unique numeric **address**. The CPU reads/writes memory by sending an address on the address bus and getting/putting a byte (or word) on the data bus.

### Alignment
CPUs often fetch memory most efficiently when data starts at an address that's a multiple of its size (e.g., a 4-byte int at an address divisible by 4). Misaligned access can be slower or, on some architectures, cause a hardware fault. Compilers insert **padding** bytes inside structs to keep each field aligned.

```c
struct Example {
    char  a;   // 1 byte
    // 3 bytes padding inserted here
    int   b;   // 4 bytes, needs 4-byte alignment
};
// sizeof(Example) == 8, not 5
```

### Endianness
When a multi-byte value (like a 4-byte integer) is stored in memory, which byte goes first?

- **Little-endian**: least significant byte first (at the lowest address). Used by x86/x64, most ARM configurations.
- **Big-endian**: most significant byte first. Used by many network protocols ("network byte order") and some older architectures (SPARC, PowerPIC historically).

```
Value: 0x12345678

Little-endian in memory: 78 56 34 12
Big-endian in memory:    12 34 56 78
```

This matters constantly in networking (you must convert to/from "network byte order") and when reading raw binary file formats or memory dumps — get the endianness wrong and every multi-byte value you parse will be garbage.

---

## PART 12 — Bitwise Operations

The fundamental logic gates, applied bit-by-bit to entire words at once.

| Op | Symbol (C) | Rule | Example |
|---|---|---|---|
| AND | `&` | 1 only if both bits are 1 | `1010 & 1100 = 1000` |
| OR | `\|` | 1 if either bit is 1 | `1010 \| 1100 = 1110` |
| XOR | `^` | 1 if bits differ | `1010 ^ 1100 = 0110` |
| NOT | `~` | flips every bit | `~1010 = 0101` (within bit width) |
| Shift left | `<<` | shifts bits left, fills with 0 (multiply by 2ⁿ) | `0001 << 2 = 0100` |
| Shift right | `>>` | shifts bits right (divide by 2ⁿ; sign-extends for signed types) | `1000 >> 2 = 0010` |

### Applications
- **Flags**: pack many true/false options into one integer, e.g. Unix file permission bits, CPU status flags.
- **Masks**: use AND with a mask to isolate specific bits (`value & 0xFF` extracts the lowest byte).
- **Permissions**: `chmod` values are literally bitmasks (read=4, write=2, execute=1).
- **Compression**: many algorithms pack data into fewer bits than a "natural" representation (e.g., variable-length codes in Huffman coding).
- **Encryption**: XOR is a building block of stream ciphers and one-time pads (XOR-ing with the same key twice returns the original data).
- **Networking**: header fields (flags, subnet masks) are bit-packed for efficiency.
- **Graphics**: pixel blending, color channel extraction (`(pixel >> 16) & 0xFF` gets the red channel from a 0xRRGGBB value).
- **Operating systems**: page table entries, permission bits, and memory-mapped I/O all rely on bit-level packing.

---

## PART 13 — Bit Manipulation Tricks

Let `x` be an integer and `n` be a bit position (0 = LSB).

```c
// Set bit n
x = x | (1 << n);

// Clear bit n
x = x & ~(1 << n);

// Toggle bit n
x = x ^ (1 << n);

// Check bit n
bool is_set = (x >> n) & 1;

// Extract bits [start, end] (inclusive, 0-indexed from LSB)
int width = end - start + 1;
int mask = (1 << width) - 1;
int extracted = (x >> start) & mask;

// Count set bits (population count / popcount) - Brian Kernighan's algorithm
int count = 0;
while (x) {
    x = x & (x - 1);   // clears the lowest set bit each iteration
    count++;
}

// Detect power of two
bool is_power_of_two = x > 0 && (x & (x - 1)) == 0;
// Reasoning: powers of two have exactly one set bit;
// x-1 flips that bit and all lower bits, so ANDing gives 0.

// Reverse bits (8-bit example, brute-force loop)
uint8_t reverse8(uint8_t x) {
    uint8_t result = 0;
    for (int i = 0; i < 8; i++) {
        result = (result << 1) | (x & 1);
        x >>= 1;
    }
    return result;
}

// Rotate left by k bits (n-bit width)
uint32_t rotl(uint32_t x, int k) {
    return (x << k) | (x >> (32 - k));
}
```

These primitives (set/clear/toggle/extract/popcount/rotate) show up constantly in cryptographic hash functions, compression codecs, and low-level driver code.

---

## PART 14 — Binary in C

### Integer type sizes (typical on a 64-bit system)
| Type | Size | Notes |
|---|---|---|
| `char` | 1 byte | also used for raw byte manipulation |
| `short` | 2 bytes | |
| `int` | 4 bytes | |
| `long` | 4 or 8 bytes (platform-dependent!) | |
| `long long` | 8 bytes | |
| `size_t` | matches pointer width (4 or 8 bytes) | used for sizes/indices, always unsigned |
| `uint32_t` / `uint64_t` | exactly 4 / 8 bytes | fixed-width types from `<stdint.h>`, preferred for portability |

`long`'s size varying by platform is a classic portability trap — this is exactly why fixed-width types (`uint32_t`, `int64_t`) exist.

### Bit fields
```c
struct Flags {
    unsigned int is_active : 1;   // 1 bit
    unsigned int priority   : 3;   // 3 bits (0-7)
    unsigned int reserved   : 4;   // padding to a byte
};
```
Bit fields let you pack multiple small values into fewer bytes, at the cost of some portability (bit-field layout order is implementation-defined between compilers).

### Struct packing and alignment
Compilers insert padding between struct members so each is aligned to its natural boundary (see Part 11). You can override this with compiler-specific pragmas (`#pragma pack`) — useful (and necessary) when a struct must exactly match a binary file format or network protocol layout, at the cost of possibly slower memory access.

---

## PART 15 — Binary Files

Binary files store raw bytes not meant to be read as plain text. Most formats start with **magic bytes** — a fixed byte sequence identifying the file type, so tools (and operating systems) can recognize a file without trusting its extension.

| Format | Magic bytes (hex) | Notes |
|---|---|---|
| PNG | `89 50 4E 47 0D 0A 1A 0A` | includes "PNG" in ASCII plus control bytes to detect corruption from text-mode transfers |
| JPEG | `FF D8 FF` | |
| PDF | `25 50 44 46` (`%PDF`) | |
| ZIP | `50 4B 03 04` (`PK..`) | "PK" = Phil Katz, ZIP's creator |
| ELF (Linux executables) | `7F 45 4C 46` (`.ELF`) | |
| PE (Windows executables) | `4D 5A` (`MZ`) at file start, `50 45 00 00` (`PE\0\0`) at the actual header | "MZ" = Mark Zbikowski, an early MS-DOS architect |
| Mach-O (macOS executables) | `FE ED FA CE` / `CF FA ED FE` (32/64-bit) | |

After the magic bytes, most formats have a structured **header** containing metadata (dimensions, compression type, version, offsets to other sections) followed by the actual data payload.

---

## PART 16 — Binary Executables: From Source Code to Machine Code

### The toolchain
1. **Compiler** — translates source code (e.g. C) into assembly language for a target CPU architecture.
2. **Assembler** — translates human-readable assembly (`MOV`, `ADD`) into raw machine code bytes (opcodes).
3. **Linker** — combines multiple compiled object files and libraries into a single executable, resolving references between them (e.g., where does the `printf` function actually live?).
4. **Loader** — part of the OS; when you run a program, the loader reads the executable file, maps its sections into memory, sets up the stack, and hands control to the entry point.

### Executable sections
| Section | Contents |
|---|---|
| `.text` | the actual machine code instructions (typically read-only, executable) |
| `.data` | initialized global/static variables |
| `.bss` | uninitialized global/static variables (zero-filled at load time; doesn't take space *in the file*, only in memory) |
| `.rodata` | read-only data — string literals, constants |

This section layout is why, for instance, trying to write to a string literal in C (`char *s = "hello"; s[0] = 'H';`) often crashes — that string lives in `.rodata`, which the OS maps as non-writable memory.

---

## PART 17 — The CPU

### Key components
- **Registers**: tiny, extremely fast storage locations built directly into the CPU (e.g., `EAX`, `RBX` on x86). Holds operands and results during computation — far faster than RAM.
- **ALU (Arithmetic Logic Unit)**: the circuit that actually performs arithmetic and bitwise operations.
- **Control Unit**: orchestrates the whole process — fetches instructions, decodes them, and directs the ALU/registers/memory accordingly.
- **Instruction Decoder**: translates a binary opcode into the specific control signals needed to execute it.

### Instruction anatomy
A machine instruction typically breaks into:
- **Opcode**: the binary code identifying *which* operation to perform (e.g., "add," "move," "jump").
- **Operands**: the data or register/memory references the operation acts on.

### The instruction cycle (Fetch-Decode-Execute)
1. **Fetch**: CPU reads the next instruction from memory (address given by the Program Counter register).
2. **Decode**: the Instruction Decoder figures out what operation and operands are encoded.
3. **Execute**: the ALU (or other unit) actually performs the operation.
4. Repeat, advancing the Program Counter — unless a jump/branch instruction redirected it.

### Pipelining and clock
Modern CPUs **pipeline** this cycle — overlapping fetch/decode/execute of multiple instructions simultaneously (like an assembly line) to increase throughput. The **clock** is the CPU's heartbeat — each tick advances the pipeline stages; clock speed (GHz) is roughly how many of these ticks happen per second.

---

## PART 18 — Assembly Language

Assembly is a thin, human-readable layer directly over machine code — each assembly instruction corresponds (roughly) to one machine instruction.

| Instruction | Meaning |
|---|---|
| `MOV dst, src` | copy a value from src to dst |
| `ADD dst, src` | dst = dst + src |
| `SUB dst, src` | dst = dst - src |
| `CMP a, b` | compute `a - b` and set flags, without storing the result (used to prepare for conditional jumps) |
| `JMP label` | unconditional jump to another instruction |
| `CALL func` | push return address, jump to a function |
| `RET` | pop return address, jump back to caller |

Example (x86-ish pseudo-assembly) for `if (a == b) x = 1; else x = 0;`:
```asm
    MOV EAX, [a]
    CMP EAX, [b]
    JNE not_equal
    MOV [x], 1
    JMP done
not_equal:
    MOV [x], 0
done:
```

**Understanding opcodes**: each mnemonic like `MOV` or `ADD` corresponds to a specific binary opcode (plus operand encoding) that the CPU's decoder recognizes — this is the actual "machine code" stored in a `.text` section, and what disassemblers (Part 23) translate back into readable mnemonics.

---

## PART 19 — Binary and Operating Systems

- **Processes**: an OS abstraction giving each running program its own isolated view of memory, CPU time, and resources — implemented via hardware support (like the page tables below) plus OS bookkeeping.
- **Virtual memory**: each process sees a private, contiguous address space; the OS + hardware (MMU) translate these **virtual addresses** to actual **physical addresses** in RAM, enabling isolation and letting programs use more memory than physically exists (via swapping to disk).
- **Pages**: virtual memory is divided into fixed-size chunks (commonly 4KB) called pages, mapped to physical memory frames via **page tables**. This granularity is why 4096 (2¹²) shows up so often in low-level programming.
- **Permissions**: pages can be marked readable, writable, and/or executable — the hardware enforces this, which is why (for example) you generally can't execute data or write to code, a key defense against certain exploits.
- **System calls**: the controlled gateway a user-space program uses to request services (file I/O, memory allocation, networking) from the kernel — typically implemented via a special CPU instruction that triggers a mode switch from user mode to kernel mode.
- **Stack**: grows/shrinks automatically as functions are called/return; stores local variables, function arguments, and return addresses.
- **Heap**: manually (or garbage-collector) managed memory for dynamically allocated data whose lifetime isn't tied to a single function call.
- **Kernel**: the privileged core of the OS that directly manages hardware, memory, and processes.

---

## PART 20 — Networking

Every network protocol is, at its core, a precisely specified binary layout.

- **Ethernet frames**: carry a destination/source MAC address, a type field, and a payload, plus a checksum for error detection.
- **IP (Internet Protocol)**: headers include version, header length, total length, TTL (time-to-live, decremented at each hop to prevent infinite routing loops), protocol number, and source/destination addresses — all packed into specific bit-field positions.
- **TCP**: adds sequence numbers, acknowledgment numbers, and **flags** (SYN, ACK, FIN, RST) packed as individual bits in a single byte, used to manage connection establishment/teardown and reliability.
- **UDP**: a much simpler header — source port, destination port, length, checksum — with no built-in reliability or ordering.
- **Checksums**: a value computed from the rest of the packet's bits so the receiver can detect (some) transmission errors — often as simple as a one's-complement sum of 16-bit words.
- **Ports**: 16-bit numbers (hence 0–65535, matching 2¹⁶) identifying which application on a host a packet belongs to.

Because these headers are bit-packed for efficiency, parsing them correctly means understanding exact bit offsets, field widths, and — critically — that data crossing the network is transmitted in **big-endian ("network byte order")**, requiring conversion on little-endian machines like x86 (`htons`/`ntohs` in C).

---

## PART 21 — Cryptography at the Bit Level

- **XOR** is foundational: XOR-ing data with a key, then XOR-ing the result with the same key again, perfectly recovers the original data (`a ^ b ^ b = a`). This is the basis of stream ciphers and the theoretically unbreakable **one-time pad** (when the key is truly random, as long as the message, and never reused).
- **Randomness / entropy**: cryptographic security depends on keys being unpredictable — "entropy" measures how much genuine randomness (unpredictability) a bit sequence contains. Poor entropy sources are a classic real-world vulnerability (predictable keys are effectively no security at all).
- **Keys**: fixed-length bit sequences used as secret parameters to encryption algorithms — key length (128-bit, 256-bit) directly determines how many possible keys an attacker would need to brute-force.
- **AES (Advanced Encryption Standard)**: a block cipher operating on 128-bit blocks, using rounds of substitution (byte-level lookup tables), permutation (bit/byte rearrangement), and XOR with round keys derived from the main key.
- **RSA**: unlike AES, RSA is asymmetric — it relies on number-theoretic operations (modular exponentiation) on very large binary integers (thousands of bits), where the difficulty of factoring the product of two large primes underpins its security.
- **Hashes** (like SHA-256): take an arbitrary-length bit string and deterministically produce a fixed-length "digest," designed so that even a 1-bit change in input completely scrambles the output (the "avalanche effect") and so that finding two inputs with the same hash ("collision") is computationally infeasible.
- **Bit permutations**: many ciphers include explicit steps that rearrange bit positions according to a fixed pattern, increasing "diffusion" (spreading the influence of each input bit across many output bits).

---

## PART 22 — Cybersecurity

Nearly every category of low-level security work is really "binary literacy applied":

- **Reverse engineering**: recovering a program's logic/structure from its compiled binary, without source code.
- **Disassembly**: mechanically translating machine code back into assembly mnemonics.
- **Shellcode**: small, self-contained snippets of machine code (often hand-crafted or generated) designed to be injected into and executed by a vulnerable process.
- **Memory corruption**: bugs where a program writes data outside its intended bounds, corrupting adjacent memory (other variables, pointers, or even the instruction flow itself).
- **Buffer overflows**: the classic memory corruption bug — writing past the end of a fixed-size buffer, potentially overwriting a saved return address on the stack to hijack program execution.
- **ROP (Return-Oriented Programming)**: an advanced exploitation technique that chains together small existing snippets of code already present in a binary ("gadgets") to perform arbitrary actions, sidestepping defenses that prevent injecting *new* executable code.
- **Binary exploitation**: the general discipline of turning software bugs (like the above) into a working exploit that achieves some attacker goal (code execution, privilege escalation, information leak).
- **Binary patching**: directly modifying compiled machine code (rather than source) to change program behavior — used both maliciously and for legitimate purposes (bug fixes without source, license bypass research, game modding).
- **Malware analysis**: applying reverse engineering to understand what a malicious binary actually does, usually in an isolated ("sandboxed") environment.

---

## PART 23 — Reverse Engineering Toolbox

### File formats you'll be dissecting
- **ELF** — the standard executable/object file format on Linux and most Unix-likes.
- **PE** — the Windows executable format.
- **Mach-O** — the macOS/iOS executable format.

### Tools and what they're for
| Tool | Purpose |
|---|---|
| `objdump` | disassembles binaries, shows section headers, symbol tables |
| `strings` | extracts printable text sequences from a binary — often a fast first clue about what a program does |
| `nm` | lists symbols (function/variable names) in an object file |
| `hexdump` / `xxd` | displays raw file bytes in hex (and often ASCII) side by side — the basic tool for eyeballing binary file structure |
| `readelf` | detailed inspection specifically of ELF file structure |
| `gdb` | interactive debugger — step through execution, inspect registers/memory live |
| `radare2` | powerful open-source reverse engineering framework (disassembly, debugging, scripting) |
| `Ghidra` | NSA-developed free disassembler/decompiler with a GUI, popular for larger reverse engineering projects |
| `IDA` (Interactive DisAssembler) | industry-standard commercial disassembler/decompiler |

A typical reverse-engineering workflow: `file` to identify the format → `strings` for quick clues → `objdump`/`readelf` to inspect structure and sections → a disassembler/decompiler (Ghidra/IDA/radare2) to understand logic → `gdb` to dynamically verify behavior by actually running it.

---

## PART 24 — Projects (Roadmap for Hands-On Practice)

**Beginner**
- Decimal ↔ Binary converter
- Binary calculator (add/subtract/multiply using only bitwise ops)
- Hex converter
- ASCII table explorer
- UTF-8 encoder/decoder

**Intermediate**
- Terminal hex editor
- Binary file viewer
- Bit visualizer (show a number's binary layout interactively)
- IEEE-754 converter (float ↔ raw bits)
- Binary clock

**Advanced**
- ELF parser (read sections/symbols from a real ELF file)
- PE parser
- PNG parser (decode header + basic chunks)
- JPEG parser
- Mini assembler
- Mini disassembler

**Expert**
- CHIP-8 emulator (a great, well-documented first emulator project)
- 8-bit CPU emulator
- Virtual machine (define your own bytecode + interpreter)
- Simple linker
- Toy compiler
- Binary diff tool
- Packet analyzer

**Suggested order:** work top to bottom within each tier before moving to the next — the beginner projects build the number-system fluency the intermediate projects assume, and so on.

---

## Mastery Checklist — Answered

**1. Why do computers use binary instead of decimal?**
Because transistors are cheap and reliable at distinguishing two voltage states, but expensive and error-prone at reliably distinguishing ten (or more) states on the same wire.

**2. Why is hexadecimal so common in systems programming?**
Because each hex digit maps exactly onto 4 bits (a nibble), making hex a compact, easy-to-convert shorthand for binary — far easier to read and convert than decimal.

**3. How is -42 represented in memory (8-bit)?**
Two's complement: take `42` (`00101010`), flip all bits (`11010101`), add 1 → `11010110`.

**4. What happens when an unsigned integer overflows?**
It wraps around modulo 2ⁿ — e.g., an 8-bit unsigned `255 + 1` becomes `0`, since the resulting carry bit is discarded.

**5. Why does floating-point arithmetic have rounding errors?**
Because most decimal fractions (like 0.1) can't be represented exactly as a finite sum of powers of 2, so IEEE-754 stores the closest representable approximation, and arithmetic on approximations compounds small errors.

**6. How does UTF-8 encode characters of different sizes?**
Using a variable-width scheme (1–4 bytes) where the leading bits of the first byte indicate how many total bytes the character occupies, keeping ASCII characters identical to plain 7-bit ASCII.

**7. Little-endian vs big-endian?**
Little-endian stores the least significant byte at the lowest memory address; big-endian stores the most significant byte first. Network protocols conventionally use big-endian ("network byte order"), while x86/x64 CPUs are little-endian internally.

**8. How do bitwise operators work, and when should you use them?**
AND/OR/XOR/NOT operate bit-by-bit; shifts move bits left/right. Use them for flags, masks, permissions, and any scenario needing compact, fast manipulation of individual bits rather than whole numeric values.

**9. What does an ELF executable contain?**
A header identifying it as ELF plus metadata (architecture, entry point), followed by sections like `.text` (code), `.data`/`.bss` (variables), `.rodata` (constants), and tables describing symbols and how to load/link the file.

**10. How does a CPU fetch, decode, and execute binary instructions?**
It repeatedly fetches the next instruction (from the address in the Program Counter), decodes the opcode/operands into control signals, executes via the ALU or other units, and advances (or jumps) the Program Counter — all synchronized to the clock, often overlapped via pipelining.

**11. How does a compiler turn C code into machine code?**
The compiler translates source into assembly for the target architecture; an assembler turns that into raw machine code (object files); a linker combines object files/libraries into a final executable, resolving cross-references.

**12. How do network protocols represent fields and flags as bits?**
Via precisely specified, fixed-position bit fields within each header — e.g., TCP's SYN/ACK/FIN flags are individual bits within one header byte, and IP addresses are packed 32-bit (or 128-bit for IPv6) integers.

**13. How can understanding binary help with reverse engineering and exploit development?**
Reverse engineering requires reading raw machine code, file formats, and memory layouts directly; exploit development requires precisely manipulating bytes (offsets, addresses, encoded instructions) to redirect a program's execution — both are impossible without fluency in binary, hex, two's complement, and endianness.

---

## Suggested Study Sequence (Recap)
1. Why binary and number systems (Parts 1–2)
2. Binary arithmetic and powers of two (Parts 3–4)
3. Bits, bytes, and memory representation (Parts 5–7, 11)
4. Signed integers and two's complement (Part 8)
5. Hexadecimal and octal (already covered in Part 2 — revisit)
6. ASCII and Unicode, especially UTF-8 (Part 10)
7. Bitwise operations and bit manipulation (Parts 12–13)
8. Endianness and memory layout (Part 11 — revisit)
9. IEEE-754 floating point (Part 9)
10. Binary file formats (Part 15)
11. CPU architecture and machine code (Part 17)
12. Assembly language (Part 18)
13. Operating systems, networking, and security (Parts 19–23)

Work through the **Level 1–5 exercises** and the **project ladder** in Part 24 alongside this reading — binary fluency is built by doing conversions and writing bit-manipulation code by hand, not just reading about it.
