
module R = Relation

(* Some relational lenses *)

(* Helper functions *)

type bias = Left | Right | Both

let incl_left b rcd =
  b rcd = Left || b rcd = Both

let incl_right b rcd =
  b rcd = Right || b rcd = Both

let ( ||~ ) = R.union
let ( &&~ ) = R.inter
let ( --~ ) = R.diff
let ( >>~ ) r f = R.project f r

let rcd_extends r1 r2 =
  List.for_all (fun x -> List.mem x r1) r2

let list_diff l1 l2 =
  List.filter (fun x -> not (List.mem x l2)) l1

let list_inter l1 l2 =
  list_diff l1 (list_diff l1 l2)

let rel_select p rel =
  R.fold
    (fun x r -> if p x then R.insert x r else r)
    rel
    (R.create (R.fields rel))

let rel_join rel1 rel2 =
  let r = R.create (R.fields rel1 @ R.fields rel2) in
  let addall1 rcd r =
    let accum x r =
      let agree = list_inter x rcd in
      let agreeflds = list_inter (fst (List.split x)) (fst (List.split rcd)) in
      if List.length agree = List.length agreeflds then
        R.insert ((list_diff x agree) @ rcd) r
      else
        r
    in
    R.fold accum rel1 r
  in
  R.fold addall1 rel2 r

let ( **~ ) = rel_join

let outer_join d1 d2 r1 r2 =
    let shared_flds = list_inter (R.fields r1) (R.fields r2) in
    let only1 = (((r1 >>~ shared_flds) --~ (r2 >>~ shared_flds)) **~ r1) **~ d1
    and only2 = (((r2 >>~ shared_flds) --~ (r1 >>~ shared_flds)) **~ r2) **~ d2 in
    (r1 **~ r2) ||~ (only1 **~ d1) ||~ (only2 **~ d2)

(* Making lenses and trapping errors *)

let mk_lens opname get put =
  let dom ls =
    `Tree(V.from_list (List.map (fun x -> (x, V.empty)) ls))
  in
  let trap_dom_errors f x y =
    try f x y with
    | R.Unequal_domains(d1, d2) ->
        Lens.error
          [ `String(opname^":")
          ; `Space; dom d1
          ; `Space; `String("is unequal to")
          ; `Space; dom d2
          ]
    | R.Domain_excludes(d, a) ->
        Lens.error
          [ `String(opname^":")
          ; `Space; dom d
          ; `Space; `String("does not include")
          ; `Space; `String(a)
          ]
    | R.Domain_includes(d, a) ->
        Lens.error
          [ `String(opname^":")
          ; `Space; dom d
          ; `Space; `String("already contains")
          ; `Space; `String(a)
          ]
  in
  Lens.native ((trap_dom_errors (fun () -> get)) ()) (trap_dom_errors put)

(* Rename *)

let rename m n =
  let getfun c =
    R.rename m n c
  and putfun a co =
    R.rename n m a
  in
  mk_lens "<relational rename>" getfun putfun

(* Union *)

let union b =
  let getfun (c1, c2) =
    c1 ||~ c2
  and putfun a co =
    let rev_union (c1, c2) =
      let additions = a --~ (c1 ||~ c2) in
      let left = rel_select (incl_left b) additions
      and right = rel_select (incl_right b) additions in
      ((a &&~ c1) ||~ left, (a &&~ c2) ||~ right)
    in
    match co with
    | None -> let empty = R.create (R.fields a) in rev_union (empty, empty)
    | Some(c) -> rev_union c
  in
  mk_lens "<relational union>" getfun putfun

(* Intersection *)

let inter b =
  let getfun (c1, c2) =
    c1 &&~ c2
  and putfun a co =
    let rev_inter (c1, c2) =
      let deletions = (c1 &&~ c2) --~ a in
      let left = rel_select (incl_left b) deletions
      and right = rel_select (incl_right b) deletions in
      ((a ||~ c1) --~ left, (a ||~ c2) --~ right)
    in
    match co with
    | None -> let empty = R.create (R.fields a) in rev_inter (empty, empty)
    | Some(c) -> rev_inter c
  in
  mk_lens "<relational intersect>" getfun putfun

(* Difference *)

let diff b =
  let getfun (c1, c2) =
    c1 --~ c2
  and putfun a co =
    let rev_diff (c1, c2) =
      let deletions = (c1 --~ c2) --~ a in
      let left = rel_select (incl_left b) deletions
      and right = rel_select (incl_right b) deletions in
      ((a ||~ c1) --~ left, (c2 --~ a) ||~ right)
    in
    match co with
    | None -> let empty = R.create (R.fields a) in rev_diff (empty, empty)
    | Some(c) -> rev_diff c
  in
  mk_lens "<relational difference>" getfun putfun

(* Selection *)

