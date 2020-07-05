import
  os, sdl2,
  audio, cpu, display, keyboard, types

const
  scale = 10
  maxRomSize = 4096 - 0x200

proc readRom(path: string): array[maxRomSize, uint8] =
  var file = open(path)
  discard readBytes(file, result, 0, maxRomSize)
  close(file)

proc emulate() =
  discard sdl2.init(INIT_VIDEO + INIT_AUDIO)
  let
    romPath = paramStr(1)
    rom = readRom(romPath)
    display = newDisplay(scale)
  var
    cpu = newCPU(rom)
    keyboard = newKeyboard()
  initAudio(addr cpu.soundTimer)
  display.clear()
  display.draw()
  while true:
    var evt = sdl2.defaultEvent
    while pollEvent(evt):
      case evt.kind
      of QuitEvent: quit(0)
      of KEY_DOWN, KEY_UP: keyboard.keyState(evt.key().keysym.sym, evt.kind)
      else: discard
    cpu.incrementTimers()
    cpu.executeInstruction(display, keyboard)
    sleep(2) # sleep 2 milliseconds and call it a day, whatever

proc main() =
  if paramCount() != 1:
    echo("Run with ./chip8 /path/to/rom")
    quit(1)
  else:
    emulate()

when isMainModule:
  main()

