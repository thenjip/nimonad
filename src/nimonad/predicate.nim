import reader

import pkg/funcynim/[ifelse, partialproc]

import std/[sugar]



type
  Predicate* [T] = Reader[T, bool]



proc test* [T](self: Predicate[T]; value: T): bool =
  self.run(value)



func `not`* [T](self: Predicate[T]): Predicate[T] =
  self.map(partial(not ?_))


func `and`* [T](self, then: Predicate[T]): Predicate[T] =
  ##[
    The returned predicate will use the short circuiting `and`.
  ]##
  (value: T) => self.test(value) and then.test(value)


func `or`* [T](self, `else`: Predicate[T]): Predicate[T] =
  ##[
    The returned predicate will use the short circuiting `or`.
  ]##
  (value: T) => self.test(value) or `else`.test(value)



func ifElse* [A; B](self: Predicate[A]; then, `else`: A -> B): A -> B =
  (value: A) => self.test(value).ifElse(() => then(value), () => `else`(value))



func alwaysFalse* [T](_: T): bool =
  false


func alwaysTrue* [T](_: T): bool =
  true



when isMainModule:
  import identity
  import predicate/private/test/[predicatetrace]

  import pkg/funcynim/[call, chain, partialproc, unit]

  import std/[os, strutils, unittest]



  proc main () =
    suite currentSourcePath().splitFile().name:
      test """"self.test(value)" should return the expected boolean.""":
        proc doTest [T](self: Predicate[T]; value: T; expected: bool) =
          let actual = self.test(value)

          check:
            actual == expected


        doTest(alwaysFalse[ref Defect], nil, false)
        doTest(alwaysTrue[bool], false, true)
        doTest(partial(?:Natural < 10), 4, true)
        doTest((s: string) => s.len() > 3, "a", false)



      test [
        """"not self" should return a predicate that is the negation of""",
        "\"self\"."
      ].join($' '):
        proc doTest [T](self: Predicate[T]; value: T; expected: bool) =
          let actual = self.`not`().test(value)

          check:
            actual == expected


        doTest(alwaysTrue[int], -854, false)
        doTest(partial(22 in ?:set[uint8]), {0u8, 255u8, 6u8}, true)



      test [
        """"self and then" should return a predicate that combines "self"""",
        """and "then" with a logical "and"."""
      ].join($' '):
        proc doTest [T](self, then: Predicate[T]; value: T; expected: bool) =
          let actual = self.`and`(then).test(value)

          check:
            actual == expected


        doTest(alwaysFalse[char], alwaysTrue, '\r', false)
        doTest(partial(?:int > 0), partial(?_ < 100), 91, true)



      test [
        """"self or `else`" should return a predicate that combines "self"""",
        """and "else" with a logical "or"."""
      ].join($' '):
        proc doTest [T](self, `else`: Predicate[T]; value: T; expected: bool) =
          let actual = self.`or`(`else`).test(value)

          check:
            actual == expected


        doTest(alwaysTrue[Positive], i => i > 8, 1, true)
        doTest(partial(0 in ?:seq[int]), partial(1 in ?_), @[2, 5, 1, 7], true)



      test [
        """"self.ifElse(then, `else`)(value)" should take the "then" path""",
        """when "value" verifies "self"."""
      ].join($' '):
        proc doTest [A; B](self: Predicate[A]; then, `else`: A -> B; value: A) =
          let
            actual = self.tracedIfElse(then, `else`).run(value)
            expected = predicateTrace(PredicatePath.Then, then.call(value))

          check:
            actual == expected


        doTest(alwaysTrue[Unit], itself[Unit], itself, unit())
        doTest((i: int16) => i > 500, partial($ ?_), _ => "abc", 542)



      test [
        """"self.ifElse(then, `else`)(value)" should take the "else" path""",
        """when "value" does not verify "self"."""
      ].join($' '):
        proc doTest [A; B](self: Predicate[A]; then, `else`: A -> B; value: A) =
          let
            actual = self.tracedIfElse(then, `else`).run(value)
            expected = predicateTrace(PredicatePath.Else, `else`.call(value))

          check:
            actual == expected


        doTest(alwaysFalse[int16], partial($ ?_), _ => "abc", 542)
        doTest(isEmptyOrWhitespace, partial(len(?_)), _ => 0, " a ")



      test [
        "Side effect free expressions involving Predicate[T] should be compile",
        "time compatible."
      ].join($' '):
        when defined(js):
          skip()
        else:
          proc doTest () =
            const results =
              (
                isAlphaAscii.Predicate[:char].test('0'),
                ((s: string) => s.len() < 10)
                  .`and`(not isEmptyOrWhitespace)
                  .test("abc")
              )

            discard results


          doTest()



  main()
