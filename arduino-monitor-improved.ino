#include "src/asm_defs.h"

/**
 * Arduino UNO Monitor - IMPROVED VERSION
 * Low-level register and memory inspector.
 * Make sure you set baud rate in Serial Monitor to 115200
 * 
 * IMPROVEMENTS:
 * - Added input validation
 * - Fixed word/byte address handling
 * - Improved performance with buffered output
 * - Better error handling
 * - Added bounds checking
 * - Non-blocking input with timeout
 */

extern "C" {
void capture_registers(uint8_t *buffer);
void restore_and_execute(uint16_t address, uint8_t *buffer);
void restore_and_call(uint16_t address, uint8_t *buffer);
}

extern char _etext;
extern char __data_load_start;

uint8_t reg_file[64];

// Memory bounds for ATmega328P (Arduino UNO)
#define SRAM_START    0x0100
#define SRAM_END      0x08FF  // 2KB SRAM
#define FLASH_END     0x7FFF  // 32KB Flash
#define IO_START      0x0020
#define IO_END        0x00FF

// --- Constants for non-blocking input ---
#define INPUT_TIMEOUT_MS 15000  // 15 seconds
#define INPUT_TIMEOUT_SENTINEL 0xFFFF

// --- Utility Functions ---
void printHex8(uint8_t val) {
  if (val < 16)
    Serial.print('0');
  Serial.print(val, HEX);
}

void printHex16(uint16_t val) {
  printHex8(val >> 8);
  printHex8(val & 0xFF);
}

// Validate SRAM address
bool isValidSRAMAddress(uint16_t addr) {
  return (addr >= SRAM_START && addr <= SRAM_END);
}

// Validate Flash address
bool isValidFlashAddress(uint16_t addr) {
  return (addr <= FLASH_END);
}

// Check if address is in I/O space (potentially dangerous)
bool isIOAddress(uint16_t addr) {
  return (addr >= IO_START && addr < SRAM_START);
}

uint16_t readInputLine(char *buffer, uint8_t maxLen, bool isHex, uint32_t timeout_ms) {
  uint8_t pos = 0;
  uint32_t startTime = millis();
  
  while (millis() - startTime < timeout_ms) {
    if (Serial.available()) {
      char c = Serial.read();
      if (c == '\n' || c == '\r') {
        if (pos > 0) {
          buffer[pos] = '\0';
          Serial.println();
          return (uint16_t)strtol(buffer, NULL, isHex ? 16 : 10);
        }
        // Reset start time on empty input to avoid immediate timeout
        startTime = millis(); 
        continue;
      } else if (c == 0x08 || c == 0x7F) { // Backspace or Del
        if (pos > 0) {
          pos--;
          Serial.print(F("\b \b"));
        }
      } else if (pos < maxLen - 1) {
        // Only accept valid hex/dec digits
        if ((isHex && isxdigit(c)) || (!isHex && isdigit(c))) {
          buffer[pos++] = c;
          Serial.print(c);
        }
      }
      // Reset start time on any valid keypress
      startTime = millis();
    }
  }

  Serial.println(F("\nERROR: Input timeout."));
  return INPUT_TIMEOUT_SENTINEL;
}

uint16_t readHexInput() {
  char buf[10];
  return readInputLine(buf, sizeof(buf), true, INPUT_TIMEOUT_MS);
}

uint16_t readDecInput() {
  char buf[10];
  return readInputLine(buf, sizeof(buf), false, INPUT_TIMEOUT_MS);
}

void displayMenu() {
  Serial.println(F("\n--- AVR MONITOR ---"));
  Serial.println(F("1. Read Registers (Snapshot)"));
  Serial.println(F("2. Modify Register (in Snapshot)"));
  Serial.println(F("3. Read Memory (RAM)"));
  Serial.println(F("4. Write Memory (RAM)"));
  Serial.println(F("5. Call Flash Address (Word Addr)"));
  Serial.println(F("6. Read Flash Memory (Dump)"));
  Serial.println(F("7. Display Program Address Info"));
  Serial.print(F("Choice> "));
}

void setup() {
  Serial.begin(115200);
  while (!Serial)
    ;
  Serial.println(F("Monitor Ready."));
  Serial.print(F("SRAM: 0x"));
  printHex16(SRAM_START);
  Serial.print(F(" - 0x"));
  printHex16(SRAM_END);
  Serial.println();
}

