(****************************************************************)
(* The Harmony Project                                          *)
(* harmony@lists.seas.upenn.edu                                 *)
(*                                                              *)
(* sync.ml - Core synchronizer                                  *)
(****************************************************************)
(* $Id *)

(* BCP: We package the body of this module in another module, Internal,
   so that we can make it recursive with the D3 module defined at the end of
   the file (e.g., so that the action type and the D3.action type can refer to
   each other recursively). *)
module rec Internal :
  sig
    type action
    val equal: action
    val has_conflict: action -> bool
    val format_action: action -> unit
    val sync : Schema.t
            -> (V.t option * V.t option * V.t option)
            -> action * V.t option * V.t option * V.t option
  end = struct

let diff3 = Prefs.createBool "diff3" true
  "Use diff3 algorithm to synchronize lists"
  "Use diff3 algorithm to synchronize lists"

let debug = Trace.debug "sync"

type copy_value =
  | Adding of V.t
  | Deleting of V.t
  | Replacing of V.t * V.t

type action =
  | SchemaConflict of Schema.t * V.t * V.t 
  | MarkEqual
  | DeleteConflict of V.t * V.t
  | CopyLeftToRight of copy_value
  | CopyRightToLeft of copy_value
  | ListSync of D3.action
  | ListConflict of V.t * V.t
  | GoDown of action Name.Map.t

let equal = MarkEqual

let rec has_conflict a = 
  match a with
      SchemaConflict _ | DeleteConflict _  -> true
    | MarkEqual | CopyLeftToRight _ | CopyRightToLeft _ -> false
    | ListSync a -> D3.has_conflict a 
    | ListConflict _ -> true
    | GoDown(m) -> Name.Map.fold 
	(fun k a' c -> c || has_conflict a')
        m false

let format_copy s = function
  | Adding v ->
     V.format_msg [`Open_box; `String "Add ("; `String s; `String ")";
                   `SpaceOrIndent; `Tree v; `Close_box]
  | Deleting v ->
     V.format_msg [`Open_box; `String "Delete ("; `String s; `String ")";
                   `SpaceOrIndent; `Tree v; `Close_box]
  | Replacing (vold,vnew) ->
     V.format_msg [`Open_box; `String "Replace ("; `String s; `String ")";
                   `SpaceOrIndent; `Tree vold; `Space; `String "with";
                   `SpaceOrIndent; `Tree vnew; `Close_box]
	
let format_schema_conflict t lv rv =
  V.format_msg ([`Open_vbox
                ; `String "[SchemaConflict] at type "
                ; `Prim (fun () -> Schema.format_t t)
                ; `Break; `Tree lv; `Break; `Tree rv
                ; `Close_box] )
  
let format_list_conflict lv rv =
  V.format_msg ([`Open_vbox
     ; `String "List conflict (synchronizing a list with a non-list) between"
     ; `Break; `Tree lv; `Space; `String "and"; `Space; `Tree rv
     ; `Close_box] )

let rec format_raw = function
  | SchemaConflict (t,lv,rv) ->
      format_schema_conflict t lv rv
  | GoDown(m) ->
      Name.Map.dump (fun ks -> ks) Misc.whack
        (fun x -> format_raw x)
        (fun _ -> false)
        m
  | MarkEqual -> Format.printf "EQUAL"
  | DeleteConflict (v0,v) ->
      Format.printf "DELETE CONFLICT@,  @[";
      V.show_diffs v0 v;
      Format.printf "@]@,"
  | ListSync a -> D3.format_action a
  | ListConflict (lv,rv) -> format_list_conflict lv rv
  | CopyLeftToRight c -> format_copy "-->" c
  | CopyRightToLeft c -> format_copy "<--" c

let is_cons m = 
  let dom_m = Name.Map.domain m in
     Name.Set.mem V.hd_tag dom_m 
  || Name.Set.mem V.tl_tag dom_m 

let list_tags =
  Safelist.fold_right
    Name.Set.add
    [V.hd_tag; V.tl_tag; V.nil_tag]
    Name.Set.empty

