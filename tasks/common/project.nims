import "../../nimonad.nimble"

import pkg/taskutils/[fileiters, filetypes]

import std/[os]



export nimonad



func nimblePackageName* (): string =
  "nimonad"



func nim* (f: FilePath): FilePath =
  f.addFileExt(nimExt())



iterator libNimModules* (): AbsoluteFile =
  yield srcDirName() / nimblePackageName().nim()

  for module in srcDirName().`/`(nimblePackageName()).absoluteNimModules():
    yield module
