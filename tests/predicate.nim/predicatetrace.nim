import pkg/nimonad/[predicate]

import pkg/funcynim/[chain, partialproc]

import std/[sugar]



type
  Path* {.pure.} = enum
    Then
    Else

  Trace* [T] = tuple
    path: Path
    output: T



func trace* [T](path: Path; output: T): Trace[T] =
  (path, output)



proc tracedIfElse* [A; B](
  self: Predicate[A];
  then: A -> B;
  `else`: A -> B
): A -> Trace[B] =
  self.ifElse(
    then.chain(partial(trace(Path.Then, ?:B))),
    `else`.chain(partial(trace(Path.Else, ?:B)))
  )
