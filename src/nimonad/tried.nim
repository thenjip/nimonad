##[
  This module implements the `Tried` monad also called `Result` or `Try` in
  Scala.

  It is a value that represents either a success or a failure.

  Failure values are usually exceptions, but they can be of any type.

  Since ``0.2.0``.
]##



import identity, predicate

import pkg/funcynim/[chain, curry, fold, partialproc, run, unit]

import std/[strutils, strformat, sugar]



type
  Tried* [S; F] = object
    ## Since ``0.2.0``.
    case successful: bool
      of true:
        success: S
      of false:
        failure: F

  UnboxError* = object of CatchableError
    ## Since ``0.2.0``.



template successType* [S; F](X: typedesc[Tried[S, F]]): typedesc[S] =
  ## Since ``0.2.0``.
  S


template failureType* [S; F](X: typedesc[Tried[S, F]]): typedesc[F] =
  ## Since ``0.2.0``.
  F


template successType* [S; F](self: Tried[S, F]): typedesc[S] =
  ## Since ``0.2.0``.
  self.typeof().successType()


template failureType* [S; F](self: Tried[S, F]): typedesc[F] =
  ## Since ``0.2.0``.
  self.typeof().failureType()



proc success* [S](value: S; F: typedesc): Tried[S, F] =
  ## Since ``0.2.0``.
  Tried[S, F](successful: true, success: value)


proc success* [S; F](value: S): Tried[S, F] =
  ## Since ``0.2.0``.
  success(value, F)



proc failure* [F](value: F; S: typedesc): Tried[S, F] =
  ## Since ``0.2.0``.
  Tried[S, F](successful: false, failure: value)


proc failure* [S; F](value: F): Tried[S, F] =
  ## Since ``0.2.0``.
  failure(value, S)



func isSuccess* [S; F](self: Tried[S, F]): bool =
  ## Since ``0.2.0``.
  self.successful


func isFailure* [S; F](self: Tried[S, F]): bool =
  ## Since ``0.2.0``.
  not self.isSuccess()



proc fold* [S; F; T](
  self: Tried[S, F];
  onSuccess: S -> T;
  onFailure: F -> T
): T =
  ## Since ``0.2.0``.
  self
    .isSuccess()
    .fold(_ => onSuccess(self.success), _ => onFailure(self.failure))



proc swap* [S; F](self: Tried[S, F]): Tried[F, S] =
  ## Since ``0.2.0``.
  self.fold(failure[F, S], success[F, S])



proc `==`* [S; F](left, right: Tried[S, F]): bool =
  ## Since ``0.2.0``.
  left
    .fold(
      leftSuccess => right.fold(partial(?_ == leftSuccess), alwaysFalse[F]),
      leftFailure => right.fold(alwaysFalse[S], partial(?_ == leftFailure))
    )


proc `$`* [S; F](self: Tried[S, F]): string =
  ## Since ``0.2.0``.
  proc buildMsg [T](prefix: string; value: T): string {.curry.} =
    fmt"{prefix}[{$T}]({$value})"

  self.fold(buildMsg("success"), buildMsg("failure"))



proc map* [A; B; F](self: Tried[A, F]; f: A -> B): Tried[B, F] =
  ##[
    Maps `f` on `self` when it is a success.

    Otherwise, does nothing.

    Since ``0.2.0``.
  ]##
  self.fold(f.chain(success[B, F]), failure[B, F])


proc join* [S; F](self: Tried[Tried[S, F], F]): Tried[S, F] =
  ##[
    Returns the inner success value when `self` is a success.

    Otherwise, returns the outer failure value.

    Since ``0.2.0``.
  ]##
  self.fold(itself, failure[S, F])


proc flatMap* [A; B; F](self: Tried[A, F]; f: A -> Tried[B, F]): Tried[B, F] =
  ## Since ``0.2.0``.
  self.map(f).join()



proc mapFailure* [S; FA; FB](self: Tried[S, FA]; f: FA -> FB): Tried[S, FB] =
  ##[
    Maps `f` on `self` when it is a failure.

    Otherwise, does nothing.

    Since ``0.2.0``.
  ]##
  self.swap().map(f).swap()




template `raise` (E: typedesc[Exception]; msg: string): untyped =
  raise E.newException(msg)


proc unboxSuccess* [S; F](self: Tried[S, F]): S {.
  raises: [Exception, UnboxError]
.} =
  ##[
    Tries to unbox the success value inside `self`.

    Otherwise, raises an `UnboxError`.

    Since ``0.2.0``.
  ]##
  func buildErrorMsg (_: Unit): string =
    [
      fmt"""Expected a success of type "{$S}",""",
      fmt"""but got a failure of type "{$F}"."""
    ].join($' ')

  self.fold(itself, proc (_: F): S = UnboxError.`raise`(buildErrorMsg.run()))


proc unboxSuccessOrRaise* [S; E: CatchableError](
  self: Tried[S, Unit -> ref E]
): S {.raises: [Exception, E].} =
  ##[
    Tries to unbox the success value inside `self`.

    Otherwise, raises the failure value.

    Since ``0.2.0``.
  ]##
  self.fold(itself, proc (error: Unit -> ref E): S = raise error.run())


proc unboxSuccessOrRaise* [S; E: CatchableError](self: Tried[S, ref E]): S {.
  raises: [Exception, E]
.} =
  ##[
    Tries to unbox the success value inside `self`.

    Otherwise, raises the failure value.

    Since ``0.2.0``.
  ]##
  self.mapFailure(error => ((_: Unit) => error)).unboxSuccessOrRaise()


proc unboxFailure* [S; F](self: Tried[S, F]): F {.
  raises: [Exception, UnboxError]
.} =
  ##[
    Tries to unbox the failure value inside `self`.

    Otherwise, raises an `UnboxError`.

    Since ``0.2.0``.
  ]##

  self.swap().unboxSuccess()
