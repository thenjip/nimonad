# nimonad

[![Build Status](https://github.com/thenjip/nimonad/workflows/Tests/badge.svg?branch=main)](https://github.com/thenjip/nimonad/actions?query=workflow%3A"Tests"+branch%3A"main")
[![Licence](https://img.shields.io/github/license/thenjip/nimonad.svg)](https://raw.githubusercontent.com/thenjip/nimonad/main/LICENSE)

A monad library for Nim.

This project focuses on maximum backend compatibility:

- C
- C++
- Objective-C
- JavaScript
- NimScript (not tested yet)
- Compile time expressions in all the backends above

## Installation

```sh
nimble install 'https://github.com/thenjip/nimonad'
```

### Dependencies

- [`nim`](https://nim-lang.org/) >= `1.6.0`
- [`funcynim`](https://github.com/thenjip/funcynim) >= `1.0.0`

## Documentation

- [API](https://thenjip.github.io/nimonad)

## Features

### Monads

#### `Optional[T]`

An implementation similar to
[`std/options`](https://nim-lang.org/docs/options.html) but without unsafe
operations.

[`ifSome`](https://thenjip.github.io/nimonad/nimonad/reader.html#ifSome%2COptional%5BA%5D%2C%2C)
is the procedure that makes it possible.

```nim
import pkg/funcynim/[ifelse]
import pkg/nimonad/[optional]
import std/[os, sugar]

proc findExec (exe: string): Optional[string] =
  exe.findExe().`==`("").ifElse(none[result.boxedType()], () => exe.some())

echo(getCurrentCompilerExe().findExec())
```

#### `Io[T]`

An alias for `() -> T`.

It is quite useful as an abstraction for scopes.

For example, it can be used as a library version of
[ARC](https://nim-lang.org/blog/2020/10/15/introduction-to-arc-orc-in-nim.html).
Instead of defining special procedures (hooks), they are passed as regular parameters to
[`bracket`](https://thenjip.github.io/nimonad/nimonad/io.html#bracket%2CIo%5BA%5D%2C%2C)
and alike.

```nim
import pkg/funcynim/[ignore, unit]
import pkg/nimonad/[io]
import std/[sugar]

proc withFile [T](file: () -> File; compute: File -> T): Io[T] =
  file.tryBracket(compute, proc (f: File): Unit = f.close())
  #[
    `tryBracket` will ensure that the `File` will be closed at the end of
    running the returned `Io[T]`, even if an exception is raised in `compute`.
  ]#

proc openCurrentSrcFile (): File =
  currentSourcePath().open()

proc assertPositiveFileSize (f: File): Unit =
  doAssert(f.getFileSize() > 0)

openCurrentSrcFile.withFile(assertPositiveFileSize).run().ignore()
```

### Monad laws

The library provides an API to test a type's `flatMap`/`bind`/`>>=` operator for
[monad laws](https://miklos-martin.github.io/learn/fp/2016/03/10/monad-laws-for-regular-developers.html)
compliance.

#### Checking the monad laws for `Optional[T]`

```nim
import pkg/nimonad/[laws, optional]
import std/[sugar]



type
  OptionalMonadLawsSpec* [LA; LB; RT; AA; AB; AC] =
    MonadLawsSpec[
      LA, Optional[LA], Optional[LB],
      RT, Optional[RT],
      AA, AB, Optional[AA], Optional[AB], Optional[AC]
    ]



proc checkLaws* [LA; LB; RT; AA; AB; AC](
  self: OptionalMonadLawsSpec[LA, LB, RT, AA, AB, AC]
): MonadLawsVerdict[Optional[LB], Optional[RT], Optional[AC]] =
  self.checkLaws(optional.flatMap[int, int])


proc test [LA; LB; RT; AA; AB; AC](
  spec: OptionalMonadLawsSpec[LA, LB, RT, AA, AB, AC]
) =
  let (leftId, rightId, assoc) = spec.checkLaws()

  doAssert(leftId.actual == leftId.expected)
  doAssert(rightId.actual == rightId.expected)
  doAssert(assoc.actual == assoc.expected)



test(
  monadLawsSpec(
    leftIdentitySpec(NaN, some, _ => float32.none()),
    rightIdentitySpec(@[""].some(), some),
    associativitySpec(
      69.some(),
      (i: int) => i.float.some(),
      (f: float) => f.`$`().some()
    )
  )
)
```

#### Checking the monad laws for `Io[T]`

```nim
import pkg/nimonad/[io, laws]
import std/[sugar]



type
  IoMonadLawsSpec [LA; LB; RT; AA; AB; AC] =
    MonadLawsSpec[
      LA, Io[LA], Io[LB],
      RT, Io[RT],
      AA, AB, Io[AA], Io[AB], Io[AC]
    ]



proc checkLaws [LA; LB; RT; AA; AB; AC](
  self: IoMonadLawsSpec[LA, LB, RT, AA, AB, AC]
): MonadLawsVerdict[LB, RT, AC] =
  self.checkLaws(io.flatMap[int, int]).map(run[LB], run[RT], run[AC])


proc test [LA; LB; RT; AA; AB; AC](
  spec: IoMonadLawsSpec[LA, LB, RT, AA, AB, AC]
) =
  let (leftId, rightId, assoc) = spec.checkLaws()

  doAssert(leftId.actual == leftId.expected)
  doAssert(rightId.actual == rightId.expected)
  doAssert(assoc.actual == assoc.expected)



test(
  monadLawsSpec(
    leftIdentitySpec(-5, toIo, i => toIo(-i)),
    rightIdentitySpec(Io[auto](() => "abc"), toIo),
    associativitySpec(
      ('a', true).toIo(),
      (t: (char, bool)) => (t[0], not t[1]).toIo(),
      (t: (char, bool)) => t[0].`$`().len().toIo()
    )
  )
)
```

### Predicates

It is not a monad, but `Predicate[T]` is the same as `Reader[T, bool]`:
`T -> bool`.

The library provides predicate counterparts of the logical boolean operators.

```nim
import pkg/nimonad/[predicate]
import std/[strutils]

doAssert(not test(isEmptyOrWhitespace and alwaysFalse, ""))
doAssert(isAlphaAscii.`not`().test('0'))
```
