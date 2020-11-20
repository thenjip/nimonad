##[
  The `Reader` monad.

  A `Reader[S, T]` is a function that reads some environment (or state) `S`
  and returns some value `T`.
]##



import identity

import pkg/funcynim/[call, chain]

import std/[sugar]



type Reader* [S, T] = S -> T



func ask* (S: typedesc): Reader[S, S] =
  ##[
    Can be used to retrieve the read state within a
    [flatMap](#flatMap%2CReader%5BS%2CA%5D%2C) call.
  ]##
  itself[S]


func ask* [S](): Reader[S, S] =
  S.ask()



func toReader* [T](value: T; S: typedesc): Reader[S, T] =
  (_: S) => value


func toReader* [S; T](value: T): Reader[S, T] =
  value.toReader(S)



proc run* [S; T](self: Reader[S, T]; state: S): T =
  self.call(state)



func map* [S; A; B](self: Reader[S, A]; f: A -> B): Reader[S, B] =
  self.chain(f)


func flatMap* [S; A; B](
  self: Reader[S, A];
  f: A -> Reader[S, B]
): Reader[S, B] =
  (state: S) => self.run(state).f().run(state)



func local* [S; T](self: Reader[S, T]; f: S -> S): Reader[S, T] =
  ##[
    Returns a `Reader` that will execute `self` in an environment modified by
    `f`.
  ]##
  f.map(self)



when isMainModule:
  import laws
  import reader/private/test/laws as readerlaws

  import pkg/funcynim/[operators, partialproc, unit]

  import std/[macros, os, sequtils, strutils, unittest]



  proc main () =
    suite currentSourcePath().splitFile().name:
      test """"Reader[S, T]" should obey the monad laws.""":
        proc doTest [LA; LB; LS; RT; RS; AA; AB; AC; AS](
          spec: ReaderMonadLawsSpec[LA, LB, LS, RT, RS, AA, AB, AC, AS];
          runArgs: RunArgs[LS, RS, AS]
        ) =
          let (leftId, rightId, assoc) = spec.checkLaws(runArgs)

          check:
            leftId.actual == leftId.expected
            rightId.actual == rightId.expected
            assoc.actual == assoc.expected


        doTest(
          monadLawsSpec(
            leftIdentitySpec(
              @["a", "abc", "012"],
              partial(toReader(?_, Unit)),
              s => s.foldl(a + b.len().uint, 0u).toReader(Unit)
            ),
            rightIdentitySpec(
              Reader[cfloat, auto]((_: cfloat) => {0i16 .. 9i16}),
              toReader
            ),
            associativitySpec(
              (@[0, 7], 'a').toReader(string),
              (t: (seq[int], char)) =>
                t[0].foldl(a + b, 0).plus(t[1].ord()).toReader(string)
              ,
              (i: int) => i.modulo(2).toReader(string)
            )
          ),
          (unit(), 5.2, "abc")
        )



      test [
        "Side effect free expressions involving Reader[S, T] should be compile",
        "time compatible."
      ].join($' '):
        when defined(js):
          skip()
        else:
          proc doTest () =
            const results = (
              0.toReader(string).map(partial($ ?_)).run("abc"),
              partial($ ?:float)
                .flatMap((s: string) => itself[float].map(partial($ ?_)))
                .run(1.2)
            )

            discard results


          doTest()



      test [
        """"S.ask()" should give access to the read state inside "flatMap"."""
      ].join($' '):
        proc doTest [S; T](self: Reader[S, T]; expected: S) =
          let actual = self.flatMap((_: T) => S.ask()).run(expected)

          check:
            actual == expected


        doTest(partial(len(?:string)), "abc")



  main()
