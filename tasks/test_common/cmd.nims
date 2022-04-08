import "dirs.nims"
import ../common/[filetypes, nimcmdline, "project.nims"]

import std/[options, os, sequtils]



func compileRunCmdOptions*(module: RelativeFile; task: TestTask): seq[string] =
  let valuedOptions =
    {
      "nimcache": task.srcGenDir(module),
      "outdir": task.binGenDir(module)
    }.map(toLongOption)

  "run".toLongOption() & valuedOptions


func compileRunCmd*(module: RelativeFile; task: TestTask): string =
  task
    .nimCmdName()
    .`&`(module.compileRunCmdOptions(task))
    .`&`(module.quoteShell())
    .toCmdLine()


proc compileRun*(module: RelativeFile; task: TestTask) =
  module.compileRunCmd(task).selfExec()


proc compileRunAllTests*(task: TestTask) =
  for test in tests():
    test.compileRun(task)
