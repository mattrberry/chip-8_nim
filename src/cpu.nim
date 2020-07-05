import
  random, strformat, strutils,
  display, types

const
  fontset: array[5 * 16, uint8] = [
    0xF0'u8, 0x90'u8, 0x90'u8, 0x90'u8, 0xF0'u8, # 0
    0x20'u8, 0x60'u8, 0x20'u8, 0x20'u8, 0x70'u8, # 1
    0xF0'u8, 0x10'u8, 0xF0'u8, 0x80'u8, 0xF0'u8, # 2
    0xF0'u8, 0x10'u8, 0xF0'u8, 0x10'u8, 0xF0'u8, # 3
    0x90'u8, 0x90'u8, 0xF0'u8, 0x10'u8, 0x10'u8, # 4
    0xF0'u8, 0x80'u8, 0xF0'u8, 0x10'u8, 0xF0'u8, # 5
    0xF0'u8, 0x80'u8, 0xF0'u8, 0x90'u8, 0xF0'u8, # 6
    0xF0'u8, 0x10'u8, 0x20'u8, 0x40'u8, 0x40'u8, # 7
    0xF0'u8, 0x90'u8, 0xF0'u8, 0x90'u8, 0xF0'u8, # 8
    0xF0'u8, 0x90'u8, 0xF0'u8, 0x10'u8, 0xF0'u8, # 9
    0xF0'u8, 0x90'u8, 0xF0'u8, 0x90'u8, 0x90'u8, # A
    0xE0'u8, 0x90'u8, 0xE0'u8, 0x90'u8, 0xE0'u8, # B
    0xF0'u8, 0x80'u8, 0x80'u8, 0x80'u8, 0xF0'u8, # C
    0xE0'u8, 0x90'u8, 0x90'u8, 0x90'u8, 0xE0'u8, # D
    0xF0'u8, 0x80'u8, 0xF0'u8, 0x80'u8, 0xF0'u8, # E
    0xF0'u8, 0x80'u8, 0xF0'u8, 0x80'u8, 0x80'u8, # F
  ]

proc newCPU*(rom: openarray[uint8]): CPU =
  new result
  result.pc = 0x200'u16
  for idx in 0..<fontset.len:
    result.memory[idx] = fontset[idx]
  for idx in 0..<rom.len:
    result.memory[0x200 + idx] = rom[idx]

proc invalidOperation(opcode: uint16) =
  echo(fmt"Encountered an unhandled operation: 0x{toHex(opcode)}")
  quit(1)

proc incrementTimers*(cpu: var CPU) =
  if cpu.soundTimer > 0 and cpu.soundTimerCounter mod 8 == 0:
    cpu.soundTimer -= 1
    cpu.soundTimerCounter = 0
  cpu.soundTimerCounter += 1
  if cpu.delayTimer > 0 and cpu.delayTimerCounter mod 8 == 0:
    cpu.delayTimer -= 1
    cpu.delayTimerCounter = 0
  cpu.delayTimerCounter += 1

