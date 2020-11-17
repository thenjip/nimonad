#[
  This can compiled to C or C++ and checked for file descriptor leaks with
  ``valgrind --track-fds=yes``. No leaks should be found.
]#



import nimonad/[io]

import pkg/funcynim/[unit]

import std/[sugar]



proc withFile* [T](file: () -> File; compute: File -> T): Io[T] =
  file.tryBracket(compute, proc (f: File): Unit = f.close())


proc openCurrentSrcFile* (): File =
  currentSourcePath().open()



when isMainModule:
  proc main () =
    let fileSize = openCurrentSrcFile.withFile(getFileSize).run()

    echo(fileSize) # This should print a positive number.



  main()
