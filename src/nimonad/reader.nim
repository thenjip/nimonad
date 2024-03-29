##[
  The `Reader` monad.

  A `Reader[S, T]` is a function that reads some environment (or state) `S`
  and returns some value `T`.
]##



import identity

import pkg/funcynim/[chain, run, unit]

import std/[sugar]



type Reader* [S, T] = S -> T



func ask* (S: typedesc): Reader[S, S] =
  ##[
    Can be used to retrieve the read state within a
    [flatMap](#flatMap%2CReader%5BS%2CA%5D%2C) call.
  ]##
  itself[S]


func ask* [S](_: Unit): Reader[S, S] =
  S.ask()


func ask* [S](): Reader[S, S] {.deprecated: "Since 0.2.0.".} =
  ask[S](unit())



func toReader* [T](value: T; S: typedesc): Reader[S, T] =
  (_: S) => value


func toReader* [S; T](value: T): Reader[S, T] =
  value.toReader(S)



proc run* [S; T](self: Reader[S, T]; state: S): T =
  self(state)



func map* [S; A; B](self: Reader[S, A]; f: A -> B): Reader[S, B] =
  self.chain(f)


func join* [S; T](self: Reader[S, Reader[S, T]]): Reader[S, T] =
  ## Since `0.2.0`.
  (state: S) => self.run(state).run(state)


func flatMap* [S; A; B](
  self: Reader[S, A];
  f: A -> Reader[S, B]
): Reader[S, B] =
  self.map(f).join()



func local* [S; T](self: Reader[S, T]; f: S -> S): Reader[S, T] =
  ##[
    Returns a `Reader` that will execute `self` in an environment modified by
    `f`.
  ]##
  f.map(self)