(* general predicate on records *)
let select p =
  let getfun c =
    rel_select p c
  and putfun a co =
    let c = match co with None -> R.create (R.fields a) | Some(c) -> c in
    let a' = rel_select p c in
    let added = a --~ a' in
    let removed = a' --~ a in
    (c --~ removed) ||~ added
  in
  mk_lens "<relational select>" getfun putfun

(* Projection *)

let rcd_extends r1 r2 =
  List.for_all (fun x -> List.mem x r1) r2

let list_diff l1 l2 =
  List.filter (fun x -> not (List.mem x l2)) l1

let project p q d =
  let getfun c =
    c >>~ p
  and putfun a co =
    let c = match co with None -> R.create (R.fields a) | Some(c) -> c in
    if false then begin
      prerr_endline "*** BEGIN PROJECT DEBUGGING ***";
      prerr_endline "Abstract view:";
      R.dump_stderr a;
      prerr_endline "Concrete view:";
      R.dump_stderr c;
      prerr_endline "Calculated abstract view:";
      R.dump_stderr (R.project p c);
      prerr_endline "**** END PROJECT DEBUGGING ****";
    end;
    if R.equal a (c >>~ p) then
      c
    else
      let compflds = (list_diff (R.fields c) p) @ q in
      let comp = c >>~ compflds in
      let newkeys = (a >>~ q) --~ (c >>~ q) in
      let additions = newkeys **~ d in
      a **~ (comp ||~ additions)
  in
  mk_lens "<relational project>" getfun putfun

(* Inner Join *)

let ijoin b =
  let getfun (c1, c2) =
    c1 **~ c2
  and putfun a co =
    let empty_abs = R.create (R.fields a) in
    let rev_join (c1, c2) =
      let lflds = R.fields c1
      and rflds = R.fields c2 in
      let shflds = list_inter lflds rflds in
      let additions =
        (* records that were inserted into the abstract view *)
        a --~ (c1 **~ c2)
      in
      let mod_left =
        (* a projection on the shared fields of the records in the left
         * concrete table that should be modified based upon additions in the
         * abstract view *)
        (additions >>~ shflds) &&~ (c1 >>~ shflds)
      and mod_right =
        (* a projection on the shared fields of the records in the right
         * concrete table that should be modified based upon additions in the
         * abstract view *)
        (additions >>~ shflds) &&~ (c2 >>~ shflds)
      in
      let add_left =
        (* records that should be added to the left concrete table *)
        additions >>~ lflds
      and add_right =
        (* records that should be added to the right concrete table *)
        additions >>~ rflds
      in
      let deletions =
        (* records that were removed from the abstract view *)
        (c1 **~ c2) --~ a
      in
      let del_left =
        (* records that should be removed from the left concrete table *)
        ((rel_select (incl_left b) deletions) >>~ lflds) ||~
          (mod_left **~ c1)
      and del_right =
        (* records that should be removed from the right concrete table *)
        ((rel_select (incl_right b) deletions) >>~ rflds) ||~
          (mod_right **~ c2) in
      ((c1 --~ del_left) ||~ add_left,
       (c2 --~ del_right) ||~ add_right)
    in
    match co with
    | None -> rev_join (empty_abs, empty_abs)
    | Some(c) -> rev_join c
  in
  mk_lens "<relational inner join>" getfun putfun

(* Outer Join *)

let ojoin dl dr pl pr b =
  let ( ***~ ) = outer_join dl dr in
  let getfun (c1, c2) =
    c1 ***~ c2
  and putfun a co =
    let empty_abs = R.create (R.fields a) in
    let rev_join (c1, c2) =
      let lflds = R.fields c1
      and rflds = R.fields c2 in
      let shflds = list_inter lflds rflds in
      let additions =
        (* records that were inserted into the abstract view *)
        a --~ (c1 ***~ c2)
      in
      let may_add_left = additions &&~ ((additions >>~ rflds) **~ dr)
      and may_add_right = additions &&~ ((additions >>~ lflds) **~ dl) in
      let must_add_one = may_add_left &&~ may_add_right in
      let must_add_left = additions --~ may_add_left
      and must_add_right = additions --~ may_add_right in
      let add_left =
        (* records that should be added to the left concrete table *)
        (must_add_left ||~
          ((rel_select pl may_add_left) ||~
            (rel_select (incl_left b) must_add_one))) >>~ lflds
      and add_right =
        (* records that should be added to the right concrete table *)
        (must_add_right ||~
          ((rel_select pr may_add_right) ||~
            (rel_select (incl_right b) must_add_one))) >>~ rflds
      in
      ((c1 &&~ (a >>~ lflds)) ||~ add_left,
       (c2 &&~ (a >>~ rflds)) ||~ add_right)
    in
    match co with
    | None -> rev_join (empty_abs, empty_abs)
    | Some(c) -> rev_join c
  in
  mk_lens "<relational outer join>" getfun putfun

