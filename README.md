# Arduino UNO Monitor

A low-level register and memory inspector for Arduino UNO (ATmega328P). This tool provides direct access to AVR registers, RAM, and Flash memory for debugging and educational purposes.

## Features

- **Register Inspection**: Capture and display all 32 general-purpose registers plus SREG
- **Register Modification**: Modify register snapshots before execution
- **Memory Reading**: Read from any SRAM address with bounds checking
- **Memory Writing**: Write to SRAM with validation and verification
- **Flash Execution**: Call arbitrary Flash addresses with register state restoration
- **Flash Dumping**: Dump Flash memory contents in hex format
- **Address Information**: Display program memory layout and symbol addresses

## Hardware Requirements

- Arduino UNO (ATmega328P)
- USB connection for Serial communication

## Installation

1. Clone this repository
2. Open `arduino-monitor-improved.ino` in Arduino IDE
3. Ensure `asm_utils_fixed.S` is in the same directory
4. Set Serial Monitor baud rate to **115200**
5. Upload to your Arduino UNO

## Usage

After uploading, open the Serial Monitor at 115200 baud. You'll see a menu:

```
--- AVR MONITOR ---
1. Read Registers (Snapshot)
2. Modify Register (in Snapshot)
3. Read Memory (RAM)
4. Write Memory (RAM)
5. Call Flash Address (Word Addr)
6. Read Flash Memory (Dump)
7. Display Program Address Info
Choice>
```

### Examples

**Read all registers:**
```
Choice> 1
```

**Read 64 bytes of RAM starting at 0x0100:**
```
Choice> 3
Address (Hex): 0100
Length (Dec): 64
```

**Dump 256 bytes of Flash starting at address 0x0000:**
```
Choice> 6
Flash Byte Address (Hex): 0000
Length (Dec): 256
```

## Safety Features

- Input validation for all memory operations
- Bounds checking for SRAM (0x0100-0x08FF)
- Warnings when accessing I/O register space
- Confirmation prompts for potentially dangerous operations
- Write verification with readback

## Memory Map (ATmega328P)

```
0x0000 - 0x001F: General Purpose Registers (not directly accessible)
0x0020 - 0x00FF: I/O Registers
0x0100 - 0x08FF: SRAM (2KB)
0x0000 - 0x7FFF: Flash Memory (32KB, word-addressed in hardware)
```

## Technical Details

### Register Snapshot

The register snapshot captures:
- All 32 general-purpose registers (r0-r31)
- Status Register (SREG) with decoded flags: I T H S V N Z C

### Assembly Functions

Written in AVR assembly for accurate low-level operations:

- `capture_registers()`: Saves all registers to a buffer
- `restore_and_call()`: Restores registers and calls a Flash address
- Proper handling of stack and SREG to prevent corruption

### Improvements Over Original

This is an improved version with:
- ✅ Fixed stack corruption bug in register restoration
- ✅ Fixed register capture corruption (r24/r25)
- ✅ Proper word/byte address handling for Flash
- ✅ Added comprehensive input validation
- ✅ Added bounds checking and safety warnings
- ✅ Better error messages and user feedback
- ✅ SREG flag decoding
- ✅ Free memory display

See [ANALYSIS_REPORT.md](ANALYSIS_REPORT.md) for detailed analysis of issues found and fixes applied.

## Building

The sketch uses approximately:
- **Program storage**: 6100 bytes (18% of 32KB)
- **Dynamic memory**: 233 bytes (11% of 2KB)

## Files

- `arduino-monitor-improved.ino`: Main program (C++)
- `asm_utils_fixed.S`: Assembly utilities for register operations
- `ANALYSIS_REPORT.md`: Detailed code analysis and improvements
- `README.md`: This file

## Warnings

⚠️ **This tool provides low-level hardware access. Incorrect usage can:**
- Crash the Arduino (requires reset)
- Corrupt memory
- Interfere with Serial communication
- Potentially damage hardware if I/O registers are modified incorrectly

**Use with caution and understand what you're doing!**

## Educational Use

This tool is excellent for:
- Learning AVR architecture
- Understanding register usage
- Debugging low-level code
- Exploring program memory layout
- Teaching embedded systems concepts

## License

MIT License - Feel free to use and modify

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test thoroughly on actual hardware
4. Submit a pull request

## Author

Based on original code by rjp (Jan 28 2026)
Improved and fixed (Jan 29 2026)

## Changelog

### Version 2.0 (Jan 29 2026)
- Fixed critical stack corruption bug
- Fixed register capture corruption
- Added comprehensive input validation
- Added safety warnings
- Improved error handling
- Added SREG decoding
- Better documentation

### Version 1.0 (Jan 28 2026)
- Initial release
