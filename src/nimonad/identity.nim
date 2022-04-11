##[
  The identity monad.

  It does not do much in itself, but at least it defines the identity function.
]##



import pkg/funcynim/[into, itself]

import std/[sugar]



func itself* [T](value: T): T =
  itself.itself(value)



proc into* [A; B](self: A; f: A -> B): B =
  into.into(self, f)


proc apply* [A; B](self: A; f: A -> B): B {.
  deprecated: """Since "0.2.0". Use "into" instead."""
.} =
  identity.into(self, f)
