##[
  The identity monad.

  It does not do much in itself, but at least it defines the identity function.
]##



import std/[sugar]



func itself* [T](value: T): T =
  value


proc apply* [A; B](self: A; f: A -> B): B =
  self.f()



when isMainModule:
  import std/[os, unittest]



  proc main () =
    suite currentSourcePath().splitFile().name:
      discard



  main()