void loop() {
  displayMenu();

  // Wait for a valid command key (with timeout)
  char choice = 0;
  uint32_t menuStartTime = millis();
  while (millis() - menuStartTime < INPUT_TIMEOUT_MS) {
    if (Serial.available()) {
      choice = Serial.read();
      if (choice >= '1' && choice <= '7') {
        goto choice_made;
      }
    }
  }
  // If loop finishes, it's a timeout
  Serial.println(F("\nTimeout waiting for command. Refreshing menu..."));
  return;

choice_made:
  Serial.println(choice);

  switch (choice) {
  case '1': {
    capture_registers(reg_file);
    Serial.println(F("Register Snapshot:"));
    for (int i = 0; i < 32; i++) {
      Serial.print(F("r"));
      if (i < 10) Serial.print('0');
      Serial.print(i);
      Serial.print(F(": "));
      printHex8(reg_file[i]);
      if ((i + 1) % 4 == 0)
        Serial.println();
      else
        Serial.print(F("\t"));
    }
    Serial.print(F("SREG: "));
    printHex8(reg_file[SREG_BUFFER_INDEX]);
    Serial.print(F(" ["));
    // Decode SREG bits
    if (reg_file[SREG_BUFFER_INDEX] & 0x80) Serial.print('I');
    else Serial.print('-');
    if (reg_file[SREG_BUFFER_INDEX] & 0x40) Serial.print('T');
    else Serial.print('-');
    if (reg_file[SREG_BUFFER_INDEX] & 0x20) Serial.print('H');
    else Serial.print('-');
    if (reg_file[SREG_BUFFER_INDEX] & 0x10) Serial.print('S');
    else Serial.print('-');
    if (reg_file[SREG_BUFFER_INDEX] & 0x08) Serial.print('V');
    else Serial.print('-');
    if (reg_file[SREG_BUFFER_INDEX] & 0x04) Serial.print('N');
    else Serial.print('-');
    if (reg_file[SREG_BUFFER_INDEX] & 0x02) Serial.print('Z');
    else Serial.print('-');
    if (reg_file[SREG_BUFFER_INDEX] & 0x01) Serial.print('C');
    else Serial.print('-');
    Serial.println(']');
    break;
  }

  case '2': {
    Serial.print(F("Reg index (0-31): "));
    uint16_t idx = readDecInput();
    if (idx == INPUT_TIMEOUT_SENTINEL) break;
    if (idx > 31) {
      Serial.println(F("ERROR: Invalid index (must be 0-31)"));
      break;
    }
    Serial.print(F("New Value (Hex): "));
    uint16_t val_read = readHexInput();
    if (val_read == INPUT_TIMEOUT_SENTINEL) break;
    uint8_t val = (uint8_t)val_read;
    
    reg_file[idx] = val;
    Serial.print(F("Updated r"));
    Serial.print(idx);
    Serial.print(F(" = 0x"));
    printHex8(val);
    Serial.println();
    break;
  }

  case '3': {
    Serial.print(F("Address (Hex): "));
    uint16_t addr = readHexInput();
    if (addr == INPUT_TIMEOUT_SENTINEL) break;
    
    if (!isValidSRAMAddress(addr)) {
      Serial.print(F("WARNING: Address 0x"));
      printHex16(addr);
      Serial.println(F(" is outside SRAM range!"));
      if (isIOAddress(addr)) {
        Serial.println(F("This is in I/O register space."));
      }
      Serial.print(F("Continue anyway? (y/n): "));
      while (!Serial.available());
      char confirm = Serial.read();
      Serial.println(confirm);
      if (confirm != 'y' && confirm != 'Y') {
        Serial.println(F("Cancelled."));
        break;
      }
    }
    
    Serial.print(F("Length (Dec): "));
    uint16_t len = readDecInput();
    if (len == INPUT_TIMEOUT_SENTINEL) break;

    if ((uint32_t)addr + len > 0xFFFF) {
      Serial.println(F("ERROR: Length would overflow address space!"));
      break;
    }
    
    volatile uint8_t *ptr = (volatile uint8_t *)addr;

    for (uint16_t i = 0; i < len; i++) {
      if (i % 16 == 0) {
        Serial.println();
        printHex16(addr + i);
        Serial.print(F(": "));
      }
      printHex8(ptr[i]);
      Serial.print(F(" "));
      
      if (i % 64 == 63) {
        delay(1);
      }
    }
    Serial.println();
    break;
  }

  case '4': {
    Serial.print(F("Address (Hex): "));
    uint16_t addr = readHexInput();
    if (addr == INPUT_TIMEOUT_SENTINEL) break;

    if (!isValidSRAMAddress(addr)) {
      Serial.print(F("ERROR: Address 0x"));
      printHex16(addr);
      Serial.println(F(" is not in writable SRAM!"));
      if (isIOAddress(addr)) {
        Serial.println(F("Writing to I/O registers can be dangerous!"));
        Serial.print(F("Force write? (y/n): "));
        while (!Serial.available());
        char confirm = Serial.read();
        Serial.println(confirm);
        if (confirm != 'y' && confirm != 'Y') {
          Serial.println(F("Cancelled."));
          break;
        }
      } else {
        Serial.println(F("Cannot write to Flash or invalid address."));
        break;
      }
    }
    
    Serial.print(F("Value (Hex): "));
    uint16_t val_read = readHexInput();
    if (val_read == INPUT_TIMEOUT_SENTINEL) break;
    uint8_t val = (uint8_t)val_read;

    Serial.print(F("Writing 0x"));
    printHex8(val);
    Serial.print(F(" to 0x"));
    printHex16(addr);
    Serial.print(F("... "));

    *(volatile uint8_t *)addr = val;

    uint8_t readback = *(volatile uint8_t *)addr;
    if (readback == val) {
      Serial.println(F("Verified."));
    } else {
      Serial.print(F("FAILED (Readback: 0x"));
      printHex8(readback);
      Serial.println(F(")"));
    }
    break;
  }

  case '5': {
    Serial.print(F("Flash WORD Address (Hex): "));
    uint16_t word_addr = readHexInput();
    if (word_addr == INPUT_TIMEOUT_SENTINEL) break;

    if ((uint32_t)word_addr * 2 > FLASH_END) {
      Serial.println(F("ERROR: Address beyond Flash memory!"));
      break;
    }
    
    Serial.println(F("WARNING: This will jump to the specified address."));
    Serial.println(F("Execution may not return if target doesn't ret."));
    Serial.print(F("Continue? (y/n): "));
    
    while (!Serial.available());
    char confirm = Serial.read();
    Serial.println(confirm);
    
    if (confirm != 'y' && confirm != 'Y') {
      Serial.println(F("Cancelled."));
      break;
    }
    
    Serial.println(F("Restoring registers and jumping..."));
    Serial.flush();
    delay(100);
    
    restore_and_call(word_addr, reg_file);
    
    Serial.println(F("Returned from call."));
    break;
  }

  case '6': {
    Serial.print(F("Flash Byte Address (Hex): "));
    uint16_t addr = readHexInput();
    if (addr == INPUT_TIMEOUT_SENTINEL) break;
    
    if (!isValidFlashAddress(addr)) {
      Serial.println(F("ERROR: Address beyond Flash memory!"));
      break;
    }
    
    Serial.print(F("Length (Dec): "));
    uint16_t len = readDecInput();
    if (len == INPUT_TIMEOUT_SENTINEL) break;
    
    if ((uint32_t)addr + len > FLASH_END + 1) {
      Serial.println(F("ERROR: Length exceeds Flash memory!"));
      break;
    }

    Serial.println(F("--- FLASH DUMP ---"));
    for (uint16_t i = 0; i < len; i++) {
      uint16_t currentAddr = addr + i;
      
      if (i > 0 && (currentAddr % 1024 == 0)) {
        Serial.println(F("\n[ --- 1K BLOCK BOUNDARY --- ]"));
      }
      
      if (i % 16 == 0) {
        if (i > 0)
          Serial.println();
        printHex16(currentAddr);
        Serial.print(F(": "));
      }
      
      uint8_t val = pgm_read_byte(currentAddr);
      printHex8(val);
      Serial.print(F(" "));
      
      if (i % 64 == 63) {
        delay(1);
      }
    }
    Serial.println(F("\n--- END DUMP ---"));
    break;
  }

  case '7': {
    Serial.println(F("\n--- PROGRAM/MEMORY ADDRESS INFO ---"));
    Serial.print(F("SRAM Start:                   0x"));
    printHex16(SRAM_START);
    Serial.println();
    Serial.print(F("SRAM End:                     0x"));
    printHex16(SRAM_END);
    Serial.println();
    Serial.print(F("reg_file pointer:             0x"));
    printHex16((uint16_t)reg_file);
    Serial.println();
    Serial.print(F("Flash Start:                  0x0000\n"));
    Serial.print(F("Flash End:                    0x"));
    printHex16(FLASH_END);
    Serial.println();
    Serial.print(F("Code End (_etext):            0x"));
    printHex16((uint16_t)&_etext);
    Serial.println();
    Serial.print(F("Data Load Start in Flash:     0x"));
    printHex16((uint16_t)&__data_load_start);
    Serial.println();
    Serial.print(F("loop() byte address:          0x"));
    printHex16((uint16_t)loop);
    Serial.print(F(" (word: 0x"));
    printHex16((uint16_t)loop >> 1);
    Serial.println(F(")"));
    Serial.print(F("setup() byte address:         0x"));
    printHex16((uint16_t)setup);
    Serial.print(F(" (word: 0x"));
    printHex16((uint16_t)setup >> 1);
    Serial.println(F(")"));
    
    uint16_t sp = SP;
    Serial.print(F("Current Stack Pointer:        0x"));
    printHex16(sp);
    Serial.println();
    
    extern int __heap_start, *__brkval;
    int v;
    int free_mem = (int)&v - (__brkval == 0 ? (int)&__heap_start : (int)__brkval);
    Serial.print(F("Free Memory (approx):         "));
    Serial.print(free_mem);
    Serial.println(F(" bytes"));
    break;
  }
  }

  while (Serial.available())
    Serial.read();
}
