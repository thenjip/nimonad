import varutils
import ../../../io, ../../../optional

import pkg/funcynim/[call, chain, partialproc, unit]

import std/[sugar]



export call, chain, partialproc, varutils



type
  BracketStep* {.pure.} = enum
    Before
    Between
    After

  BracketTrace* [T] = tuple
    steps: seq[BracketStep]
    output: T ## The output of the returned `IO[T]` by a `BracketCreator`.

  BracketCreator* [A; B] =
    (before: IO[A], between: A -> B, after: A -> Unit) -> IO[B]



func bracketTrace* [T](steps: seq[BracketStep]; output: T): BracketTrace[T] =
  (steps, output)



template trace* [A; B](
  self: BracketCreator[A, B];
  before: IO[A];
  between: A -> B;
  after: A -> Unit;
  steps: var seq[BracketStep]
): IO[B] =
  self.call(
    before.map(partial(steps.addAndReturn(BracketStep.Before, ?_))),
    between.chain(partial(steps.addAndReturn(BracketStep.Between, ?_))),
    after.chain(partial(steps.addAndReturn(BracketStep.After, ?_)))
  )


template traceWithException* [A; B; E: Exception](
  self: BracketCreator[A, B];
  before: IO[A];
  between: proc (a: A): B {.raises: [].};
  exception: () -> ref E;
  steps: var seq[BracketStep]
): IO[B] =
  self.trace(
    before,
    between.chain(proc (_: B): B = raise exception.call),
    doNothing[A],
    steps
  )



func trace* [A; B](
  self: BracketCreator[A, B];
  before: IO[A];
  between: A -> B;
  after: A -> Unit
): IO[BracketTrace[B]] =
  (
    proc (): BracketTrace[B] =
      var steps = newSeqOfCap[BracketStep](
        {BracketStep.low() .. BracketStep.high()}.card()
      )

      self
        .trace(before, between, after, steps)
        .map(partial(bracketTrace(steps, ?:B)))
        .run()
  )


func traceSteps* [A; B; E: Exception](
  self: BracketCreator[A, B];
  before: IO[A];
  between: proc (a: A): B {.raises: [].};
  exception: () -> ref E
): IO[seq[BracketStep]] =
  (
    proc (): seq[BracketStep] =
      var steps = newSeqOfCap[BracketStep](1)

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
    before: IO[A];
    between: proc (a: A): B {.raises: [].};
    exception: () -> ref E
  ): IO[BracketTrace[Optional[ref E]]] =
    (
      proc (): BracketTrace[Optional[ref E]] =
        var steps = newSeqOfCap[BracketStep](1)

        try:
          self
            .traceWithException(before, between, exception, steps)
            .map((_: B) => bracketTrace(steps, none(ref E)))
            .run()
        except E as e:
          bracketTrace(steps, e.some())
    )
