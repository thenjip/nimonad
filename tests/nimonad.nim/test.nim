when isMainModule:
  import pkg/[nimonad]

  import std/[unittest]



  proc main() =
    suite "nimonad":
      test "The module should compile.":
        discard



  main()
