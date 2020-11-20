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
    initial: M
    lift: T -> M

  AssociativitySpec* [A; B; MA; MB; MC] = tuple
    ##[
      Parameters for the associativity law.
    ]##
    initial: MA
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
    - `f`: The procedure passed to `flatMap`.
  ]##
  (initial, lift, f)


func rightIdentitySpec* [T; M](
  initial: M;
  lift: T -> M
): RightIdentitySpec[T, M] =
  ##[
    - `initial`: Both the starting value on the left side of the equation and
      the final value on the right side.
    - `lift`: A procedure to lift a value to a monad.
  ]##
  (initial, lift)


func associativitySpec* [A; B; MA; MB; MC](
  initial: MA;
  f: A -> MB;
  g: B -> MC;
): AssociativitySpec[A, B, MA, MB, MC] =
  ##[
    - `f`: The procedure passed to the first `flatMap`.
    - `g`: The procedure passed to the second `flatMap`.
  ]##
  (initial, f, g)



func monadLawsSpec* [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC](
  leftIdentity: LeftIdentitySpec[LA, LMA, LMB];
  rightIdentity: RightIdentitySpec[RT, RM];
  associativity: AssociativitySpec[AA, AB, AMA, AMB, AMC]
): MonadLawsSpec[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC] =
  (leftIdentity, rightIdentity, associativity)
