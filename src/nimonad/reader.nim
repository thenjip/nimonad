##[
  The `Reader` monad.

  A `Reader[S, T]` is a function that reads some environment (or state) `S`
  and returns some value `T`.
]##



import identity

import pkg/funcynim/[chain]

import std/[sugar]



type Reader* [S, T] = S -> T



func ask* (S: typedesc): Reader[S, S] =
  ##[
    Can be used to retrieve the read state within a
    [flatMap](#flatMap%2CReader%5BS%2CA%5D%2C) call.
  ]##
  itself[S]


func ask* [S](): Reader[S, S] =
  S.ask()



func toReader* [T](value: T; S: typedesc): Reader[S, T] =
  (_: S) => value


func toReader* [S; T](value: T): Reader[S, T] =
  value.toReader(S)



proc run* [S; T](self: Reader[S, T]; state: S): T =
  self(state)



func map* [S; A; B](self: Reader[S, A]; f: A -> B): Reader[S, B] =
  self.chain(f)


func flatMap* [S; A; B](
  self: Reader[S, A];
  f: A -> Reader[S, B]
): Reader[S, B] =
  (state: S) => self.run(state).into(f).run(state)



func local* [S; T](self: Reader[S, T]; f: S -> S): Reader[S, T] =
  ##[
    Returns a `Reader` that will execute `self` in an environment modified by
    `f`.
  ]##
  f.map(self)
