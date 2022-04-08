when isMainModule:
  import laws

  import pkg/nimonad/[identity]

  import pkg/funcynim/[partialproc]

  import std/[unittest]



  proc main() =
    suite "identity":
      test """The identity monad should verify the monad laws.""":
        proc doTest [LA; LB; RT; AA; AB; AC](
          spec: IdentityMonadLawsSpec[LA, LB, RT, AA, AB, AC]
        ) =
          let (leftId, rightId, assoc) = spec.checkLaws()

          check:
            leftId.actual == leftId.expected
            rightId.actual == rightId.expected
            assoc.actual == assoc.expected


        doTest(
          monadLawsSpec(
            leftIdentitySpec(0, itself, partial($ ?_)),
            rightIdentitySpec("abc", itself),
            associativitySpec('c', partial($ ?:char), partial(len(?:string)))
          )
        )



  main()
