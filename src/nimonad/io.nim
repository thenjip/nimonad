##[
  The `IO` monad from Haskell.

  It lets one build a computation that has no parameters.
  It can also be used as a wrapper for computations that interact with external
  resources such as memory management, FFI, I/O, etc. .
]##



import reader

import pkg/funcynim/[chain, into, run, unit]
when not defined(nimscript):
  import pkg/funcynim/[ignore]

import std/[sugar]



type
  Io* [T] = () -> T



func toIo* [T](value: T): Io[T] =
  () => value



proc run* [T](self: Io[T]): T =
  self()



func map* [A; B](self: Io[A]; f: A -> B): Io[B] =
  () => self.run().into(f)


func flatten* [T](self: Io[Io[T]]): Io[T] =
  self.map(run)


func flatMap* [A; B](self: Io[A]; f: A -> Io[B]): Io[B] =
  self.map(f).flatten()



func bracket* [A; B](before: Io[A]; between: A -> B; after: A -> Unit): Io[B] =
  ##[
    If an exception is raised anywhere in `before` or `between`, `after` will
    not be executed.
  ]##
  before.map(between.flatMap((b: B) => after.chain(_ => b)))



when not defined(nimscript):
  func tryBracket* [A; B](
    before: Io[A];
    `try`: A -> B;
    `finally`: A -> Unit
  ): Io[B] =
    ##[
      Any exception raised in `try` will be reraised by the returned `Io`.

      `finally` will be executed once, regardless of exception raising.
    ]##
    before.map(
      proc (a: A): B =
        try:
          `try`.run(a)
        except Exception as e:
          raise e
        finally:
          `finally`.run(a).ignore()
    )
