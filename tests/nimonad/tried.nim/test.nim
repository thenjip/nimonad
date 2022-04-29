when isMainModule:
  import laws, trace

  import pkg/nimonad/[tried]

  import pkg/funcynim/[ignore, run, unit]

  import std/[strutils, sugar, unittest]



  proc main () =
    suite "nimonad/tried":
      test(
        """"self.isSuccess()" should return "true" when "self" is a success."""
      ):
        proc doTest [S](value: S; F: typedesc) =
          let
            actual = value.success(F).isSuccess()
            expected = true

          check:
            actual == expected


        doTest(5, Unit)
        doTest("abc", ref CatchableError)



      test(
        """"self.isSuccess()" should return "false" when "self" is a failure."""
      ):
        proc doTest [F](value: F; S: typedesc) =
          let
            actual = value.failure(S).isSuccess()
            expected = false

          check:
            actual == expected


        doTest("aaaaa", float)
        doTest(ValueError.newException(""), Unit)



      test(
        """"self.isFailure()" should return "false" when "self" is a success."""
      ):
        proc doTest [S](value: S; F: typedesc) =
          let
            actual = value.success(F).isFailure()
            expected = false

          check:
            actual == expected


        doTest(5, Unit)
        doTest("abc", ref CatchableError)



      test(
        """"self.isFailure()" should return "true" when "self" is a failure."""
      ):
        proc doTest [F](value: F; S: typedesc) =
          let
            actual = value.failure(S).isFailure()
            expected = true

          check:
            actual == expected


        doTest("aaaaa", float)
        doTest(ValueError.newException(""), Unit)



      test [
        """"self.fold(_, _)" should take the "onSucess" path when "self" is""",
        "a success."
      ].join($' '):
        proc doTest [S; T](
          value: S;
          F: typedesc;
          onSuccess: S -> T;
          onFailure: F -> T
        ) =
          let
            actual = value.success(F).tracedFold(onSuccess, onFailure)
            expected = traceOutput(Path.Success, onSuccess.run(value))

          check:
            actual == expected


        doTest(1, string, i => $i, _ => "abc")



      test """"Tried[S, F]" should verify the monad laws.""":
        proc doTest [LA; LB; RT; AA; AB; AC](
          spec: TriedMonadLawsSpec[LA, LB, RT, AA, AB, AC]
        ) =
          let (leftId, rightId, assoc) = spec.checkLaws()

          check:
            leftId.actual == leftId.expected
            rightId.actual == rightId.expected
            assoc.actual == assoc.expected


        proc lift [T](self: T): Tried[T, Unit] =
          self.success(Unit)


        doTest(
          monadLawsSpec(
            leftIdentitySpec(0, lift, i => i.float.lift()),
            rightIdentitySpec("abc".lift(), lift),
            associativitySpec(
              'a'.lift(),
              (c: char) => {c}.lift(),
              (s: set[char]) => s.len().lift()
            )
          )
        )



      test [
        """"self.unboxSuccess()" should return the value inside "self" when""",
        """"self" is a success."""
      ].join($' '):
        proc doTest [S](expected: S; F: typedesc) =
          let actual = expected.success(F).unboxSuccess()

          check:
            actual == expected


        doTest(11, Unit)
        doTest("abc", (int8, char))



      test [
        """"self.unboxSuccess()" should raise an "UnboxError" when "self" is""",
        """a failure."""
      ].join($' '):
        proc doTest [F](value: F; S: typedesc) =
          let self = value.failure(S)

          expect UnboxError:
            self.unboxSuccess().ignore()


        doTest(11, Unit)
        doTest("abc", (int8, char))



      test [
        """"self.unboxSuccessOrRaise()" should return the value inside "self"""",
        """when "self" is a success."""
      ].join($' '):
        proc doTest [S](expected: S; F: typedesc[CatchableError]) =
          let actual = expected.success(Unit -> ref F).unboxSuccessOrRaise()

          check:
            actual == expected


        doTest(-8i16, ValueError)
        doTest("abc", KeyError)



      test [
        """"self.unboxSuccessOrRaise()" should raise the exception inside""",
        """"self" when "self" is a failure."""
      ].join($' '):
        proc doTest [F: CatchableError](error: Unit -> ref F; S: typedesc) =
          let self = error.failure(S)

          expect F:
            self.unboxSuccessOrRaise().ignore()


        proc doTest [F: CatchableError](error: ref F; S: typedesc) =
          let self = error.failure(S)

          expect F:
            self.unboxSuccessOrRaise().ignore()


        doTest(_ => ValueError.newException(""), Unit)
        doTest(KeyError.newException(""), string)



      test [
        """"self.unboxFailure()" should return the value inside "self" when""",
        """"self" is a failure."""
      ].join($' '):
        proc doTest [F](expected: F; S: typedesc) =
          let actual = expected.failure(S).unboxFailure()

          check:
            actual == expected


        doTest("abc".cstring, (char, string))



      test [
        """"self.unboxFailure()" should raise an "UnboxError" when "self" is""",
        """a success."""
      ].join($' '):
        proc doTest [S](value: S; F: typedesc) =
          let self = value.success(F)

          expect UnboxError:
            self.unboxFailure().ignore()


        doTest(5.6, Unit)
        doTest("abc", int -> string)



  main()
