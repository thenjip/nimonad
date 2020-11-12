##[
  Utilities to check whether a type `M` obeys the monad laws.

  This module is meant to be used in test suites. It should not be imported with
  [monadlaws](monadlaws.html).

  `M` must have:
    - A `flatMap[A; B]` procedure with the signature
      `(M[A], A -> M[B]) -> M[B]`.
    - A `run[A; R]` procedure with the signature `(M[A], R) -> A`.

  Concepts cannot currently be used to implement the monad concept in Nim.
  See this related [issue](https://github.com/nim-lang/Nim/issues/5650).
]##



import pkg/funcynim/[chain]

import std/[sugar]



type
  LazyMonad* [T; R] = concept m
    m.run(R) is T

  LeftIdentitySpec* [A; MA; MB; R] = tuple
    ##[
      Parameters for the left identity law.
    ]##
    initial: A
    lift: A -> MA
    f: A -> MB
    runArg: R

  RightIdentitySpec* [T; M; R] = tuple
    ##[
      Parameters for the right identity law.
    ]##
    expected: T
    lift: T -> M
    runArg: R

  AssociativitySpec* [A; B; MA; MB; MC; R] = tuple
    ##[
      Parameters for the associativity law.
    ]##
    initial: A
    lift: A -> MA
    f: A -> MB
    g: B -> MC
    runArg: R

  MonadLawsSpec* [LA; LMA; LMB; LR; RT; RM; RR; AA; AB; AMA; AMB; AMC; AR] =
    tuple
      leftIdentity: LeftIdentitySpec[LA, LMA, LMB, LR]
      rightIdentity: RightIdentitySpec[RT, RM, RR]
      associativity: AssociativitySpec[AA, AB, AMA, AMB, AMC, AR]



func leftIdentitySpec* [A; MA; MB; R](
  initial: A;
  lift: A -> MA;
  f: A -> MB;
  runArg: R
): LeftIdentitySpec[A, MA, MB, R] =
  ##[
    - `lift`: A procedure to lift a value to a monad.
    - `f`: The procedure passed to `flatMap` defined by the tested monad type.
  ]##
  (initial, lift, f, runArg)


func rightIdentitySpec* [T; M; R](
  expected: T;
  lift: T -> M;
  runArg: R
): RightIdentitySpec[T, M, R] =
  ##[
    - `expected`: Both The starting value on the left side of the equation and
      the final value on the right side.
    - `lift`: A procedure to lift a value to a monad.
  ]##
  (expected, lift, runArg)


func associativitySpec* [A; B; MA; MB; MC; R](
  initial: A;
  lift: A -> MA;
  f: A -> MB;
  g: B -> MC;
  runArg: R
): AssociativitySpec[A, B, MA, MB, MC, R] =
  ##[
    - `lift`: A procedure to lift a value to a monad.
    - `f`: The procedure passed to the first `flatMap` defined by the tested
      monad type.
    - `g`: The procedure passed to the second `flatMap` defined by the tested
      monad type.
  ]##
  (initial, lift, f, g, runArg)


func monadLawsSpec* [LA; LMA; LMB; LR; RT; RM; RR; AA; AB; AMA; AMB; AMC; AR](
  leftIdentity: LeftIdentitySpec[LA, LMA, LMB, LR];
  rightIdentity: RightIdentitySpec[RT, RM, RR];
  associativity: AssociativitySpec[AA, AB, AMA, AMB, AMC, AR]
): MonadLawsSpec[LA, LMA, LMB, LR, RT, RM, RR, AA, AB, AMA, AMB, AMC, AR] =
  (leftIdentity, rightIdentity, associativity)



template checkLeftIdentity* [A; MA; MB; R](
  spec: LeftIdentitySpec[A, MA, MB, R]
): bool =
  ##[
    Checks whether `a.lift().flatMap(f).run(r) == f(a).run(r)`.

    Lifting a value `a` to a monad, binding `f` to it and running the result
    should be the same as applying `f` to `a` and running the result.
  ]##
  spec
    .lift(spec.initial)
    .flatMap(spec.f)
    .run(spec.runArg)
    .`==`(spec.f(spec.initial).run(spec.runArg))



template checkRightIdentity* [T; M; R](spec: RightIdentitySpec[T, M, R]): bool =
  ##[
    Checks whether `a.lift().flatMap(lift).run(r) == a.lift().run(r)`.

    Lifting a value `a`, binding the `lift` procedure to it and running the
    result should be the same as lifting the value and running the result.
  ]##
  spec
    .lift(spec.expected)
    .flatMap(spec.lift)
    .run(spec.runArg)
    .`==`(spec.lift(spec.expected).run(spec.runArg))


template checkAssociativity* [A; B; MA; MB; MC; R](
  spec: AssociativitySpec[A, B, MA, MB, MC, R]
): bool =
  ##[
    Checks whether `a.lift().flatMap(f).flatMap(g).run(r) ==
    a.lift().flatMap(f.chain(m => m.flatMap(g))).run(r)`.

    Lifting a value `a`, binding `f`, then `g` to it and running the result
    should be the same as lifting `a`, binding `f.chain(m => m.flatMap(g))`
    and running the result.
  ]##
  spec
    .lift(spec.initial)
    .flatMap(spec.f)
    .flatMap(spec.g)
    .run(spec.runArg)
    .`==`(
      spec
        .lift(spec.initial)
        .flatMap(spec.f.chain(m => m.flatMap(spec.g)))
        .run(spec.runArg)
    )


template checkMonadLaws* [LA; LMA; LMB; LR; RT; RM; RR; AA; AB; AMA; AMB; AMC; AR](
  spec: MonadLawsSpec[LA, LMA, LMB, LR, RT, RM, RR, AA, AB, AMA, AMB, AMC, AR]
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
  import pkg/funcynim/[unit]

  import std/[os, unittest]



  type Id [T] = T



  func toId [T](value: T): Id[T] =
    value


  proc flatMap [A; B](self: Id[A]; f: A -> Id[B]): Id[B] =
    self.f()


  func run [T](self: Id[T]; _: Unit): T =
    self



  static:
    doAssert(Id[bool] is LazyMonad[bool, Unit])



  proc main () =
    suite currentSourcePath().splitFile().name:
      test "Id[T] should verify the lazy monad laws.":
        proc doTest [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC](
          spec: MonadLawsSpec[
            LA, LMA, LMB, Unit, RT, RM, Unit, AA, AB, AMA, AMB, AMC, Unit
          ]
        ) =
          check:
            spec.checkMonadLaws()

        doTest(
          monadLawsSpec(
            leftIdentitySpec(0, toId, a => `$`(a + 10), unit()),
            rightIdentitySpec((string -> string)(nil), toId, unit()),
            associativitySpec(
              'a',
              toId,
              a => a.Natural,
              (b: Natural) => b.`$`().toId(),
              unit()
            )
          )
        )



  main()
