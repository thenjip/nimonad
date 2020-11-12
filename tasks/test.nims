import common/"dirs.nims" as taskdirs
import common/["project.nims"]
import test/["env.nims", taskconfig]

import pkg/funcynim/[ifelse]
import pkg/taskutils/[
  cmdline,
  dirs,
  envtypes,
  filetypes,
  nimcmdline,
  optional,
  parseenv,
  result
]

import std/[os, sequtils, strformat, sugar]



func defaultBackend (): Backend =
  Backend.C


func binGenDirName (): string =
  "bin"



func tryParseEnvConfig (): TaskConfig =
  taskConfig(tryParseNimBackend.failOr(defaultBackend))



func srcGenDir (backend: Backend): AbsoluteDir =
  func addPlatformDirIfNotJs (dir: DirPath): DirPath =
    backend
      .`==`(Backend.Js)
      .ifElse(() => dir, () => dir.crossCompilerCache())

  Task.Test
    .outputDir()
    .map(outputDir => outputDir / backend.envVarValue())
    .map(addPlatformDirIfNotJs)
    .get()


func binGenDir (backend: Backend): AbsoluteDir =
  let srcGenDir = backend.srcGenDir()

  backend
    .`==`(Backend.Js)
    .ifElse(() => srcGenDir, () => srcGenDir / binGenDirName())



func jsFlags (backend: Backend): seq[string] =
  backend.`==`(Backend.Js).ifElse(() => @["-d:nodejs"], () => @[])



func compileAndRunCmdOptions (
  module: AbsoluteFile;
  config: TaskConfig
): seq[string] =
  let backend = config.backend

  @["run".nimLongOption()]
    .concat(
      backend.jsFlags(),
      {
        "nimcache": backend.srcGenDir(),
        "outdir": backend.binGenDir()
      }.toNimLongOptions()
    )


func compileAndRunCmd (module: AbsoluteFile; config: TaskConfig): string =
  @[config.backend.nimCmdName()]
    .concat(module.compileAndRunCmdOptions(config), @[module.quoteShell()])
    .cmdLine()



when isMainModule:
  proc main () =
    let config = tryParseEnvConfig()

    for module in libNimModules():
      module.compileAndRunCmd(config).selfExec()



  main()
