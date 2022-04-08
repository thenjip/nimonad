import pkg/nimonad/[reader, laws]

import pkg/funcynim/[partialproc]



export laws



type
  ReaderMonadLawsSpec* [LA; LB; LS; RT; RS; AA; AB; AC; AS] =
    MonadLawsSpec[
      LA, Reader[LS, LA], Reader[LS, LB],
      RT, Reader[RS, RT],
      AA, AB, Reader[AS, AA], Reader[AS, AB], Reader[AS, AC]
    ]

  RunArgs* [L; R; A] = tuple
    leftId: L
    rightId: R
    assoc: A



proc checkLaws* [LA; LB; LS; RT; RS; AA; AB; AC; AS](
  self: ReaderMonadLawsSpec[LA, LB, LS, RT, RS, AA, AB, AC, AS];
  runArgs: RunArgs[LS, RS, AS]
): MonadLawsVerdict[LB, RT, AC] =
  self
    .checkLaws(flatMap[int, int, int])
    .map(
      partial(run(?:Reader[LS, LB], runArgs.leftId)),
      partial(run(?:Reader[RS, RT], runArgs.rightId)),
      partial(run(?:Reader[AS, AC], runArgs.assoc))
    )
