import pkg/nimonad/[io, laws]



export laws



type
  IoMonadLawsSpec* [LA; LB; RT; AA; AB; AC] =
    MonadLawsSpec[
      LA, Io[LA], Io[LB],
      RT, Io[RT],
      AA, AB, Io[AA], Io[AB], Io[AC]
    ]



proc checkLaws* [LA; LB; RT; AA; AB; AC](
  self: IoMonadLawsSpec[LA, LB, RT, AA, AB, AC]
): MonadLawsVerdict[LB, RT, AC] =
  self.checkLaws(flatMap[int, int]).map(run, run[RT], run[AC])
