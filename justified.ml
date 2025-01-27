module type S = sig
  type 'a map_t
  type key_t

  (* We use the phantom type 'ph to ensure we can only look up
     keys in our map that are proven to exist *) 
  type 'ph key
  type ('ph, 'elt) map

  (* Because we need the phantom type to be filled in with something
     besides a type variable when we actually use `with_map`, but we
     don't care what that type is, we need the compiler to fill in the
     variable, which we do with an existential type.

     The simplest way to create an existential type in OCaml is
     creating a GADT whose type does not carry all the variables in
     its constructor. (The other way involves first-class
     modules. There is also a possible solution using rank N
     polymorphism in a record which contains a function.)

     When the GADT is unwrapped, unique existential types are assigned
     to the unused variables from constructor arguments. You can use
     this in a variety of interesting ways, but here we use use the
     processing of wrapping and unwrapping the type our map simply to
     avoid on one hand having a free type variable in the phantom type
     or having to manually create and fill in concrete types on the
     other. *)
  type _ wrapped =
      Map : ('ph, 'elt) map -> 'elt wrapped

  (* with_map wraps the input map, and unwrapping it creates our
     existential phantom type in the client code. The wrapped map is
     then only used in the context of `f` because existential types
     are not allowed to escape the scope in which they are created.

     In order to return one of our qualified maps or keys, we would
     need unwrapper functions, which are trivially implemented as

     let unwrap_key = Fun.id

     Of course, once unwrapped our maps and keys will no longer carry
     thier proofs. *)
  val with_map : 'elt map_t -> ('elt wrapped -> 'a) -> 'a

  (* if the map contains the key, `mem` returns the key *with
     type-level proof* that it exists in the map. If not, it returns
     None. *)
  val mem : key_t -> ('ph, 'elt) map -> 'ph key option

  (* because our `find` function will only accept keys for maps
     that are proven to contain them, it becomes a total function
     (i.e. it will never raise an exception) without the need to
     return an option type.

     This allows us to validate our input data in a separate step from
     when we act on it. For more information on why you might want to
     do that, see:
     https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/ *)
  val find : 'ph key -> ('ph, 'elt) map -> 'elt
end

module Justified (M: Map.S) :
  S with type key_t := M.key and type 'a map_t := 'a M.t
= struct

  type 'ph key = M.key
  type ('ph, 'elt) map = 'elt M.t
  type _ wrapped =
      Map : ('ph, 'elt) map -> 'elt wrapped

  let with_map map f = f (Map map)

  let find = M.find

  let mem key map =
    match M.mem key map with
    | true -> Some key
    | false -> None
end

module StringMap = Map.Make(String)
module JstringMap = Justified(StringMap)

let () =
  let open JstringMap in
  with_map (StringMap.of_list ["foo", 1; "bar", 2]) @@ fun (Map m1) ->
  with_map (StringMap.of_list ["baz", 3]) @@ fun (Map m2) ->
  match mem "foo" m1 with
  | None -> print_endline "nope"
  | Some foo ->
    Printf.printf "%d\n" (find foo m1);

    (* this is a type error, not a runtime error since m2 wasn't
       proven to contain "foo" *)
    Printf.printf "%d\n" (find foo m2)
