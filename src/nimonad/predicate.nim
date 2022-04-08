import reader

import pkg/funcynim/[fold, partialproc, run, unit]

import std/[sugar]



type
  Predicate* [T] = Reader[T, bool]



proc test* [T](self: Predicate[T]; value: T): bool =
  self.run(value)



func `not`* [T](self: Predicate[T]): Predicate[T] =
  self.map(partial(not ?_))


func `and`* [T](self, then: Predicate[T]): Predicate[T] =
  ##[
    The returned predicate will use the short circuiting `and`.
  ]##
  (value: T) => self.test(value) and then.test(value)


func `or`* [T](self, `else`: Predicate[T]): Predicate[T] =
  ##[
    The returned predicate will use the short circuiting `or`.
  ]##
  (value: T) => self.test(value) or `else`.test(value)



func ifElse* [A; B](self: Predicate[A]; then, `else`: A -> B): A -> B =
  (value: A) =>
    self
      .test(value)
      .fold((_: Unit) => then.run(value), (_: Unit) => `else`.run(value))



func alwaysFalse* [T](_: T): bool =
  false


func alwaysTrue* [T](_: T): bool =
  true
