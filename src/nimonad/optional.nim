##[
  The `Optional[T]` monad.

  It is a box containing either a value or nothing.

  This is another implementation of the `Option`/`Maybe` monad, but using only
  pure functional programming techniques to make it compatible with compile time
  execution.
]##



import identity, predicate, reader

import pkg/funcynim/[chain, fold, partialproc, run, unit]

import std/[strformat, sugar]



type
  Nilable* = concept var x
    x = nil

  UnboxError* = object of CatchableError

  Optional* [T] = object
    when T is Nilable:
      value: T
    else:
      case empty: bool
        of true:
          discard
        else:
          value: T



template boxedType* [T](X: typedesc[Optional[T]]): typedesc[T] =
  T


template boxedType* [T](self: Optional[T]): typedesc[T] =
  self.typeof().boxedType()



func none* (T: typedesc[Nilable]): Optional[T] =
  Optional[T](value: nil)


func none* (T: typedesc[not Nilable]): Optional[T] =
  Optional[T](empty: true)


func none* [T](_: Unit): Optional[T] =
  ## Since `0.2.0`.
  T.none()


func none* [T](): Optional[T] {.deprecated: """Since "0.2.0".""".} =
  none(unit())



func optionalNilable [T: Nilable](value: T): Optional[T] =
  Optional[T](value: value)



proc some* [T: Nilable](value: T): Optional[T] =
  assert(value != nil)

  value.optionalNilable()


func some* [T: not Nilable](value: T): Optional[T] =
  Optional[T](empty: false, value: value)



proc optional* [T: Nilable](value: T): Optional[T] =
  ##[
    If `value` is not `nil`, returns `value.some()`, otherwise an empty
    `Optional`.
  ]##
  value.optionalNilable()



func isNone* [T: Nilable](self: Optional[T]): bool =
  self.value == nil


func isNone* [T: not Nilable](self: Optional[T]): bool =
  self.empty



func isSome* [T](self: Optional[T]): bool =
  not self.isNone()



proc fold* [A; B](self: Optional[A]; then: A -> B; `else`: Unit -> B): B =
  ## Since `0.2.0`.
  self.isSome().fold((_: Unit) => then.run(self.value), `else`)


proc ifNone* [A; B](self: Optional[A]; then: () -> B; `else`: A -> B): B {.
  deprecated: """Since "0.2.0". Use "fold" instead."""
.} =
  self.fold(`else`, (_: Unit) => then.run())


proc ifSome* [A; B](self: Optional[A]; then: A -> B; `else`: () -> B): B {.
  deprecated: """Since "0.2.0". Use "fold" instead."""
.} =
  self.fold(then, (_: Unit) => `else`.run())



proc flatMap* [A; B](self: Optional[A]; f: A -> Optional[B]): Optional[B] =
  ##[
    Applies `f` to the value inside `self` or does nothing if `self` is empty.
  ]##
  self.fold(f, none)


proc map* [A; B](self: Optional[A]; f: A -> B): Optional[B] =
  ##[
    Applies `f` to the value inside `self` or does nothing if `self` is empty.
  ]##
  self.flatMap(f.chain(some))


func flatten* [T](self: Optional[Optional[T]]): Optional[T] =
  self.flatMap(itself)



proc unboxOr* [T](self: Optional[T]; `else`: () -> T): T =
  self.ifSome(itself, `else`)



func raiseUnboxError [T](): T {.noinit, raises: [UnboxError].} =
  raise UnboxError.newException("")


func unbox* [T](self: Optional[T]): T {.raises: [Exception, UnboxError].} =
  ##[
    Retrieves the value inside `self` or raise an `UnboxError` if `self` is
    empty.
  ]##
  self.unboxOr(raiseUnboxError)



proc filter* [T](self: Optional[T]; predicate: Predicate[T]): Optional[T] =
  self.flatMap(predicate.fold(some, _ => T.none()))


func `==`* [T](self, other: Optional[T]): bool =
  self.fold(
    selfValue => other.fold(partial(?_ == selfValue), alwaysFalse[Unit]),
    (_: Unit) => other.isNone()
  )


proc `$`* [T](self: Optional[T]): string =
  self.fold(value => fmt"some({value})", (_: Unit) => fmt"none({T})")
