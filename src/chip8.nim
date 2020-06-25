import
  os, random, strutils, system

proc invalidOperation(opcode: uint16) =
  echo("Encountered an unhandled operation: 0x$1" % [toHex(opcode)])
  quit(1)

proc emulate() =
  var
    romPath = paramStr(1)
    file = open(romPath)
    memory: array[4096, uint8]
  defer: close(file)
  discard readBytes(file, memory, 0x200, 0xFFF - 0x200)
  var
    v: array[16, uint8]      # general purpose registers
    i: uint16 = 0            # register typically used for addresses
    delay_timer: uint8 = 0   # todo
    sound_timer: uint8 = 0   # todo
    pc: uint16 = 0x200       # program counter starts at rom
    stack: array[16, uint16] # stores addresses to return to from subroutines
    sp: uint8 = 0            # current stack pointer
  while true:
    let
      opcode: uint16 = (uint16(memory[pc]) shl 8) or memory[pc + 1]
      op_1 = uint8((opcode and 0xF000) shr 12)
      op_2 = uint8((opcode and 0x0F00) shr 8)
      op_3 = uint8((opcode and 0x00F0) shr 4)
      op_4 = uint8((opcode and 0x000F))
      x = op_2
      y = op_3
      n = op_4
      nn = uint8(opcode and 0x00FF)
      nnn = opcode and 0x0FFF
    echo("Opcode:0x$1, PC:0x$2" % [toHex(opcode), toHex(pc)])
    pc += 2
    case op_1
    of 0x0:
      case op_3
      of 0xE:
        case op_4
        of 0x0: discard # cls
        of 0xE: # ret
          pc = stack[sp]
          sp -= 1
        else: invalidOperation(opcode)
      of 0x0: discard # sys addr
      else: invalidOperation(opcode)
    of 0x1: # jp addr
      pc = nnn
    of 0x2: # call addr
      sp += 1
      stack[sp] = pc
      pc = nnn
    of 0x3: # se vx, byte
      if v[x] == nn:
        pc += 2
    of 0x4: # sne vx, byte
      if v[x] != nn:
        pc += 2
    of 0x5: # se vx, vy
      if v[x] == v[y]:
        pc += 2
    of 0x6: # ld vx, byte
      v[x] = nn
    of 0x7: # add vx, byte
      v[x] += nn
    of 0x8:
      case op_4
      of 0x0: # ld vx, vy
        v[x] = v[y]
      of 0x1: # or vx, vy
        v[x] = v[x] or v[y]
      of 0x2: # and vx, vy
        v[x] = v[x] and v[y]
      of 0x3: # xor vx, vy
        v[x] = v[x] xor v[y]
      of 0x4: # add vx, vy
        v[x] += v[y]
        v[0xF] = ord(v[x] < v[y]).uint8
      of 0x5: # sub vx, vy
        v[0xF] = ord(v[y] > v[x]).uint8
        v[x] -= v[y]
      of 0x6: # shr vx, vy
        v[0xF] = v[x] and 0x1
        v[x] = v[x] shr 1
      of 0x7: # subn vx, vy
        v[0xF] = ord(v[x] <= v[y]).uint8
        v[x] = v[y] - v[x]
      of 0xE: # shl vx, vy
        v[0xF] = (v[x] and 0x80) shr 7
        v[x] = v[x] shl 1
      else: invalidOperation(opcode)
    of 0x9: # sne vx, vy
      if v[x] != v[y]:
        pc += 2
    of 0xA: # ld i, addr
      i = nnn
    of 0xB: # jp v0, addr
      pc = nnn + v[0]
    of 0xC: # rnd vx, byte
      v[x] = nn and rand(256).uint8
    of 0xD: discard # drw vx, vy, n
    of 0xE:
      case op_3
      of 0x9: discard # skp vx
      of 0xA: discard # sknp vx
      else: invalidOperation(opcode)
    of 0xF:
      case op_3
      of 0x0:
        case op_4
        of 0x7: # ld vx, dt
          v[x] = delay_timer
        of 0xA: discard # ld vx, k
        else: invalidOperation(opcode)
      of 0x1:
        case op_4
        of 0x5: # ld dt, vx
          delay_timer = v[x]
        of 0x8: # ld st, vx
          sound_timer = v[x]
        of 0xE: # add i, vx
          i += v[x]
        else: invalidOperation(opcode)
      of 0x2: # ld f, vx
        i = v[x].uint16 * 5
      of 0x3: # ld b, vx
        memory[i] = uint8(v[x] div 100)
        memory[i + 1] = uint8((v[x] div 10) mod 10)
        memory[i + 2] = uint8((v[x] mod 100) mod 10)
      of 0x5: # ld (i), vx
        for idx in 0.uint8..x:
          memory[i + idx] = v[idx]
      of 0x6: # ld vx, (i)
        for idx in 0.uint8..x:
          v[idx] = memory[i + idx]
      else: invalidOperation(opcode)
    else: invalidOperation(opcode)

proc main() =
  if paramCount() != 1:
    echo("Run with ./chip8 /path/to/rom")
    quit 1
  else:
    emulate()

when isMainModule:
  main()
