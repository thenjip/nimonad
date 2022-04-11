import varutils

import pkg/nimonad/[io, optional]

import pkg/funcynim/[chain, partialproc, run, unit]

import std/[sugar]



type
  Step* {.pure.} = enum
    Before
    Between
    After

  Trace* [T] = tuple
    steps: seq[Step]
    output: T ## The output of the returned `Io[T]` by a `BracketCreator`.

  BracketCreator* [A; B] =
    (before: Io[A], between: A -> B, after: A -> Unit) -> Io[B]



func trace* [T](steps: seq[Step]; output: T): Trace[T] =
  (steps, output)



template trace [A; B](
  self: BracketCreator[A, B];
  before: Io[A];
  between: A -> B;
  after: A -> Unit;
  steps: var seq[Step]
): Io[B] =
  bind map, chain, addAndReturn

  self(
    map(before, partial(addAndReturn(steps, Step.Before, ?_))),
    chain(between, partial(addAndReturn(steps, Step.Between, ?_))),
    chain(after, partial(addAndReturn(steps, Step.After, ?_)))
  )


template traceWithException [A; B; E: Exception](
  self: BracketCreator[A, B];
  before: Io[A];
  between: proc (a: A): B {.raises: [].};
  exception: () -> ref E;
  steps: var seq[Step]
): Io[B] =
  self.trace(
    before,
    chain(between, proc (_: B): B = raise run(exception)),
    doNothing[A],
    steps
  )



func trace* [A; B](
  self: BracketCreator[A, B];
  before: Io[A];
  between: A -> B;
  after: A -> Unit
): Io[Trace[B]] =
  (
    proc (): Trace[B] =
      var steps = newSeqOfCap[Step]({Step.low() .. Step.high()}.card())

      self
        .trace(before, between, after, steps)
        .map(partial(trace(steps, ?:B)))
        .run()
  )


func traceSteps* [A; B; E: Exception](
  self: BracketCreator[A, B];
  before: Io[A];
  between: proc (a: A): B {.raises: [].};
  exception: () -> ref E
): Io[seq[Step]] =
  (
    proc (): seq[Step] =
      var steps = newSeqOfCap[Step](1)

      try:
        self
          .traceWithException(before, between, exception, steps)
          .map((_: B) => steps)
          .run()
      except E:
        steps
  )


when not defined(nimscript):
  func traceAndCatch* [A; B; E: Exception](
    self: BracketCreator[A, B];
    before: Io[A];
    between: proc (a: A): B {.raises: [].};
    exception: () -> ref E
  ): Io[Trace[Optional[ref E]]] =
    (
      proc (): Trace[Optional[ref E]] =
        var steps = newSeqOfCap[Step](1)

        try:
          self
            .traceWithException(before, between, exception, steps)
            .map((_: B) => trace(steps, none(ref E)))
            .run()
        except E as e:
          trace(steps, e.some())
    )
