##[
  Utilities to check whether a type `M` verifies the monad laws.

  This module is meant to be used in test suites.

  Concepts cannot currently be used to implement the monad concept in Nim.
  See this related [issue](https://github.com/nim-lang/Nim/issues/5650).
]##



import laws/[flatmapper, specs, verdict]
import laws/flatmapper/[constructors]

import pkg/funcynim/[chain]

import std/[sugar]



export flatmapper, constructors, specs, verdict



proc checkLaw* [A; MA; MB](
  self: LeftIdentitySpec[A, MA, MB];
  flatMap: FlatMapper[MA, A, MB]
): Verdict[MB] =
  let (initial, lift, f) = self

  verdict(initial.lift().flatMap(f), initial.f())



proc checkLaw* [T; M](
  self: RightIdentitySpec[T, M];
  flatMap: FlatMapper[M, T, M]
): Verdict[M] =
  let (initial, lift) = self

  verdict(initial.flatMap(lift), initial)



proc checkLaw* [A; B; MA; MB; MC](
  self: AssociativitySpec[A, B, MA, MB, MC];
  flatMappers: AssociativityFlatMappers[A, B, MA, MB, MC]
): Verdict[MC] =
  let
    (initial, f, g) = self
    (flatMapFirst, flatMapSecond, flatMapOuter) = flatMappers

  verdict(
    initial.flatMapFirst(f).flatMapSecond(g),
    initial.flatMapOuter(f.chain(mb => mb.flatMapSecond(g)))
  )


template checkLaw* [A; B; MA; MB; MC; FMA; FA; FMB](
  self: AssociativitySpec[A, B, MA, MB, MC];
  flatMapper: FlatMapper[FMA, FA, FMB]{sym}
): Verdict[MC] =
  self.checkLaw(self.instantiateAssociativity(A, B, MA, MB, MC))



proc checkLaws* [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC](
  self: MonadLawsSpec[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC];
  flatMappers: MonadLawsFlatMappers[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC]
): MonadLawsVerdict[LMB, RM, AMC] =
  let (leftId, rightId, assoc) = self

  monadLawsVerdict(
    leftId.checkLaw(flatMappers.leftIdentity),
    rightId.checkLaw(flatMappers.rightIdentity),
    assoc.checkLaw(flatMappers.associativity)
  )


template checkLaws* [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC; FMA; FA; FMB](
  self: MonadLawsSpec[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC];
  flatMapper: FlatMapper[FMA, FA, FMB]{sym}
): MonadLawsVerdict[LMB, RM, AMC] =
  self.checkLaws(
    flatMapper.instantiateMonadLaws(LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC)
  )