let rec format_pretty = function
  | SchemaConflict (t,lv,rv) ->
      format_schema_conflict t lv rv
  | GoDown(m) ->
      if is_cons m then begin
        (* Special case for lists *)
        Format.printf "[@[<hv0>";
        format_cons 0 m
      end else begin
        (* Default case *)
        let prch (n,ch) = 
          let prf() =
              Format.printf "@["; format_pretty ch; Format.printf "@]" in
          Format.printf "@[<hv1>%s =@ " (Misc.whack n);
          prf();
          Format.printf "@]" in
        Format.printf "{@[<hv0>";
        let binds = Safelist.map (fun k -> (k, Name.Map.find k m))
                      (Name.Set.elements (Name.Map.domain m)) in
        let binds = Safelist.filter (fun (k,e) -> e <> MarkEqual) binds in
        (* Here, we should check for a replacement and treat it special! *)
        Misc.iter_with_sep
          prch
          (fun()-> Format.printf ","; Format.print_break 1 0)
          binds;
        Format.printf "@]}"
      end 
  | MarkEqual ->
      (* By construction, this case can only be invoked at the root *)
      Format.printf "EQUAL"
  | DeleteConflict (v0,v) ->
      Format.printf "DELETE CONFLICT@,  @[";
      V.show_diffs v0 v;
      Format.printf "@]@,"
  | CopyLeftToRight c -> format_copy "-->" c
  | CopyRightToLeft c -> format_copy "<--" c
  | ListSync a -> D3.format_action a
  | ListConflict (lv,rv) -> format_list_conflict lv rv
      
(* BCP: This can be deleted after we commit to the new list sync stuff *)
and format_cons equal_hd_count m =
  let dump_hd_count n =
    if n = 0 then ()
    else if n = 1 then Format.printf "..." 
    else Format.printf "...(%d)..." n in
  let hd_action = (try Name.Map.find V.hd_tag m with Not_found -> MarkEqual) in
  let tl_tag =
    begin
      try Name.Set.choose (Name.Set.diff (Name.Map.domain m) list_tags)
      with Not_found -> V.tl_tag 
    end in
  let tl_action = (try Name.Map.find tl_tag m with Not_found -> MarkEqual) in
  let hd_interesting = (hd_action <> MarkEqual) in
  let tl_interesting =
    (match tl_action with GoDown m -> not (is_cons m)
                        | _ -> true) in
  begin (* format the head and/or an appropriate separator, as needed *)
    match (hd_interesting, tl_interesting) with
    | true,true -> if equal_hd_count > 0 then (dump_hd_count equal_hd_count; Format.printf ",@ ");
                   format_pretty hd_action; Format.printf ";@ "
    | false,true -> dump_hd_count (equal_hd_count+1); Format.printf ";@ ";
    | true,false -> if equal_hd_count > 0 then (dump_hd_count equal_hd_count; Format.printf ",@ ");
                    format_pretty hd_action; Format.printf ",@ "
    | false,false -> ()
  end;
  match tl_action with
  | GoDown(m) -> format_cons (if hd_interesting then 0 else equal_hd_count+1) m
  | MarkEqual -> Format.printf "...]@]"
  | a -> format_pretty a; Format.printf "]@]"

let format_action v =
  if Prefs.read V.raw then format_raw v
  else format_pretty v

(*********************************************************************************)

(* accumulate adds a binding for a tree option to an accumulator *)
let accumulate oldacc k = function
    None -> oldacc
  | Some v -> (k, v) :: oldacc

let the = function None -> assert false | Some x -> x

let combine_conflicts c1 c2 = match (c1,c2) with
    (`NoConflict, `NoConflict) -> `NoConflict
  | _ -> `Conflict

