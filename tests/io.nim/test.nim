when isMainModule:
  import brackettrace, laws

  import pkg/nimonad/[identity, io, optional]

  import pkg/funcynim/[partialproc, run, unit]

  import std/[sequtils, strutils, sugar, unittest]



  proc `$` [T](self: ref T): string =
    $cast[uint](self)



  proc main () =
    suite "io":
      test """"Io[T]" should obey the monad laws.""":
        proc doTest [LA; LB; RT; AA; AB; AC](
          spec: IoMonadLawsSpec[LA, LB, RT, AA, AB, AC]
        ) =
          let (leftId, rightId, assoc) = spec.checkLaws()

          check:
            leftId.actual == leftId.expected
            rightId.actual == rightId.expected
            assoc.actual == assoc.expected


        doTest(
          monadLawsSpec(
            leftIdentitySpec(-5, toIo, i => toIo(-i)),
            rightIdentitySpec(Io[auto](() => "abc"), toIo),
            associativitySpec(
              ('a', true).toIo(),
              (t: (char, bool)) => (t[0], not t[1]).toIo(),
              (t: (char, bool)) => t[0].`$`().len().toIo()
            )
          )
        )



      test [
        """Side effect free expressions involving "Io[T]" should be""",
        "compatible with compile time execution."
      ].join($' '):
        when defined(js):
          skip() # https://github.com/nim-lang/Nim/issues/12492
        else:
          proc doTest () =
            const results =
              (
                "abc".toIo().map(partial(len(?_))).run(),
                (() => 0)
                  .flatMap((i: int) => toIo(i + 6))
                  .map(partial($ ?_))
                  .run()
              )

            discard results


          doTest()



      test [
        """"bracket" should run "after" after "between" when no exception is""",
        "raised."
      ].join($' '):
        proc doTest [A; B](
          before: Io[A];
          between: proc (a: A): B {.raises: [].};
          after: A -> Unit;
          expectedOutput: B
        ) =
          let
            actual = bracket[A, B].trace(before, between, after).run()
            expected = trace(toSeq(Step.items()), expectedOutput)

          check:
            actual == expected


        proc runTest1 () =
          let
            start = 1
            between = (i: start.typeof()) => -i.float

          doTest(() => start, between, doNothing, between.run(start))


        runTest1()



      test [
        """"bracket" should not run "after" when an exception is raised in""",
        "\"between\"."
      ].join($' '):
        proc doTest [A; B; E: Exception](
          before: Io[A];
          between: proc (a: A): B {.raises: [].};
          exception: () -> ref E
        ) =
          let
            actual = bracket[A, B].traceSteps(before, between, exception).run()
            expected = @[Step.Before]

          check:
            actual == expected


        doTest(
          () => "abc",
          itself[string],
          () => FloatDivByZeroDefect.newException("")
        )



      test [
        """"tryBracket" should run the "before", "try" and "finally" procs""",
        "once and in this order when no exception is raised."
      ].join($' '):
        when defined(nimscript):
          skip()
        else:
          proc doTest [A; B](
            before: Io[A];
            `try`: proc (a: A): B {.raises: [].};
            `finally`: A -> Unit;
            expectedOutput: B
          ) =
            let
              actual = tryBracket[A, B].trace(before, `try`, `finally`).run()
              expected = trace(toSeq(Step.items()), expectedOutput)

            check:
              actual == expected


          proc runTest1 () =
            let
              start = "abc"
              tryBlock = partial(len(?:start.typeof()))

            doTest(() => start, tryBlock, _ => unit(), tryBlock.run(start))


          runTest1()



      test [
        """"tryBracket" should re-raise the exception when an exception has""",
        """been raised in the "try" proc and after running the "finally"""",
        "proc."
      ].join($' '):
        when defined(nimscript):
          skip()
        else:
          proc doTest [A; B; E: Exception](
            before: Io[A];
            `try`: proc (a: A): B {.raises: [].};
            expectedException: ref E
          ) =
            let
              actual =
                tryBracket[A, B]
                  .traceAndCatch(before, `try`, () => expectedException)
                  .run()
              expected =
                trace(@[Step.Before, Step.After], expectedException.some())

            check:
              actual == expected


          doTest(() => 12, itself[int], KeyError.newException(""))



  main()
