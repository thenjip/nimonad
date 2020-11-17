import std/[sugar]



type
  FlatMapper* [MA; A; MB] = (MA, A -> MB) -> MB



func flatMapper* [MA; A; MB](self: (MA, A -> MB) -> MB): FlatMapper[MA, A, MB] =
  self
