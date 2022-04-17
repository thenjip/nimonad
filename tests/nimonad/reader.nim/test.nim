when isMainModule:
  import laws

  import pkg/nimonad/[identity, reader]

  import pkg/funcynim/[operators, partialproc, unit]

  import std/[sequtils, strutils, sugar, unittest]



  proc main () =
    suite "nimonad/reader":
      test """"Reader[S, T]" should obey the monad laws.""":
        proc doTest [LA; LB; LS; RT; RS; AA; AB; AC; AS](
          spec: ReaderMonadLawsSpec[LA, LB, LS, RT, RS, AA, AB, AC, AS];
          runArgs: RunArgs[LS, RS, AS]
        ) =
          let (leftId, rightId, assoc) = spec.checkLaws(runArgs)

          check:
            leftId.actual == leftId.expected
            rightId.actual == rightId.expected
            assoc.actual == assoc.expected


        doTest(
          monadLawsSpec(
            leftIdentitySpec(
              @["a", "abc", "012"],
              partial(toReader(?_, Unit)),
              s => s.foldl(a + b.len().uint, 0u).toReader(Unit)
            ),
            rightIdentitySpec(
              Reader[cfloat, auto]((_: cfloat) => {0i16 .. 9i16}),
              toReader
            ),
            associativitySpec(
              (@[0, 7], 'a').toReader(string),
              (t: (seq[int], char)) =>
                t[0].foldl(a + b, 0).plus(t[1].ord()).toReader(string)
              ,
              (i: int) => i.modulo(2).toReader(string)
            )
          ),
          (unit(), 5.2, "abc")
        )



      test [
        "Side effect free expressions involving Reader[S, T] should be compile",
        "time compatible."
      ].join($' '):
        when defined(js):
          skip() # https://github.com/nim-lang/Nim/issues/12492
        else:
          proc doTest () =
            const results = (
              0.toReader(string).map(partial($ ?_)).run("abc"),
              partial($ ?:float)
                .flatMap((s: string) => itself[float].map(partial($ ?_)))
                .run(1.2)
            )

            discard results


          doTest()



      test [
        """"S.ask()" should give access to the read state inside "flatMap"."""
      ].join($' '):
        proc doTest [S; T](self: Reader[S, T]; expected: S) =
          let actual = self.flatMap((_: T) => S.ask()).run(expected)

          check:
            actual == expected


        doTest(partial(len(?:string)), "abc")



  main()
