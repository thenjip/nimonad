import ../../../optional, ../../../laws



type
  OptionalMonadLawsSpec* [LA; LB; RT; AA; AB; AC] =
    MonadLawsSpec[
      LA, Optional[LA], Optional[LB],
      RT, Optional[RT],
      AA, AB, Optional[AA], Optional[AB], Optional[AC]
    ]



proc checkLaws* [LA; LB; RT; AA; AB; AC](
  self: OptionalMonadLawsSpec[LA, LB, RT, AA, AB, AC]
): MonadLawsVerdict[Optional[LB], Optional[RT], Optional[AC]] =
  self.checkLaws(flatMap[int, int])
