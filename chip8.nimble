# Package

version       = "0.1.0"
author        = "Matthew Berry"
description   = "A chip-8 emulator in Nim"
license       = "MIT"
srcDir        = "src"
bin           = @["chip8"]



# Dependencies

requires "nim >= 1.2.0"
requires "sdl2 >= 2.0.3"