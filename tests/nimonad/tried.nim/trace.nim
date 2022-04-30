import pkg/nimonad/[tried]

import pkg/funcynim/[chain, partialproc]

import std/[sugar]



type
  Path* {.pure.} = enum
    Success
    Failure

  TraceOutput* [T] = tuple
    path: Path
    value: T



func traceOutput* [T](path: Path; value: T): TraceOutput[T] =
  (path, value)



proc tracedFold* [S; F; T](
  self: Tried[S, F];
  onSuccess: S -> T;
  onFailure: F -> T
): TraceOutput[T] =
  self
    .fold(
      onSuccess.chain(partial(traceOutput(Path.Success, ?:T))),
      onFailure.chain(partial(traceOutput(Path.Failure, ?:T)))
    )
