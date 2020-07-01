import
  os, random, sdl2, strformat, strutils, system, tables

type
  RGB = tuple
    red: byte
    green: byte
    blue: byte

proc color(r, g, b: SomeInteger): RGB =
  return (r.uint8, g.uint8, b.uint8)

proc color(shade: SomeInteger): RGB =
  return color(shade, shade, shade)

const
  width = 64
  height = 32
  scale = 10
  white: RGB = color(0xFF)
  black: RGB = color(0x00)
  fontset: array[5 * 16, SomeInteger] = [
    0xF0, 0x90, 0x90, 0x90, 0xF0, # 0
    0x20, 0x60, 0x20, 0x20, 0x70, # 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, # 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, # 3
    0x90, 0x90, 0xF0, 0x10, 0x10, # 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, # 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, # 6
    0xF0, 0x10, 0x20, 0x40, 0x40, # 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, # 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, # 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, # A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, # B
    0xF0, 0x80, 0x80, 0x80, 0xF0, # C
    0xE0, 0x90, 0x90, 0x90, 0xE0, # D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, # E
    0xF0, 0x80, 0xF0, 0x80, 0x80, # F
  ]
  keymap = to_table({
    K_1: 0x1, K_2: 0x2, K_3: 0x3, K_4: 0xC,
    K_Q: 0x4, K_W: 0x5, K_E: 0x6, K_R: 0xD,
    K_A: 0x7, K_S: 0x8, K_D: 0x9, K_F: 0xE,
    K_Z: 0xA, K_X: 0x0, K_C: 0xB, K_V: 0xF
  })

var
  keys: array[16, bool]

discard sdl2.init(INIT_VIDEO + INIT_AUDIO)

let
  window = createWindow("Chip-8 - Nim", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width * scale, height * scale, 0)
  renderer = createRenderer(window, -1, 0)
  texture = createTexture(renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, width, height)
var buffer: array[width * height, RGB]

discard renderer.setLogicalSize(width, height)

proc draw() =
  texture.updateTexture(nil, addr buffer, width * sizeof(RGB))
  renderer.clear
  renderer.copy texture, nil, nil
  renderer.present

proc clearScreen() =
  var color: uint8
  for i in 0..<(width * height):
    buffer[i] = black

proc getPos(x: SomeInteger, y: SomeInteger): RGB =
  return buffer[(int(y) mod height) * width + (int(x) mod width)]

proc setPos(x: SomeInteger, y: SomeInteger, color: RGB) =
  buffer[(int(y) mod height) * width + (int(x) mod width)] = color

proc invalidOperation(opcode: uint16) =
  echo("Encountered an unhandled operation: 0x$1" % [toHex(opcode)])
  quit(1)

proc readRom(path: string, memory: var array[4096, uint8]) =
  var file = open(path)
  discard readBytes(file, memory, 0x200, 0xFFF - 0x200)
  close(file)

proc emulate() =
  var
    romPath = paramStr(1)
    memory: array[4096, uint8]
  readRom(romPath, memory)
  clearScreen()
  draw()
  for idx in 0..<fontset.len:
    memory[idx] = fontset[idx].uint8
  var
    v: array[16, uint8]      # general purpose registers
    i: uint16 = 0            # register typically used for addresses
    delay_timer: uint8 = 0   # todo
    sound_timer: uint8 = 0   # todo
    pc: uint16 = 0x200       # program counter starts at rom
    stack: array[16, uint16] # stores addresses to return to from subroutines
    sp: uint8 = 0            # current stack pointer
  while true:
    var evt = sdl2.defaultEvent
    while pollEvent(evt):
      case evt.kind
      of QuitEvent: quit(0)
      of KEY_DOWN:
        let key = evt.key().keysym.sym
        if keymap.has_key(key):
          keys[keymap[key]] = true
      of KEY_UP:
        let key = evt.key().keysym.sym
        if keymap.has_key(key):
          keys[keymap[key]] = false
      else: discard
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
    pc += 2
    case op_1
    of 0x0:
      case op_3
      of 0xE:
        case op_4
        of 0x0: # cls
          clearScreen()
          draw()
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
    of 0xD: # drw vx, vy, n
      v[0xF] = 0
      var
        row_byte: uint8
        was_enabled: bool
      for row in 0.uint8..<n:
        row_byte = memory[i + row]
        for col in 0.uint8..<8.uint8:
          if (row_byte and (0x80.uint8 shr col)) > 0:
            was_enabled = getPos(v[x] + col, v[y] + row) == white
            v[0xF] = v[0xF] or uint8(was_enabled)
            setPos(v[x] + col, v[y] + row, if was_enabled: black else: white)
      draw()
    of 0xE:
      case op_3
      of 0x9: # skp vx
        if keys[v[x]]:
          pc += 2
      of 0xA: # sknp vx
        if not keys[v[x]]:
          pc += 2
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
    quit(1)
  else:
    emulate()

when isMainModule:
  main()
