##[
  Utilities to check whether a type `M` obeys the monad laws.

  This module is meant to be used in test suites. It should not be imported with
  [lazymonadlaws](lazymonadlaws.html).

  `M` must have:
    - A `flatMap[A; B]` procedure with the signature
      `(M[A], A -> M[B]) -> M[B]`.
    - An equality operator.

  Concepts cannot currently be used to implement the monad concept in Nim.
  See this related [issue](https://github.com/nim-lang/Nim/issues/5650).
]##



import pkg/funcynim/[chain]

import std/[sugar]



type
  LeftIdentitySpec* [A; MA; MB] = tuple
    ##[
      Parameters for the left identity law.
    ]##
    initial: A
    lift: A -> MA
    f: A -> MB

  RightIdentitySpec* [T; M] = tuple
    ##[
      Parameters for the right identity law.
    ]##
    expected: T
    lift: T -> M

  AssociativitySpec* [A; B; MA; MB; MC] = tuple
    ##[
      Parameters for the associativity law.
    ]##
    initial: A
    lift: A -> MA
    f: A -> MB
    g: B -> MC

  MonadLawsSpec* [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC] = tuple
    leftIdentity: LeftIdentitySpec[LA, LMA, LMB]
    rightIdentity: RightIdentitySpec[RT, RM]
    associativity: AssociativitySpec[AA, AB, AMA, AMB, AMC]



func leftIdentitySpec* [A; MA; MB](
  initial: A;
  lift: A -> MA;
  f: A -> MB
): LeftIdentitySpec[A, MA, MB] =
  ##[
    - `lift`: A procedure to lift a value to a monad.
    - `f`: The procedure passed to `flatMap` defined by the tested monad type.
  ]##
  (initial, lift, f)


func rightIdentitySpec* [T; M](
  expected: T;
  lift: T -> M
): RightIdentitySpec[T, M] =
  ##[
    - `expected`: Both the starting value on the left side of the equation and
      the final value on the right side.
    - `lift`: A procedure to lift a value to a monad.
  ]##
  (expected, lift)


func associativitySpec* [A; B; MA; MB; MC](
  initial: A;
  lift: A -> MA;
  f: A -> MB;
  g: B -> MC;
): AssociativitySpec[A, B, MA, MB, MC] =
  ##[
    - `lift`: A procedure to lift a value to a monad.
    - `f`: The procedure passed to the first `flatMap` defined by the tested
      monad type.
    - `g`: The procedure passed to the second `flatMap` defined by the tested
      monad type.
  ]##
  (initial, lift, f, g)



func monadLawsSpec* [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC](
  leftIdentity: LeftIdentitySpec[LA, LMA, LMB];
  rightIdentity: RightIdentitySpec[RT, RM];
  associativity: AssociativitySpec[AA, AB, AMA, AMB, AMC]
): MonadLawsSpec[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC] =
  (leftIdentity, rightIdentity, associativity)



template checkLeftIdentity* [A; MA; MB](
  spec: LeftIdentitySpec[A, MA, MB]
): bool =
  ##[
    Checks whether `a.lift().flatMap(f) == f(a)`.

    Lifting a value `a` to a monad, and binding `f` to it should be the same as
    applying `f` to `a`.
  ]##
  spec.lift(spec.initial).flatMap(spec.f) == spec.f(spec.initial)



template checkRightIdentity* [T; M](spec: RightIdentitySpec[T, M]): bool =
  ##[
    Checks whether `a.lift().flatMap(lift) == a.lift()`.

    Lifting a value `a`, and binding the same `lift` procedure to it should be
    the same as lifting `a`.
  ]##
  spec.lift(spec.expected).flatMap(spec.lift) == spec.lift(spec.expected)


template checkAssociativity* [A; B; MA; MB; MC](
  spec: AssociativitySpec[A, B, MA, MB, MC]
): bool =
  ##[
    Checks whether `a.lift().flatMap(f).flatMap(g) ==
    a.lift().flatMap(f.chain(m => m.flatMap(g)))`.

    Lifting a value `a`, binding `f`, then `g` to it should be the same as
    lifting `a` and binding `f.chain(m => m.flatMap(g))`.
  ]##
  spec
    .lift(spec.initial)
    .flatMap(spec.f)
    .flatMap(spec.g)
    .`==`(spec.lift(spec.initial).flatMap(spec.f.chain(m => m.flatMap(spec.g))))


template checkMonadLaws* [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC](
  spec: MonadLawsSpec[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC]
): bool =
  `==`(
    (
      leftIdentity: spec.leftIdentity.checkLeftIdentity(),
      rightIdentity: spec.rightIdentity.checkRightIdentity(),
      associativity: spec.associativity.checkAssociativity()
    ),
    (leftIdentity: true, rightIdentity: true, associativity: true)
  )




when isMainModule:
  import std/[os, unittest]



  type Id[T] = T



  func toId [T](value: T): Id[T] =
    value


  proc flatMap [A; B](self: Id[A]; f: A -> Id[B]): Id[B] =
    self.f()



  proc main () =
    suite currentSourcePath().splitFile().name:
      test "Id[T] should verify the monad laws.":
        proc doTest [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC](
          spec: MonadLawsSpec[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC]
        ) =
          check:
            spec.checkMonadLaws()

        doTest(
          monadLawsSpec(
            leftIdentitySpec(0, toId, a => `$`(a + 10)),
            rightIdentitySpec((string -> string)(nil), toId),
            associativitySpec(
              'a',
              toId,
              a => a.Natural,
              (b: Natural) => b.`$`().toId()
            )
          )
        )



  main()
