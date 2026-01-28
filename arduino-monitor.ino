/**
 * Arduino UNO Monitor
 * Low-level register and memory inspector.
 */

extern "C" {
void capture_registers(uint8_t *buffer);
void restore_and_execute(uint16_t address, uint8_t *buffer);
}

uint8_t reg_file[33]; // r0-r31 + SREG

void printHex8(uint8_t val) {
  if (val < 16)
    Serial.print('0');
  Serial.print(val, HEX);
}

void printHex16(uint16_t val) {
  printHex8(val >> 8);
  printHex8(val & 0xFF);
}

void displayMenu() {
  Serial.println(F("\n--- AVR MONITOR ---"));
  Serial.println(F("1. Read Registers (Snapshot)"));
  Serial.println(F("2. Modify Register (in Snapshot)"));
  Serial.println(F("3. Read Memory (RAM)"));
  Serial.println(F("4. Write Memory (RAM)"));
  Serial.println(F("5. Call Flash Address"));
  Serial.println(F("6. Read Flash Memory (Dump)"));
  Serial.println(F("7. Display Program Address Info"));
  Serial.print(F("Choice> "));
}

uint16_t readHexInput() {
  String input = "";
  while (true) {
    if (Serial.available()) {
      char c = Serial.read();
      if (c == '\n' || c == '\r') {
        if (input.length() > 0)
          break;
        else
          continue;
      }
      input += c;
      Serial.print(c);
    }
  }
  Serial.println();
  return (uint16_t)strtol(input.c_str(), NULL, 16);
}

void setup() {
  Serial.begin(9600);
  while (!Serial)
    ;
  Serial.println(F("Monitor Ready."));
}

void loop() {
  displayMenu();
  while (!Serial.available())
    ;
  char choice = Serial.read();
  Serial.println(choice);

  switch (choice) {
  case '1': {
    capture_registers(reg_file);
    Serial.println(F("Register Snapshot:"));
    for (int i = 0; i < 32; i++) {
      Serial.print(F("r"));
      Serial.print(i);
      Serial.print(F(": "));
      printHex8(reg_file[i]);
      if ((i + 1) % 4 == 0)
        Serial.println();
      else
        Serial.print(F("\t"));
    }
    Serial.print(F("SREG: "));
    printHex8(reg_file[32]);
    Serial.println();
    break;
  }

  case '2': {
    Serial.print(F("Reg index (0-31): "));
    uint8_t idx = Serial.parseInt();
    if (idx > 31) {
      Serial.println(F("Invalid index"));
      break;
    }
    Serial.print(F("New Value (Hex): "));
    uint8_t val = (uint8_t)readHexInput();
    reg_file[idx] = val;
    Serial.print(F("Updated r"));
    Serial.print(idx);
    Serial.println();
    break;
  }

  case '3': {
    Serial.print(F("Address (Hex): "));
    uint16_t addr = readHexInput();
    Serial.print(F("Length: "));
    uint16_t len = Serial.parseInt();
    volatile uint8_t *ptr = (volatile uint8_t *)addr;

    for (uint16_t i = 0; i < len; i++) {
      if (i % 16 == 0) {
        Serial.println();
        printHex16(addr + i);
        Serial.print(F(": "));
      }
      printHex8(ptr[i]);
      Serial.print(F(" "));
    }
    Serial.println();
    break;
  }

  case '4': {
    Serial.print(F("Address (Hex): "));
    uint16_t addr = readHexInput();
    Serial.print(F("Value (Hex): "));
    uint8_t val = (uint8_t)readHexInput();
    *(volatile uint8_t *)addr = val;
    Serial.println(F("Done."));
    break;
  }

  case '5': {
    Serial.print(F("Flash Word Address (Hex): "));
    uint16_t addr = readHexInput();
    Serial.println(F("Restoring registers and jumping..."));
    delay(100);
    restore_and_execute(addr, reg_file);
    Serial.println(F("Returned."));
    break;
  }

  case '6': {
    Serial.print(F("Flash Address (Hex): "));
    uint16_t addr = readHexInput();
    Serial.print(F("Length (Dec): "));
    uint16_t len = Serial.parseInt();

    Serial.println(F("--- FLASH DUMP ---"));
    for (uint16_t i = 0; i < len; i++) {
      uint16_t currentAddr = addr + i;

      // Add 1K Separator
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
    }
    Serial.println(F("\n--- END DUMP ---"));
    break;
  }

  case '7': {
    Serial.println(F("\n--- PROGRAM ADDRESS INFO ---"));
    Serial.print(F("Flash Start (__text_start):  0x0000 (Physical start)\n"));

    Serial.print(F("Code End (_etext):           0x"));
    printHex16((uint16_t)&_etext);
    Serial.println();

    Serial.print(F("Data Load Start in Flash:    0x"));
    printHex16((uint16_t)&__data_load_start);
    Serial.println();

    Serial.print(F("loop() function address:     0x"));
    printHex16((uint16_t)loop);
    Serial.println();

    Serial.print(F("setup() function address:    0x"));
    printHex16((uint16_t)setup);
    Serial.println();

    Serial.println(F("Note: Addresses are in Bytes."));
    break;
  }

  default:
    Serial.println(F("Unknown command"));
    break;
  }
}
