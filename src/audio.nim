import
  sdl2/audio

const
  bufferSize = 2000
  sampleRate = 40000

var
  audioBufferFull: array[bufferSize, float32]
  audioBufferEmpty: array[bufferSize, float32]
  obtainedSpec: AudioSpec
  audioSpec: AudioSpec

for i in 0..<bufferSize:
  audioBufferFull[i] = if (i mod 50) < 25: 1'f else: -1'f

proc audioCallback*(userdata: pointer; stream: ptr uint8; len: cint) {.cdecl.} =
  if cast[ptr uint8](userdata)[] > 0:
    copyMem(stream, addr audioBufferFull, len)
  else:
    copyMem(stream, addr audioBufferEmpty, len)

proc initAudio*(soundTimer: ptr uint8) =
  audioSpec.freq = sampleRate.cint
  audioSpec.format = AUDIO_F32
  audioSpec.channels = 1 
  audioSpec.samples = bufferSize
  audioSpec.callback = audioCallback
  audioSpec.userdata = soundTimer
  audioSpec.padding = 0

  discard openAudio(addr audioSpec, addr obtainedSpec)
  pauseAudio(0)

