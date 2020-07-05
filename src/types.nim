import
  sdl2

type
  RGB* = tuple
    red: byte
    green: byte
    blue: byte

  CPU* = ref object
    memory*: array[4096, uint8]
    v*: array[16, uint8]
    i*: uint16
    pc*: uint16
    stack*: array[16, uint16]
    sp*: uint8
    delayTimer*: uint8
    delayTimerCounter*: uint8
    soundTimer*: uint8
    soundTimerCounter*: uint8

  Display* = ref object
    window*: WindowPtr
    renderer*: RendererPtr
    texture*: TexturePtr
    buffer*: array[64 * 32, RGB]

  Keyboard* = ref object
    keys*: array[16, bool]

