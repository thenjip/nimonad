import std/[sugar]



type
  Verdict* [T] = tuple
    actual: T
    expected: T

  MonadLawsVerdict* [L; R; A] = tuple
    leftIdentity: Verdict[L]
    rightIdentity: Verdict[R]
    associativity: Verdict[A]



func verdict* [T](actual, expected: T): Verdict[T] =
  (actual, expected)


func monadLawsVerdict* [L; R; A](
  leftIdentity: Verdict[L];
  rightIdentity: Verdict[R];
  associativity: Verdict[A]
): MonadLawsVerdict[L, R, A] =
  (leftIdentity, rightIdentity, associativity)



proc map* [A; B](self: Verdict[A]; f: A -> B): Verdict[B] =
  verdict(self.actual.f(), self.expected.f())


proc map* [LA; RA; AA; LB; RB; AB](
  self: MonadLawsVerdict[LA, RA, AA];
  fLeftId: LA -> LB;
  fRightId: RA -> RB;
  fAssoc: AA -> AB
): MonadLawsVerdict[LB, RB, AB] =
  let (leftId, rightId, assoc) = self

  monadLawsVerdict(
    leftId.map(fLeftId),
    rightId.map(fRightId),
    assoc.map(fAssoc)
  )


proc map* [LA; RA; AA; LB; RB; AB](
  self: MonadLawsVerdict[LA, RA, AA];
  f: tuple[leftId: LA -> LB; rightId: RA -> RB; assoc: AA -> AB]
): MonadLawsVerdict[LB, RB, AB] =
  self.map(f.leftId, f.rightId, f.assoc)
