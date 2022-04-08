import pkg/funcynim/[into, variables, unit]

import std/[sugar]



proc addAndReturn* [T; R](self: var seq[T]; item: T; returned: R): R =
  self
    .modify(proc (s: var seq[T]): Unit = s.add(item))
    .into(_ => returned)
