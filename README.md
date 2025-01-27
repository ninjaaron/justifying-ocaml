# justifying-ocaml
A proof-of-concept for justified containers in OCaml

I was looking at techiques for creating types OCaml that could prove
something about their values, inspired by
[Parse, Don't Validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/),
and in the process of reading more, I found the Haskell package
[justified-containers](https://github.com/matt-noonan/justified-containers),
Which creates proofs that certain keys exist in certain maps, which
can then be used for error-free access to those maps. The link also
contains more information on why you might want that.

I set out to try to do the same thing in OCaml, since, generally
speaking, anything you can do with Haskell, you can do in OCaml with a
little more typing. One interesting thing about this code is that it
uses a GADT solely to create an existential type.

The code is in `justified.ml`. It's very short and has a lot of comments.
