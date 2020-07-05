import
  sdl2,
  types

const
  width = 64
  height = 32
  color_off = (0x00'u8, 0x00'u8, 0x00'u8)
  color_on = (0xFF'u8, 0xFF'u8, 0xFF'u8)

proc newDisplay*(scale: SomeInteger): Display =
  new result
  result.window = createWindow("Chip-8 - Nim", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, cint(width * scale), cint(height * scale), 0)
  result.renderer = createRenderer(result.window, -1, 0)
  result.texture = createTexture(result.renderer, SDL_PIXELFORMAT_RGB24, SDL_TEXTUREACCESS_STREAMING, width, height)
  discard result.renderer.setLogicalSize(width, height)

proc draw*(display: Display) =
  display.texture.updateTexture(nil, addr display.buffer, width * sizeof(RGB))
  display.renderer.clear
  display.renderer.copy display.texture, nil, nil
  display.renderer.present

proc clear*(display: Display) =
  for i in 0..<(width * height):
    display.buffer[i] = color_off

proc getPos*(display: Display, x: SomeInteger, y: SomeInteger): bool =
  return display.buffer[(int(y) mod height) * width + (int(x) mod width)] == color_on

proc setPos*(display: Display, x: SomeInteger, y: SomeInteger, on: bool) =
  display.buffer[(int(y) mod height) * width + (int(x) mod width)] = if on: color_on else: color_off

