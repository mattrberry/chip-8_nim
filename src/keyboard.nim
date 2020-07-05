import
  sdl2, tables,
  types

const
  keymap = to_table({
    K_1: 0x1, K_2: 0x2, K_3: 0x3, K_4: 0xC,
    K_Q: 0x4, K_W: 0x5, K_E: 0x6, K_R: 0xD,
    K_A: 0x7, K_S: 0x8, K_D: 0x9, K_F: 0xE,
    K_Z: 0xA, K_X: 0x0, K_C: 0xB, K_V: 0xF 
  })

proc newKeyboard*(): Keyboard =
  new result

proc keyState*(keyboard: Keyboard, key: cint, eventType: EventType) =
  if keymap.has_key(key):
    keyboard.keys[keymap[key]] = eventType == KEY_DOWN

