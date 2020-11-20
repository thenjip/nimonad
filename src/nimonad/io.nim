##[
  The `IO` monad from Haskell.

  It lets one build a computation that has no parameters.
  It can also be used as a wrapper for computations that interact with external
  resources such as memory management, FFI, I/O, etc. .
]##



import reader

import pkg/funcynim/[call, chain, unit]
when not defined(nimscript):
  import pkg/funcynim/[ignore]

import std/[sugar]



type
  Io* [T] = () -> T



func toIo* [T](value: T): Io[T] =
  () => value



proc run* [T](self: Io[T]): T =
  self.call()



func map* [A; B](self: Io[A]; f: A -> B): Io[B] =
  self.chain(f)


func flatten* [T](self: Io[Io[T]]): Io[T] =
  self.map(run)


func flatMap* [A; B](self: Io[A]; f: A -> Io[B]): Io[B] =
  self.map(f).flatten()



func bracket* [A; B](before: Io[A]; between: A -> B; after: A -> Unit): Io[B] =
  ##[
    If an exception is raised anywhere in `before` or `between`, `after` will
    not be executed.
  ]##
  before.map(between.flatMap((b: B) => after.chain(_ => b)))



when not defined(nimscript):
  func tryBracket* [A; B](
    before: Io[A];
    `try`: A -> B;
    `finally`: A -> Unit
  ): Io[B] =
    ##[
      Any exception raised in `try` will be reraised by the returned `Io`.

      `finally` will be executed once, regardless of exception raising.
    ]##
    before.map(
      proc (a: A): B =
        try:
          a.`try`()
        except Exception as e:
          raise e
        finally:
          a.`finally`().ignore()
    )



when isMainModule:
  import identity, laws, optional
  import io/private/test/[brackettrace]
  import io/private/test/laws as iolaws

  import pkg/funcynim/[call, partialproc]
  when not defined(js):
    import pkg/funcynim/[lambda]

  import std/[os, sequtils, strutils, unittest]



  proc `$` [T](self: ref T): string =
    $cast[uint](self)



  proc main () =
    suite currentSourcePath().splitFile().name:
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
          skip()
        else:
          proc doTest () =
            const results =
              (
                "abc".toIo().map(partial(len(?_))).run(),
                0
                  .lambda()
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
            expected = bracketTrace(toSeq(BracketStep.items()), expectedOutput)

          check:
            actual == expected


        proc runTest1 () =
          let
            start = 1
            between = (i: start.typeof()) => -i.float

          doTest(() => start, between, doNothing, between.call(start))


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
            expected = @[BracketStep.Before]

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
              expected =
                bracketTrace(toSeq(BracketStep.items()), expectedOutput)

            check:
              actual == expected


          proc runTest1 () =
            let
              start = "abc"
              tryBlock = partial(len(?:start.typeof()))

            doTest(() => start, tryBlock, _ => unit(), tryBlock.call(start))


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
                bracketTrace(
                  @[BracketStep.Before, BracketStep.After],
                  expectedException.some()
                )

            check:
              actual == expected


          doTest(() => 12, itself[int], KeyError.newException(""))



  main()
