when isMainModule:
  import laws

  import pkg/nimonad/[optional, predicate]

  import pkg/funcynim/[ignore, partialproc, run, unit]

  import std/[strutils, sugar, unittest]



  proc main () =
    suite "nimonad/optional":
      test """"Nilable" should match standard "nil" types.""":
        proc doTest (T: typedesc) =
          check:
            T is Nilable


        doTest(ptr cstring)
        when declared(system.pointer):
          doTest(pointer)
        doTest(ref tuple[a: Unit; b: char])
        doTest(int -> string)
        doTest(cstring)



      test """"Nilable" should not match standard non "nil" types.""":
        proc doTest (T: typedesc) =
          check:
            T isnot Nilable


        doTest(cuint)
        doTest(string)
        doTest(seq[cdouble])
        doTest(tuple[a: Unit; b: byte])
        doTest(Slice[Natural])
        doTest(Positive)



      test """"nil.some()" should raise a "Defect" at runtime.""":
        proc doTest (T: typedesc[Nilable]) =
          expect Defect:
            nil.T.some().ignore()


        doTest(ref RootObj)



      test """"nil.optional()" should return "none".""":
        proc doTest (T: typedesc[Nilable]) =
          let
            actual = nil.T.optional()
            expected = T.none()

          check:
            actual == expected


        when declared(system.pointer):
          doTest(pointer)
        doTest(uint16 -> bool)
        doTest(ref Exception)



      test [
        """"value.optional()" should return "some" when "value" is not "nil"."""
      ].join($' '):
        proc doTest [T: Nilable](value: T) =
          let
            actual = value.optional()
            expected = value.some()

          check:
            actual == expected


        doTest(doTest[cstring])
        doTest(new byte)



      test """"Optional[T]" should verify the monad laws.""":
        proc doTest [LA; LB; RT; AA; AB; AC](
          spec: OptionalMonadLawsSpec[LA, LB, RT, AA, AB, AC]
        ) =
          let (leftId, rightId, assoc) = spec.checkLaws()

          check:
            leftId.actual == leftId.expected
            rightId.actual == rightId.expected
            assoc.actual == assoc.expected


        doTest(
          monadLawsSpec(
            leftIdentitySpec(NaN, some, _ => float32.none()),
            rightIdentitySpec(@[""].some(), some),
            associativitySpec(
              69.some(),
              (i: int) => i.float.some(),
              (f: float) => f.`$`().some()
            )
          )
        )



      test [
        "Side effect free expressions involving Optional[T] should be compile",
        "time compatible."
      ].join($' '):
        when defined(js):
          skip() # https://github.com/nim-lang/Nim/issues/12492
        else:
          proc doTest () =
            const results = (
              0.some().some.flatten(),
              string.none().map(partial(len(?_))),
              5.4.some().unbox()
            )

            discard results

          doTest()



      test [
        """"unboxOr" with "some" should return the value inside the Optional."""
      ].join($' '):
        proc doTest [T](expected: T; unexpected: T) =
          require:
            expected != unexpected

          let actual = expected.some().unboxOr(() => unexpected)

          check:
            actual == expected


        doTest("abc".cstring, nil)
        doTest(0, 1)



      test """"unboxOr" with "none" should return the default value passed.""":
        proc doTest [T](expected: T) =
          let actual = T.none().unboxOr(() => expected)

          check:
            actual == expected


        doTest('a')
        doTest(unboxOr[int32])



      test [
        """"unbox" with "some" should return the value inside the Optional."""
      ].join($' '):
        proc doTest [T](expected: T) =
          let actual = expected.some().unbox()

          check:
            actual == expected


        doTest(["a", "b"])
        doTest(1)
        doTest((1, 1.005))
        doTest(() => 5)



      test """"unbox" with "none" should raise an UnboxError.""":
        proc doTest (T: typedesc) =
          expect UnboxError:
            T.none().unbox().ignore()


        doTest(int)



      test """"self.filter(predicate)" with "none" should return "none".""":
        proc doTest [T](predicate: Predicate[T]) =
          let
            expected = T.none()
            actual = expected.filter(predicate)

          check:
            actual == expected


        doTest((s: string) => s.len() > 0)
        doTest(alwaysTrue[uint])
        doTest(alwaysFalse[ptr cint])



      test [
        """"self.filter(predicate)" with "some" and a predicate that will be""",
        """verified should return "self"."""
      ].join($' '):
        proc doTest [T](value: T) =
          let
            expected = value.some()
            actual = expected.filter(alwaysTrue[T])

          check:
            actual == expected


        doTest(new cfloat)
        doTest('a')



      test [
        """"self.filter(predicate)" with "some" and a predicate that will""",
        """not be verified should return "none"."""
      ].join($' '):
        proc doTest [T](value: T) =
          let
            expected = T.none()
            actual = value.some().filter(alwaysFalse[T])

          check:
            actual == expected


        doTest("abc".cstring)
        when defined(js):
          doTest(partial($ ?:int))
        else:
          doTest(partial($ ?:uint))
        doTest(0)



  main()
