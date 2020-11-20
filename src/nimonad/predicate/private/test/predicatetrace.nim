import ../../../predicate, ../../../reader

import pkg/funcynim/[chain ,partialproc]

import std/[sugar]



type
  PredicatePath* {.pure.} = enum
    Then
    Else

  PredicateTrace* [T] = tuple
    path: PredicatePath
    output: T



func predicateTrace* [T](path: PredicatePath; output: T): PredicateTrace[T] =
  (path, output)



proc tracedIfElse* [A; B](
  self: Predicate[A];
  then: A -> B;
  `else`: A -> B
): Reader[A, PredicateTrace[B]] =
  self.ifElse(
    then.chain(partial(predicateTrace(PredicatePath.Then, ?:B))),
    `else`.chain(partial(predicateTrace(PredicatePath.Else, ?:B)))
  )
