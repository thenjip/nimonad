import ../flatmapper

import std/[macros]



type
  AssociativityFlatMappers* [A; B; MA; MB; MC] = tuple
    first: FlatMapper[MA, A, MB]
    second: FlatMapper[MB, B, MC]
    outer: FlatMapper[MA, A, MC]

  MonadLawsFlatMappers* [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC] = tuple
    leftIdentity: FlatMapper[LMA, LA, LMB]
    rightIdentity: FlatMapper[RM, RT, RM]
    associativity: AssociativityFlatMappers[AA, AB, AMA, AMB, AMC]

  GenericFlatMapperSymbol = object
    symbol: NimNode



func monadLawsFlatMappers* [LA; LMA; LMB; RT; RM; AA; AB; AMA; AMB; AMC](
  leftIdentity: FlatMapper[LMA, LA, LMB];
  rightIdentity: FlatMapper[RM, RT, RM];
  associativity: AssociativityFlatMappers[AA, AB, AMA, AMB, AMC]
): MonadLawsFlatMappers[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC] =
  (leftIdentity, rightIdentity, associativity)


func associativityFlatMappers* [A; B; MA; MB; MC](
  first: FlatMapper[MA, A, MB];
  second: FlatMapper[MB, B, MC];
  outer: FlatMapper[MA, A, MC]
): AssociativityFlatMappers[A, B, MA, MB, MC] =
  (first, second, outer)



func genericSymbol (flatMapperInst: NimNode): GenericFlatMapperSymbol =
  GenericFlatMapperSymbol(symbol: flatMapperInst.strVal().ident())


func instantiate (
  self: GenericFlatMapperSymbol;
  MA, A, MB: NimNode
): NimNode =
  let ident = self.symbol

  "flatMapper"
    .bindSym()
    .newCall(
      quote do:
        (
          proc (self: `MA`; f: proc (a: `A`): `MB`): `MB` =
            `ident`(self, f)
        )
    )


func generateAssociativity (
  self: GenericFlatMapperSymbol;
  A, B, MA, MB, MC: NimNode
): NimNode =
  "associativityFlatMappers"
    .bindSym()
    .newCall(
      self.instantiate(MA, A, MB),
      self.instantiate(MB, B, MC),
      self.instantiate(MA, A, MC)
    )



macro instantiateAssociativity* [IMA; IA; IMB](
  instance: FlatMapper[IMA, IA, IMB]{sym};
  A, B, MA, MB, MC: typed
): auto =
  ##[
    Returns a `AssociativityFlatMappers[A, B, MA, MB, MC]` with `instance`
    instantiated for each needed `FlatMapper`.

    `IMA`, `IA`, and `IMB` can be anything.
  ]##
  instance.genericSymbol().generateAssociativity(A, B, MA, MB, MC)


macro instantiateMonadLaws* [IMA; IA; IMB](
  instance: FlatMapper[IMA, IA, IMB]{sym};
  LA, LMA, LMB: typed;
  RT, RM: typed;
  AA, AB, AMA, AMB, AMC: typed
): auto =
  ##[
    Returns a
    `MonadLawsFlatMappers[LA, LMA, LMB, RT, RM, AA, AB, AMA, AMB, AMC]` with
    `instance` instantiated for each needed `FlatMapper`.

    `IMA`, `IA`, and `IMB` can be anything.
  ]##
  let
    symbol = instance.genericSymbol()
    flatMappers = (
      leftId: symbol.instantiate(LMA, LA, LMB),
      rightId: symbol.instantiate(RM, RT, RM),
      assoc: symbol.generateAssociativity(AA, AB, AMA, AMB, AMC)
    )

  "monadLawsFlatMappers"
    .bindSym()
    .newCall(flatMappers.leftId, flatMappers.rightId, flatMappers.assoc)