let assert_member v t = 
  if (not (Schema.member v t)) then begin 
    Lens.error [`String "Synchronization error: "; `Break ; `Tree v; `Break
               ; `String " does not belong to "; `Break
               ; `Prim (fun () -> Schema.format_t t)]
  end 

let rec sync s (oo, ao, bo) = 
  match (oo, ao, bo) with
    | _, None, None       ->
        (MarkEqual, None, None, None)
    | None, None, Some rv -> 
        assert_member rv s;
        (CopyRightToLeft (Adding rv), Some rv, Some rv, Some rv)
    | None, Some lv, None -> 
        assert_member lv s; 
        (CopyLeftToRight (Adding lv), Some lv, Some lv, Some lv)
    | Some arv, None, Some rv ->
        assert_member rv s;
        if V.included_in rv arv then 
          (CopyLeftToRight (Deleting rv), None, None, None)
        else 
          (DeleteConflict(arv,rv), oo, ao, bo)
    | Some arv, Some lv, None ->
        assert_member lv s;
        if V.included_in lv arv then 
          (CopyRightToLeft (Deleting lv), None, None, None)
        else 
          (DeleteConflict(arv,lv), oo, ao, bo)
    | _, Some lv, Some rv ->
        assert_member lv s;
        assert_member rv s;
        (* BCP [Oct 05]: The following test could give us a nasty
           n^2 behavior in deep (and narrow) trees. *)
        if V.equal lv rv then begin
          (MarkEqual, Some lv, Some lv, Some rv)
        (* BCP [Apr 06]: The next tests are potentially nasty too!  And the
           test for V.hd_tag is a hack that should be removed, if possible. *)
        end else if Name.Set.is_empty (Name.Set.inter
                                        (Name.Set.remove V.hd_tag (V.dom lv))
                                        (Name.Set.remove V.hd_tag (V.dom rv)))
             && oo <> None
             && (V.equal (the oo) lv || V.equal (the oo) rv) then 
          if V.equal (the oo) lv then 
            (CopyRightToLeft (Replacing (lv,rv)), Some rv, Some rv, Some rv)
          else 
            (CopyLeftToRight (Replacing (rv,lv)), Some lv, Some lv, Some lv)
        else if V.is_list lv && V.is_list rv && Prefs.read diff3 then 
          (* Call the diff3 module to handle list sync: *)
          let ll = V.list_from_structure lv in
          let rl = V.list_from_structure rv in
          let ol = match oo with
                     None -> []
                   | Some ov ->
                       if V.is_list ov then V.list_from_structure ov else [] in
          let elt_schema =
            (* BCP: Following line is bogus -- assumes that all lists are
               homogeneous and just takes the type of the first element as the
               type of all elements.  But what, exactly, should we do instead?? *)
            match Schema.project s V.hd_tag with
              None -> assert false (* Not a list schema? *)
            | Some ss -> ss in
          let (a,ol',ll',rl') = D3.sync elt_schema (ol,ll,rl) in
          (ListSync a,
           Some (V.structure_from_list ol'),
           Some (V.structure_from_list ll'),
           Some (V.structure_from_list rl'))
        else if (V.is_list lv || V.is_list rv) && Prefs.read diff3 then 
          (ListConflict (lv,rv), oo, ao, bo)
        else
          let lrkids = Name.Set.union (V.dom lv) (V.dom rv) in
          let acts, arbinds, lbinds, rbinds =            
            Name.Set.fold
              (fun k (actacc, aracc, lacc, racc) ->
                 let tk = match Schema.project s k with
                     None ->
                       (* Can't happen, since every child k is in        *)
                       (* either dom(a) or dom(b), both of which are in  *)
                       (* T, as we just checked. For debugging, here's a *)
                       (* helpful error message:                         *)
                       Lens.error [`String "synchronization bug: type "
                             ; `Prim (fun () -> Schema.format_t s)
                             ; `String " cannot be projected on "; `String k]
                   | Some tk -> tk   in
                 let act, o', a', b' =
                   sync 
                     tk
                     ((match oo with None -> None | Some av -> V.get av k),
                      (V.get lv k),
                      (V.get rv k)) in  
                 let aracc = accumulate aracc k o' in
                 let lacc  = accumulate lacc k a' in
                 let racc  = accumulate racc k b' in
                 ((k, act)::actacc, aracc, lacc, racc))
              lrkids 
              ([], [], [], [])   in
          let o',a',b' = 
            (V.from_list arbinds),
            (V.from_list lbinds),
            (V.from_list rbinds)   in
          let a'_in_tdoms = Schema.dom_member a' s in
          let b'_in_tdoms = Schema.dom_member b' s in
          if a'_in_tdoms && b'_in_tdoms then
              (GoDown(Safelist.fold_left
                        (fun acc (k, act) -> Name.Map.add k act acc)
                        Name.Map.empty
                        acts),
               Some o', Some a', Some b')
          else 
            (SchemaConflict(s,lv,rv),oo,ao,bo)

end (* module Internal *)

and D3Args : Diff3.DIFF3ARGS with type elt = V.t
= struct
  type elt = V.t
  type action = Internal.action
  let has_conflict = Internal.has_conflict
  let format_action = Internal.format_action                       
  let eqv = V.equal
  let format = V.format_t
  let tostring = V.string_of_t
  let sync = Internal.sync
end

and D3 : Diff3.DIFF3RES with type elt = V.t =
Diff3.Make(D3Args)

(* Extract top-level definitions from the Internal module and re-export *)
type action = Internal.action
let sync = Internal.sync
let format_action = Internal.format_action
let has_conflict = Internal.has_conflict
let equal = Internal.equal