proc executeInstruction*(cpu: var CPU, display: Display, keyboard: Keyboard) =
  let
    opcode: uint16 = (uint16(cpu.memory[cpu.pc]) shl 8) or cpu.memory[cpu.pc + 1]
    op_1 = uint8((opcode and 0xF000) shr 12)
    op_2 = uint8((opcode and 0x0F00) shr 8)
    op_3 = uint8((opcode and 0x00F0) shr 4)
    op_4 = uint8((opcode and 0x000F))
    x = op_2
    y = op_3
    n = op_4
    nn = uint8(opcode and 0x00FF)
    nnn = opcode and 0x0FFF
  cpu.pc += 2
  case op_1
  of 0x0:
    case op_3
    of 0xE:
      case op_4
      of 0x0: # cls
        display.clear()
        display.draw()
      of 0xE: # ret
        cpu.pc = cpu.stack[cpu.sp]
        cpu.sp -= 1
      else: invalidOperation(opcode)
    of 0x0: discard # sys addr
    else: invalidOperation(opcode)
  of 0x1: # jp addr
    cpu.pc = nnn
  of 0x2: # call addr
    cpu.sp += 1
    cpu.stack[cpu.sp] = cpu.pc
    cpu.pc = nnn
  of 0x3: # se vx, byte
    if cpu.v[x] == nn:
      cpu.pc += 2
  of 0x4: # sne vx, byte
    if cpu.v[x] != nn:
      cpu.pc += 2
  of 0x5: # se vx, vy
    if cpu.v[x] == cpu.v[y]:
      cpu.pc += 2
  of 0x6: # ld vx, byte
    cpu.v[x] = nn
  of 0x7: # add vx, byte
    cpu.v[x] += nn
  of 0x8:
    case op_4
    of 0x0: # ld vx, vy
      cpu.v[x] = cpu.v[y]
    of 0x1: # or vx, vy
      cpu.v[x] = cpu.v[x] or cpu.v[y]
    of 0x2: # and vx, vy
      cpu.v[x] = cpu.v[x] and cpu.v[y]
    of 0x3: # xor vx, vy
      cpu.v[x] = cpu.v[x] xor cpu.v[y]
    of 0x4: # add vx, vy
      cpu.v[x] += cpu.v[y]
      cpu.v[0xF] = uint8(cpu.v[x] < cpu.v[y])
    of 0x5: # sub vx, vy
      cpu.v[0xF] = uint8(cpu.v[y] > cpu.v[x])
      cpu.v[x] -= cpu.v[y]
    of 0x6: # shr vx, vy
      cpu.v[0xF] = cpu.v[x] and 0x1'u8
      cpu.v[x] = cpu.v[x] shr 1
    of 0x7: # subn vx, vy
      cpu.v[0xF] = uint8(cpu.v[x] <= cpu.v[y])
      cpu.v[x] = cpu.v[y] - cpu.v[x]
    of 0xE: # shl vx, vy
      cpu.v[0xF] = (cpu.v[x] and 0x80'u8) shr 7
      cpu.v[x] = cpu.v[x] shl 1
    else: invalidOperation(opcode)
  of 0x9: # sne vx, vy
    if cpu.v[x] != cpu.v[y]:
      cpu.pc += 2
  of 0xA: # ld i, addr
    cpu.i = nnn
  of 0xB: # jp v0, addr
    cpu.pc = nnn + cpu.v[0]
  of 0xC: # rnd vx, byte
    cpu.v[x] = nn and uint8(rand(256))
  of 0xD: # drw vx, vy, n
    cpu.v[0xF] = 0'u8
    var
      row_byte: uint8
      was_enabled: bool
    for row in 0'u8..<n:
      row_byte = cpu.memory[cpu.i + row]
      for col in 0'u8..<8'u8:
        if (row_byte and (0x80'u8 shr col)) > 0:
          was_enabled = display.getPos(cpu.v[x] + col, cpu.v[y] + row)
          cpu.v[0xF] = cpu.v[0xF] or uint8(was_enabled)
          display.setPos(cpu.v[x] + col, cpu.v[y] + row, not was_enabled)
    display.draw()
  of 0xE:
    case op_3
    of 0x9: # skp vx
      if keyboard.keys[cpu.v[x]]:
        cpu.pc += 2
    of 0xA: # sknp vx
      if not keyboard.keys[cpu.v[x]]:
        cpu.pc += 2
    else: invalidOperation(opcode)
  of 0xF:
    case op_3
    of 0x0:
      case op_4
      of 0x7: # ld vx, dt
        cpu.v[x] = cpu.delayTimer
      of 0xA: discard # ld vx, k
      else: invalidOperation(opcode)
    of 0x1:
      case op_4
      of 0x5: # ld dt, vx
        cpu.delayTimer = cpu.v[x]
      of 0x8: # ld st, vx
        cpu.soundTimer = cpu.v[x]
      of 0xE: # add i, vx
        cpu.i += cpu.v[x]
      else: invalidOperation(opcode)
    of 0x2: # ld f, vx
      cpu.i = cpu.v[x].uint16 * 5
    of 0x3: # ld b, vx
      cpu.memory[cpu.i] = cpu.v[x] div 100
      cpu.memory[cpu.i + 1] = (cpu.v[x] div 10) mod 10
      cpu.memory[cpu.i + 2] = (cpu.v[x] mod 100) mod 10
    of 0x5: # ld (i), vx
      for idx in 0'u8..x:
        cpu.memory[cpu.i + idx] = cpu.v[idx]
    of 0x6: # ld vx, (i)
      for idx in 0'u8..x:
        cpu.v[idx] = cpu.memory[cpu.i + idx]
    else: invalidOperation(opcode)
  else: invalidOperation(opcode)

