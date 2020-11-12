##[
  The `Optional[T]` monad.

  It is a box containing either a value or nothing.

  This is another implementation of the `Option`/`Maybe` monad, but using only
  pure functional programming techniques to make it compatible with compile time
  execution.
]##



import identity, predicate, reader

import pkg/funcynim/[chain, ifelse, partialproc]

import std/[strformat, sugar]



type
  Nilable* = concept var x
    x = nil

  UnboxError* = object of CatchableError

  Optional* [T] = object
    when T is Nilable:
      value: T
    else:
      case empty: bool
        of true:
          discard
        else:
          value: T



template boxedType* [T](X: typedesc[Optional[T]]): typedesc[T] =
  T


template boxedType* [T](self: Optional[T]): typedesc[T] =
  self.typeof().boxedType()



func none* (T: typedesc[Nilable]): Optional[T] =
  Optional[T](value: nil)


func none* (T: typedesc[not Nilable]): Optional[T] =
  Optional[T](empty: true)


func none* [T](): Optional[T] =
  T.none()



func optionalNilable [T: Nilable](value: T): Optional[T] =
  Optional[T](value: value)



proc some* [T: Nilable](value: T): Optional[T] =
  assert(value != nil)

  value.optionalNilable()


func some* [T: not Nilable](value: T): Optional[T] =
  Optional[T](empty: false, value: value)



proc optional* [T: Nilable](value: T): Optional[T] =
  ##[
    If `value` is not `nil`, returns `value.some()`, otherwise an empty
    `Optional`.
  ]##
  value.optionalNilable()



func isNone* [T: Nilable](self: Optional[T]): bool =
  self.value == nil


func isNone* [T: not Nilable](self: Optional[T]): bool =
  self.empty



func isSome* [T](self: Optional[T]): bool =
  not self.isNone()



proc ifNone* [A; B](self: Optional[A]; then: () -> B; `else`: A -> B): B =
  self.isNone().ifElse(then, () => self.value.`else`())


proc ifSome* [A; B](self: Optional[A]; then: A -> B; `else`: () -> B): B =
  self.isSome().ifElse(() => self.value.then(), `else`)



proc flatMap* [A; B](self: Optional[A]; f: A -> Optional[B]): Optional[B] =
  ##[
    Applies `f` to the value inside `self` or does nothing if `self` is empty.
  ]##
  self.ifSome(f, none)


proc map* [A; B](self: Optional[A]; f: A -> B): Optional[B] =
  ##[
    Applies `f` to the value inside `self` or does nothing if `self` is empty.
  ]##
  self.flatMap(f.chain(some))


func flatten* [T](self: Optional[Optional[T]]): Optional[T] =
  self.flatMap(itself)



proc unboxOr* [T](self: Optional[T]; `else`: () -> T): T =
  self.ifSome(itself, `else`)



func raiseUnboxError [T](): T {.noinit, raises: [UnboxError].} =
  raise UnboxError.newException("")


func unbox* [T](self: Optional[T]): T {.raises: [Exception, UnboxError].} =
  ##[
    Retrieves the value inside `self` or raise an `UnboxError` if `self` is
    empty.
  ]##
  self.unboxOr(raiseUnboxError)



proc filter* [T](self: Optional[T]; predicate: Predicate[T]): Optional[T] =
  self.flatMap(predicate.ifElse(some, _ => T.none()))



func `==`* [T](self, other: Optional[T]): bool =
  self.ifSome(
    selfValue => other.ifSome(partial(?_ == selfValue), () => false),
    () => other.isNone()
  )


proc `$`* [T](self: Optional[T]): string =
  self.ifSome(value => fmt"some({value})", () => fmt"none({$T})")



when isMainModule:
  import monadlaws

  import pkg/funcynim/[call, ignore, partialproc, unit]

  import std/[os, strutils, unittest]



  proc main () =
    suite currentSourcePath().splitFile().name:
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


        when defined(js):
          doTest(ref RootObj)
        else:
          doTest(pointer)



      test """"nil.optional()" should return "none".""":
        proc doTest (T: typedesc[Nilable]) =
          let
            actual = nil.T.optional()
            expected = T.none()

          check:
            actual == expected


        when not defined(js):
          doTest(pointer)
        doTest(Predicate[uint16])
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



      test """"Optional[T]" should obey the monad laws.""":
        proc doTest [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC](
          spec: MonadLawsSpec[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC]
        ) =
          check:
            spec.checkMonadLaws()


        doTest(
          monadLawsSpec(
            leftIdentitySpec(NaN, some, _ => float32.none()),
            ["".cstring, nil]
              .apply(
                expected =>
                  rightIdentitySpec(expected, _ => expected.typeof().none())
              )
            ,
            associativitySpec(
              69,
              some,
              i => some(none[i.typeof()]),
              (p: none[int].typeof()) => p.call().`$`().some()
            )
          )
        )



      test [
        "Side effect free expressions involving Optional[T] should be compile",
        "time compatible."
      ].join($' '):
        when defined(js):
          skip()
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
