import pkg/nimonad/[laws, tried]

import pkg/funcynim/[unit]

import std/[sugar]



export laws



type
  TriedMonadLawsSpec* [LA; LB; RT; AA; AB; AC] =
    MonadLawsSpec[
      LA, Tried[LA, Unit], Tried[LB, Unit],
      RT, Tried[RT, Unit],
      AA, AB, Tried[AA, Unit], Tried[AB, Unit], Tried[AC, Unit]
    ]



proc checkLaws* [LA; LB; RT; AA; AB; AC](
  self: TriedMonadLawsSpec[LA, LB, RT, AA, AB, AC]
): MonadLawsVerdict[Tried[LB, Unit], Tried[RT, Unit], Tried[AC, Unit]] =
  proc flatMap [A; B](
    self: Tried[A, Unit];
    f: A -> Tried[B, Unit]
  ): Tried[B, Unit] =
    tried.flatMap(self, f)

  self.checkLaws(flatMap[int, int])
