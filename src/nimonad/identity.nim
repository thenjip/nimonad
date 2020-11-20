##[
  The identity monad.

  It does not do much in itself, but at least it defines the identity function.
]##



import std/[sugar]



func itself* [T](value: T): T =
  value


proc apply* [A; B](self: A; f: A -> B): B =
  self.f()



when isMainModule:
  import laws
  import identity/private/test/laws as identitylaws

  import pkg/funcynim/[partialproc]

  import std/[os, unittest]



  proc main () =
    suite currentSourcePath().splitFile().name:
      test """The identity monad should verify the monad laws.""":
        proc doTest [LA; LB; RT; AA; AB; AC](
          spec: IdentityMonadLawsSpec[LA, LB, RT, AA, AB, AC]
        ) =
          let (leftId, rightId, assoc) = spec.checkLaws()

          check:
            leftId.actual == leftId.expected
            rightId.actual == rightId.expected
            assoc.actual == assoc.expected


        doTest(
          monadLawsSpec(
            leftIdentitySpec(0, itself, partial($ ?_)),
            rightIdentitySpec("abc", itself),
            associativitySpec('c', partial($ ?:char), partial(len(?:string)))
          )
        )



  main()
