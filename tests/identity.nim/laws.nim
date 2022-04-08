import pkg/nimonad/[identity, laws]



export laws



type
  IdentityMonadLawsSpec* [LA; LB; RT; AA; AB; AC] =
    MonadLawsSpec[LA, LA, LB, RT, RT, AA, AB, AA, AB, AC]



proc checkLaws* [LA; LB; RT; AA; AB; AC](
  self: IdentityMonadLawsSpec[LA, LB, RT, AA, AB, AC]
): MonadLawsVerdict[LB, RT, AC] =
  self.checkLaws(apply[int, int])
