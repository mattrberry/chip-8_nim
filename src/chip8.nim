import
  os, strutils, system

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
      op_1 = (opcode and 0xF000) shr 12
      op_2 = (opcode and 0x0F00) shr 8
      op_3 = (opcode and 0x00F0) shr 4
      op_4 = (opcode and 0x000F)
      x = op_2
      y = op_3
      n = op_4
      nn = opcode and 0x00FF
      nnn = opcode and 0x0FFF
    echo("Opcode:0x$1, PC:0x$2" % [toHex(opcode), toHex(pc)])
    pc += 2
    case op_1
    of 0x0:
      case op_3
      of 0xE:
        case op_4
        of 0x0: discard # cls
        of 0xE: discard # ret
        else: invalidOperation(opcode)
      of 0x0: discard # sys addr
      else: invalidOperation(opcode)
    of 0x1: pc = nnn # jp addr
    of 0x2: discard # call addr
    of 0x3: discard # se vx, byte
    of 0x4: discard # sne vx, byte
    of 0x5: discard # se vx, vy
    of 0x6: discard # ld vx, byte
    of 0x7: discard # add vx, byte
    of 0x8:
      case op_4
      of 0x0: discard # ld vx, vy
      of 0x1: discard # or vx, vy
      of 0x2: discard # and vx, vy
      of 0x3: discard # xor vx, vy
      of 0x4: discard # add vx, vy
      of 0x5: discard # sub vy, vy
      of 0x6: discard # shr vx, vy
      of 0x7: discard # subn vx, vy
      of 0xE: discard # shl vx, vy
      else: invalidOperation(opcode)
    of 0x9: discard # sne vx, vy
    of 0xA: discard # ld i, addr
    of 0xB: discard # jp v0, addr
    of 0xC: discard # rnd vx, byte
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
        of 0x7: discard # ld vx, dt
        of 0xA: discard # ld vx, k
        else: invalidOperation(opcode)
      of 0x1:
        case op_4
        of 0x5: discard # ld dt, vx
        of 0x8: discard # ld st, vx
        of 0xE: discard # add i, vx
        else: invalidOperation(opcode)
      of 0x2: discard # ld f, vx
      of 0x3: discard # ld b, vx
      of 0x5: discard # ld (i), vx
      of 0x6: discard # ld vx, (i)
      else: invalidOperation(opcode)
    else:
      echo("no match")
      invalidOperation(opcode)

proc main() =
  if paramCount() != 1:
    echo("Run with ./chip8 /path/to/rom")
    quit 1
  else:
    emulate()

when isMainModule:
  main()
