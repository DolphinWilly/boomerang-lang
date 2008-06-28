(*******************************************************************************)
(* The Harmony Project                                                         *)
(* harmony@lists.seas.upenn.edu                                                *)
(*******************************************************************************)
(* Copyright (C) 2007-2008                                                     *)
(* J. Nathan Foster and Benjamin C. Pierce                                     *)
(*                                                                             *)
(* This library is free software; you can redistribute it and/or               *)
(* modify it under the terms of the GNU Lesser General Public                  *)
(* License as published by the Free Software Foundation; either                *)
(* version 2.1 of the License, or (at your option) any later version.          *)
(*                                                                             *)
(* This library is distributed in the hope that it will be useful,             *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of              *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU           *)
(* Lesser General Public License for more details.                             *)
(*******************************************************************************)
(* /boomerang/src/brx.ml                                                       *)
(* Boomerang RegExp engine                                                     *)
(* $Id$ *)
(*******************************************************************************)

(* This code is based on a similar module Jerome Vouillon wrote for
   Unison. *)

(* --------------------- CONSTANTS / HELPERS --------------------- *)

(* debugging *)
let dbg thk = Trace.debug "brx+" thk
let sdbg s = Trace.debug "brx+" (fun () -> Util.format "%s" s)

let () = Format.set_margin 300

let string_of_char_code n = String.make 1 (Char.chr n) 
	   
(* ASCII alphabet *)
let min_code = 0
let max_code = 255

(* --------------------- PRETTY PRINTING --------------------- *)
(* ranks: used to determine when parentheses are needed. *)
type r = 
  | Urnk (* union *)
  | Drnk (* diff *)
  | Irnk (* inter *)
  | Crnk (* concat *)
  | Srnk (* star *)
  | Arnk (* atomic *)

let lpar r1 r2 = match r1,r2 with
  | Arnk, _ -> false
  | _, Arnk -> false
  | Srnk, _ -> false
  | _, Srnk -> true
  | Crnk, _ -> false
  | _, Crnk -> true
  | Irnk, _ -> false
  | _, Irnk -> true
  | Urnk, Drnk
  | Drnk, Urnk -> true
  | Drnk, Drnk -> false
  | Urnk, Urnk -> false
      
let rpar r1 r2 = match r1,r2 with
  | Arnk, _ -> false
  | _, Arnk -> false
  | Srnk, _ -> false
  | _, Srnk -> true
  | Crnk, _ -> false
  | _, Crnk -> true
  | Irnk, _ -> false
  | _, Irnk -> true
  | Urnk, Drnk
  | Drnk, Urnk -> true
  | Drnk, Drnk -> true
  | Urnk, Urnk -> true

(* --------------------- CHARACTER SETS --------------------- *)
module CharSet : 
sig
  type p = int * int 
  type t = p list
  val union : t -> t -> t
  val add : p -> t -> t
  val inter : t -> t -> t
  val negate : int -> int -> t -> t
  val diff : t -> t -> t
  val mem : int -> t -> bool
end = struct
  type p = int * int 
  type t = p list
  let rec union l1 l2 = match l1,l2 with
    | _,[] -> l1
    | [],_ -> l2
    | (c1,c2)::r1,(d1,d2)::r2 -> 
        if succ c2 < d1 then 
          (c1,c2)::union r1 l2
        else if succ d2 < c1 then 
          (d1,d2)::union l1 r2
        else if c1 < d2 then 
          union r1 ((min c1 d1,d2)::r2)
        else 
          union ((min c1 d1,c2)::r1) r2

  let add p1 l1 = union [p1] l1

  let rec inter l1 l2 = match l1, l2 with
    | _, [] -> []
    | [], _ -> []
    | (c1, c2)::r1, (d1, d2)::r2 ->
        if c2 < d1 then
          inter r1 l2
        else if d2 < c1 then
          inter l1 r2
        else if c2 < d2 then
          (max c1 d1, c2)::inter r1 l2
        else
          (max c1 d1, d2)::inter l1 r2
            
  let rec negate mi ma l = match l with
    | [] ->
        if mi <= ma then [(mi, ma)] else []
    | (c1, c2)::r ->  
        if ma < c1 then 
          if mi <= ma then [(mi, ma)] else []
        else if  mi < c1 then
          (mi, c1 - 1)::negate c1 ma l
        else (* i.e., c1 <= mi *) 
          negate (max mi (c2 + 1)) ma r 

  let diff l1 l2 = 
    inter l1 (negate min_code max_code l2)

  let mem c l = 
    Safelist.exists (fun (c1,c2) -> c1 <= c && c <= c2) l 
end

(* --------------------- REGULAR EXPRESSIONS --------------------- *)
(* we use a recursive module because t uses Q.ts in representative *) 
type d = 
  | Anything
  | Empty
  | Epsilon
  | CSet of CharSet.t
  | Alt of t * t list
  | Seq of t * t
  | Star of t
  | Inter of t * t list
  | Diff of t * t
and t = 
    { uid                        : int;
      desc                       : d;
      hash                       : int;
      size                       : int;
      final                      : bool;
      (* lazily computed *)     
      mutable maps               : (int array * int array * int) option;
      mutable reverse            : t option;
      mutable representative     : (string option) option;
      mutable suffs              : t option;
      (* operations *)           
      mutable derivative         : int -> t }

type this_t = t 

let compare_t t1 t2 = compare (t1.uid,t1.size) (t2.uid,t2.size)

module Q = Set.Make(
  struct
    type t = this_t
    let compare t1 t2 = compare_t t1 t2
  end)

module P = Set.Make(
  struct 
    type t = this_t * (string * this_t) list 
    let compare (ti,_) (tj,_) = 
      let c1 = ti.size - tj.size in 
      if c1 = 0 then c1 else (ti.uid - tj.uid)
  end)
      
(* --------------------- PRETTY PRINTING --------------------- *)
let rank t0 = match t0.desc with
  | Anything -> Arnk
  | Empty    -> Arnk
  | Epsilon  -> Arnk
  | CSet _   -> Arnk
  | Star _   -> Srnk
  | Seq _    -> Crnk
  | Alt _    -> Urnk 
  | Inter _  -> Irnk
  | Diff _   -> Drnk 

let tag_of_t t = 
  let rec aux b t =
  match t.desc with
  | Anything -> "Anything"
  | Empty    -> "Empty"
  | Epsilon  -> "Epsilon"
  | CSet _   -> "CSet"
  | Star _   -> "Star"
  | Seq _    -> "Seq"
  | Alt _    -> "Alt" 
  | Inter(t1,tl)  -> if b then "Inter[" ^ Misc.concat_list "," (Safelist.map (aux false) (t1::tl)) ^ "]" else "Inter"
  | Diff _   -> "Diff" in 
  aux true t

let rec format_t t0 = 
  let format_char_code n = Util.format "%s" (Misc.whack (string_of_char_code n)) in 
  let format_char_code_pair (n1,n2) = 
    if n1=n2 then format_char_code n1 
    else (format_char_code n1; Util.format "-"; format_char_code n2) in 

  let maybe_wrap = Bprint.maybe_wrap format_t in

  let rec format_list sep rnk ri resti = 
    Util.format sep;
    match resti with 
      | [] -> 
          maybe_wrap (rpar (rank ri) rnk) ri
      | rj::restj -> 
          maybe_wrap (lpar (rank ri) rnk || rpar (rank ri) rnk) ri;
          format_list sep rnk rj restj in 
    
    match t0.desc with
      | Anything -> Util.format "@[ANYTHING@]"
      | Empty -> Util.format "@[NADA@]"
      | CSet [p1] -> 
          let n1,n2 = p1 in 
            Util.format "@[";
            if n1=min_code && n2=max_code then 
              Util.format "[.]"
            else if n1=n2 then 
              (Util.format "'";
               format_char_code n1;
               Util.format "'")
            else 
              (Util.format "[";
               format_char_code_pair p1;
               Util.format "]");
            Util.format "@]"
      | CSet cs -> 
          let ns = CharSet.negate min_code max_code cs in
          let p,l = 
            if Safelist.length ns < Safelist.length cs 
            then ("^",ns)
            else ("",cs) in           
            Util.format "@[[%s" p;
            Misc.format_list "" format_char_code_pair l;
            Util.format "]@]"
      | Epsilon -> 
          Util.format "@[EPSILON@]"
      | Seq (t1,t2) -> 
	  Util.format "@[";
	  maybe_wrap (lpar (rank t1) Crnk) t1;
	  Util.format ".";
	  maybe_wrap (rpar (rank t2) Crnk) t2;
	  Util.format "@]"
      | Alt (t1,[]) -> 
          format_t t1
      | Alt (t1,t2::rest) ->
          Util.format "@[";
          maybe_wrap (lpar (rank t1) Urnk) t1;
          format_list "@,|" Urnk t2 rest;
          Util.format "@]"
      | Star(t1) -> 
          Util.format "@[";
          maybe_wrap (lpar (rank t1) Srnk) t1;
          Util.format "*@,";
          Util.format "@]"
      | Inter(t1,[]) -> 
          format_t t1
      | Inter (t1,t2::rest) ->
          Util.format "@[";
          maybe_wrap (lpar (rank t1) Irnk) t1;
          format_list "@,&" Urnk t2 rest;
          Util.format "@]"
      | Diff(t1,t2) -> 
          Util.format "@[{";
          maybe_wrap (lpar (rank t1) Drnk) t1;
          Util.format "@,-";
          maybe_wrap (lpar (rank t2) Drnk) t2;
          Util.format "}@]"
            
let string_of_t t0 = 
  Util.format_to_string (fun () -> format_t t0)

let size_of_t t = t.size 
let compare_size (t1,_) (t2,_) = t1.size - t2.size

(* --------------------- HASH CONS CACHES --------------------- *)
module MapCache = Map.Make(
  struct
    type t = (int * int list)
    let rec compare (h1,l1) (h2,l2) = 
      let rec aux l1 l2 = match l1,l2 with
        | [],[] -> 0
        | _,[]  -> 1
        | [],_  -> -1
        | h1::rest1,h2::rest2 -> 
            let c1 = h1 - h2 in 
            if c1 <> 0 then c1
            else aux rest1 rest2 in 
      aux (h1::l1) (h2::l2)
  end)

module ICache = Hashtbl.Make
  (struct 
     type t = int
     let hash x = Hashtbl.hash x
     let equal (x:int) (y:int) = x=y
   end)

module CSCache = Hashtbl.Make
  (struct
     type t = CharSet.t 
     let hash cs1 = Hashtbl.hash cs1
     let equal cs1 cs2 = cs1 = cs2
   end)

module TCache = Hashtbl.Make
  (struct
     type t = this_t
     let hash t = t.hash
     let equal t1 t2 = t1.uid = t2.uid
   end)

module TTCache = Hashtbl.Make
  (struct 
     type t = this_t * this_t
     let hash (t1,t2) = (883 * t1.hash + 859 * t2.hash)
     let equal (t11,t12) (t21,t22) = t11.uid = t21.uid && t12.uid = t22.uid
   end)

module TLCache = Hashtbl.Make
  (struct
     type t = this_t list
     let hash tl = Safelist.fold_left (fun h ti -> h + 883 * ti.hash) 0 tl
     let rec equal tl1 tl2 = match tl1,tl2 with 
       | h1::rest1,h2::rest2 -> 
	   h1.uid = h2.uid && equal rest1 rest2
       | [],[] -> true
       | _ -> false
   end)

let mcache : (int array * int array * int) MapCache.t ref = ref MapCache.empty
let cset_cache : t CSCache.t = CSCache.create 131
let neg_cset_cache : t CSCache.t = CSCache.create 131
let star_cache : t TCache.t = TCache.create 131
let seq_cache : t TTCache.t = TTCache.create 131
let alt_cache : t TTCache.t = TTCache.create 131
let inter_cache : t TTCache.t = TTCache.create 131
let diff_cache : t TTCache.t = TTCache.create 131
let seqs_cache : t TLCache.t = TLCache.create 131
let alts_cache : t TLCache.t = TLCache.create 131
let inters_cache : t TLCache.t = TLCache.create 131

(* --------------------- DESC OPERATIONS --------------------- *)
let desc_hash = function
  | Anything     -> 181
  | Empty        -> 443
  | Epsilon      -> 1229
  | CSet(cs)     -> 
      let rec aux = function
        | [] -> 0
        | (i,j)::r -> i + 13 * j + 257 * aux r in 
      aux cs land 0x3FFFFFFF
  | Alt(t1,tl)   -> 199 * Safelist.fold_left (fun h ti -> h + 883 * ti.hash) 0 (t1::tl)
  | Seq(t1,t2)   -> 821 * t1.hash + 919 * t2.hash
  | Inter(t1,tl) -> 71 * Safelist.fold_left (fun h ti -> h + 883 * ti.hash) 0 (t1::tl)
  | Diff(t1,t2)  -> 379 * t1.hash + 563 * t2.hash
  | Star(t1)     -> 197 * t1.hash

let desc_size = function
  | Anything     -> 1
  | Empty        -> 1
  | Epsilon      -> 1
  | CSet(cs)     -> 1
  | Alt(t1,tl)   -> Safelist.fold_left (fun s ti -> s + ti.size) 0 (t1::tl) + 1
  | Seq(t1,t2)   -> t1.size + t2.size + 1
  | Inter(t1,tl) -> Safelist.fold_left (fun s ti -> s * ti.size) 1 (t1::tl) + 1
  | Diff(t1,t2)  -> t1.size * t2.size + 1
  | Star(t1)     -> t1.size + 1

let desc_final = function
  | Anything     -> true
  | Empty        -> false
  | Epsilon      -> true
  | CSet _       -> false
  | Star _       -> true
  | Seq(t1,t2)   -> t1.final && t2.final
  | Alt(t1,tl)   -> t1.final || Safelist.exists (fun ti -> ti.final) tl
  | Inter(t1,tl) -> t1.final && Safelist.for_all (fun ti -> ti.final) tl
  | Diff(t1,t2)  -> t1.final && not t2.final

(* character maps (hash consed) *)
let desc_maps d0 = 
  let rec split m cs = match cs with
    | [] -> ()
    | (c1,c2)::rest ->
        m.(c1) <- true;
        m.(succ c2) <- true;
        split m rest in
  let rec desc_colorize m d = match d with
    | Anything     -> ()
    | Empty        -> ()
    | Epsilon          -> ()
    | CSet cs      -> split m cs
    | Star(t1)     -> colorize m t1
    | Seq(t1,t2)   -> colorize m t1; if t1.final then colorize m t2
    | Alt(t1,tl)   -> colorize m t1; Safelist.iter (colorize m) tl
    | Inter(t1,tl) -> colorize m t1; Safelist.iter (colorize m) tl
    | Diff(t1,t2)  -> colorize m t1; colorize m t2 
  and colorize m t = desc_colorize m t.desc in
  let key_of_map m =
    let ws = 31 in
    let rec loop i mask cont a1 al =
      if i > max_code then (a1::al)
      else if cont && i mod ws = 0 then
        loop i 1 false 0 (a1::al)
      else
        let mask' = mask lsl 1 in
        let a1' = if m.(i) then mask lor a1 else a1 in
          loop (succ i) mask' true a1' al in
    let l = loop 0 1 false 0 [] in 
    (Hashtbl.hash l,l) in 
  let flatten m = 
    let km = key_of_map m in
    try MapCache.find km !mcache 
    with Not_found ->
      let cm = Array.make (succ max_code) 0 in 
      let rec loop i nc rml = 
        if i > max_code then Safelist.rev rml
        else
          let nc' = if m.(i) then succ nc else nc in 
          let rml' = if m.(i) then i::rml else rml in 
            (cm.(i) <- nc';
             loop (succ i) nc' rml') in 
      let rml = loop 1 0 [0] in
      let rm = Array.of_list rml in 
      let len = Array.length rm in 
      let ms = (cm,rm,len) in
        mcache := MapCache.add km ms !mcache;
        ms in 
  let m = Array.make (succ (succ max_code)) false in 
    desc_colorize m d0;
    flatten m

(* --------------------- CONSTRUCTORS --------------------- *)
let uid_counter = ref 0 
let next_uid () = 
  incr uid_counter;
  !uid_counter

let install upd f = 
  (fun args -> 
     let v = f args in 
     upd (fun _ -> v); 
     v)

let dummy_impl _ = assert false  

let mk_constant d t_nexto t_repo = 
  let t = 
    { uid = next_uid ();
      desc = d;
      hash = desc_hash d;
      size = 1;
      final = desc_final d;
      maps = Some (desc_maps d);
      reverse = None;
      representative = Some t_repo;
      suffs = None;
      derivative = dummy_impl; } in 
  let t_next = match t_nexto with 
    | None -> t 
    | Some t' -> t' in 
  (* backpatch *)
  t.reverse <- Some t;
  t.suffs <- Some t;
  t.derivative <- (fun c -> t_next);  
  t

(* CONSTANTS *)
let empty    = mk_constant Empty    None         None     
let anything = mk_constant Anything None         (Some "")
let epsilon  = mk_constant Epsilon  (Some empty) (Some "")

let force vo set f x = match vo with 
  | Some v -> v 
  | None -> 
      let v = f x in
      set v; 
      v 

(* GENERIC CONSTRUCTOR *)
let rec mk_t d0 = 
  let t0 = 
    { uid = next_uid ();
      desc = d0;
      hash = desc_hash d0;
      size = desc_size d0;
      final = desc_final d0;      
      maps = None;
      reverse = None;
      representative = None;
      suffs = None;
      derivative = dummy_impl } in 

  (* derivative *)
  let derivative_impl = 
    let mk_table f = 
      let fr = ref f in 
      let diff_cache : t ICache.t = ICache.create 7 in
      (fun c ->
         try ICache.find diff_cache c with Not_found ->
           let r = !fr c in
           ICache.add diff_cache c r;
           r) in
(*       let cm,_,len = get_maps t0 in *)
(*       let tr : (t option) array = Array.make len None in *)
(*       (fun c -> *)
(*          let i = cm.(c) in *)
(*          match tr.(i) with *)
(*          | None -> *)
(*              let r = !fr c in *)
(*              tr.(i) <- Some r; *)
(*              r *)
(*          | Some tc -> tc) in *)

    match d0 with 
      | Anything -> (fun c -> t0)
      | Empty    -> (fun c -> t0)
      | Epsilon  -> (fun c -> empty)
      | CSet s   -> 
          mk_table 
            (fun c -> if CharSet.mem c s then epsilon else empty)
      | Seq(t1,t2) ->
          mk_table
            (fun c -> 
	       let t12 = mk_seq (t1.derivative c) t2 in 
	       if t1.final then mk_alt t12 (t2.derivative c)
	       else t12)
      | Alt (t1,tl) -> 
          mk_table
            (fun c -> mk_alts (Safelist.map (fun ti -> ti.derivative c) (t1::tl)))
      | Star(t1) -> 
          mk_table
            (fun c -> mk_seq (t1.derivative c) (mk_star t0))
      | Inter(t1,tl) ->
          mk_table 
            (fun c -> mk_inters (Safelist.map (fun ti -> ti.derivative c) (t1::tl)))
      | Diff(t1,t2) -> 
          mk_table 
            (fun c -> mk_diff (t1.derivative c) (t2.derivative c)) in 

  (* backpatch t0 with implementations of derivative *)  
  t0.derivative <- derivative_impl;
  t0

and get_maps t = force t.maps (fun v -> t.maps <- Some v) desc_maps t.desc  

and calc_reverse t = match t.desc with 
  | Anything     -> t
  | Empty        -> t
  | Epsilon      -> t
  | CSet _       -> t
  | Seq(t1,t2)   -> mk_seq (get_reverse t2) (get_reverse t1)
  | Alt(t1,tl)   -> mk_alts (Safelist.map get_reverse (t1::tl))
  | Star(t1)     -> mk_star (get_reverse t1)
  | Inter(t1,tl) -> mk_inters (Safelist.map get_reverse (t1::tl))
  | Diff(t1,t2)  -> mk_diff (get_reverse t1) (get_reverse t2)
and get_reverse t = force t.reverse (fun v -> t.reverse <- Some v) calc_reverse t 

and calc_representative t0 = 
(*   Util.format "CALC_REPRESENTATIVE %d (%s)@\n@\n" t0.uid (tag_of_t t0); *)
  let rec rep_jump f p = 
    if P.is_empty p then Misc.Right f 
    else 
      let (ti,ri) = P.choose p in
      let rest = P.remove (ti,ri) p in 
      if Q.mem ti f then rep_jump f rest
      else calc_representative ti (ri,f,rest) in
  let add ti wi r f p = 
    match ti.representative with
    | Some (Some t_wi) -> 
        let r' = 
          if wi = "" then (t_wi,ti)::r  
          else (t_wi,epsilon)::(wi,ti)::r in 
        Misc.Left r'
    | Some None -> 
        Misc.Right p
    | None -> 
        let p' = 
          if Q.mem ti f then p
          else P.add (ti,(wi,ti)::r) p in
        Misc.Right p' in 
    
  let full_search (r,f,p) =
(*     Util.format "@\nFULL_SEARCH %d@\n" t0.uid; *)
    let f' = Q.add t0 f in
      if t0.final then Misc.Left (("",t0)::r)
      else if Q.mem t0 f then 
        begin 
          if t0.representative = None then t0.representative <- Some None;
          rep_jump f' p
        end
      else
	let _,rm,len = get_maps t0 in
        let rec loop sn acc i = match acc with
          | Misc.Left _ -> acc
          | Misc.Right pacc ->               
              if i < 0 then acc
              else 
                let ci = rm.(i) in
                let w_ci = String.make 1 (Char.chr ci) in 
                let ti = t0.derivative ci in
                  if Q.mem ti sn then loop sn acc (pred i)
                  else loop (Q.add ti sn) (add ti w_ci r f' pacc) (pred i) in 
          match loop Q.empty (Misc.Right p) (pred len) with
            | Misc.Left _ as res -> res
            | Misc.Right p' -> rep_jump f' p' in 

  let rep_of_list l = 
    let buf = Buffer.create 17 in
    Safelist.iter (fun (wi,_) -> Buffer.add_string buf wi) l;
    Buffer.contents buf in 
    
  (* TODO: refactor loop in full_search to use a generalized alt_rep *)
  let rec alts_rep r g f p l = 
    let rec loop acc l = match acc,l with
      | Misc.Left _,_ -> acc
      | _,[]          -> acc
      | Misc.Right pacc,ti::rest -> 
          loop (add (g ti) "" r f pacc) rest in
      match loop (Misc.Right p) l with
        | Misc.Left _ as res -> res
        | Misc.Right p'      -> rep_jump f p' in 
    
    match t0.desc with
      | Anything | Epsilon | Star _ -> 
          (fun (r,f,_) -> Misc.Left(("",t0)::r))
      | Empty | CSet [] -> 
          (fun (r,f,_) -> Misc.Right f)
      | CSet((c1,_)::_) -> 
          (fun (r,f,_) -> Misc.Left ((string_of_char_code c1,t0)::r))
      | Seq(t1,t2) -> 
          (fun (r,f,p) -> 
             let go (r,f,p) ti = match ti.representative with
               | Some(Some wi) -> Misc.Left [wi,ti]
               | Some None     -> Misc.Right Q.empty
               | None          -> calc_representative ti (r,f,p) in
             match go (r,f,P.empty) t1 with 
               | Misc.Right f' -> 
                   (if t1.representative = None then t1.representative <- Some None);
                   rep_jump (Q.add t0 f) p
               | Misc.Left r1 -> 
                   let w1 = rep_of_list r1 in 
                   (if t1.representative = None then t1.representative <- Some (Some w1));
                   match go ([],f,P.empty) t2 with
                   | Misc.Right f' -> 
                       (if t2.representative = None then t2.representative <- Some None);
                       rep_jump (Q.add t0 f) p
                   | Misc.Left r2 ->
                       let w2 = rep_of_list r2 in 
                       (if t2.representative = None then t2.representative <- Some (Some w2));
                       Misc.Left[w1 ^ w2,t0])
      | Alt(t1,tl) -> 
          (fun (r,f,p) -> alts_rep r (fun x -> x) (Q.add t0 f) p (t1::tl))
      | Diff(t1,t2) -> 
            (match t1.desc with
               | Alt(t11,tl1) ->                 
                   (fun (r,f,p) -> alts_rep r (fun ti -> mk_diff ti t2) (Q.add t0 f) p (t11::tl1))
               | _ -> full_search)
      | Inter(t1,[t2]) ->
          (match t1.desc with
             | Alt(t11,tl1) ->
                 (fun (r,f,p) -> alts_rep r (fun ti -> mk_inter ti t2) (Q.add t0 f) p (t11::tl1))
             | _ -> match t2.desc with
                 | Alt(t21,tl2) ->
                     (fun (r,f,p) -> alts_rep r (fun ti -> mk_inter t1 ti) (Q.add t0 f) p (t21::tl2))
                 | _ -> full_search)
      | Inter(t1,tl2) ->
          (match t1.desc with
             | Alt(t11,tl1) ->
                 (fun (r,f,p) -> alts_rep r (fun ti -> mk_inters (ti::tl2)) (Q.add t0 f) p (t11::tl1))
             | _ -> full_search )

and get_representative t0 = match t0.representative with
  | Some res -> res 
  | None -> 
      match calc_representative t0 ([],Q.empty,P.empty) with
        | Misc.Right f' -> 
            Q.iter (fun ti -> ti.representative <- Some None) f';
            t0.representative <- Some None;
            None
        | Misc.Left r -> 
            let w0 = Safelist.fold_left 
              (fun w (wi,ti) -> 
                 let w' = wi ^ w in 
                 (if ti.representative = None then ti.representative <- Some (Some w'));
                 w') 
              "" r in
            t0.representative <- Some (Some w0);
            Some w0

and easy_empty t0 = match t0.representative with
  | Some None -> true
  | _ -> false

and calc_suffs t0 = 
  let rec suff_jump acc f p = match p with 
    | []        -> acc
    | ti::rest  -> 
        begin match ti.suffs with 
          | Some ti' -> suff_jump (mk_alt acc ti') f rest
          | None     -> calc_suffs ti (acc,f,rest) 
        end in 
  let add ti f p = if Q.mem ti f then p else ti::p in 
  let full_search (ts,f,p) = 
    let f' = Q.add t0 f in 
      if t0.final then suff_jump (mk_alt ts t0) f' p 
      else 
        let _,rm,len = get_maps t0 in 
        let rec loop sn pacc i = 
          if i < 0 then pacc 
          else 
            let ci = rm.(i) in 
            let ti = t0.derivative ci in 
              if Q.mem ti sn then loop sn pacc (pred i)
              else loop (Q.add ti sn) (add ti f' pacc) (pred i) in
          suff_jump ts f' (loop Q.empty p (pred len)) in 
    match t0.desc with
      | Anything | Epsilon | Star _ | Empty | CSet [] -> 
          (fun (ts,f,p) -> suff_jump (mk_alt ts t0) f p)
      | CSet((c1,_)::_) -> 
          (fun (ts,f,p) -> suff_jump (mk_alt ts epsilon) f p)
      | Seq(t1,t2) -> 
          (fun (ts,f,p) -> 
             if not t2.final then 
               let f' = Q.add t0 (Q.add t2 f) in 
                 suff_jump ts f' (add t2 f p)
             else 
               let f' = Q.add t0 (Q.add t1 (Q.add t2 f)) in 
                 suff_jump ts f' (add t1 f (add t2 f p)))
      | Alt(t1,tl) -> 
          (fun (ts,f,p) -> 
             let f',p' = Safelist.fold_left (fun (f,p) ti -> (Q.add ti f,add ti f p)) (Q.add t0 f,p) (t1::tl) in
               suff_jump ts f' p')
      | Diff(t1,t2) -> 
          (match t1.desc with
             | Alt(t11,tl1) ->                 
                 (fun (ts,f,p) -> 
                    let f',p' = Safelist.fold_left (fun (f,p) ti -> (Q.add ti f,add (mk_diff ti t2) f p)) (Q.add t0 f,p) (t1::tl1) in
                      suff_jump ts f' p')
             | _ -> full_search)
      | Inter(t1,t2) -> 
          (match t1.desc with
             | Alt(t11,tl1) -> 
                 (fun (ts,f,p) -> 
                    let f',p' = Safelist.fold_left (fun (f,p) ti -> (Q.add ti f,add (mk_inters (ti::t2)) f p)) (Q.add t0 f,p) (t1::tl1) in
                      suff_jump ts f' p')                 
             | _ -> full_search) 

and get_suffs t0 = match t0.suffs with
  | Some suffso -> suffso 
  | None -> 
      let t0' = calc_suffs t0 (empty,Q.empty,[]) in
      t0.suffs <- Some t0';
      t0'

and mk_cset cs = match cs with
  | [] -> empty
  | (c1,_)::_ -> 
      let cs' = Safelist.fold_left (fun l p -> CharSet.add p l) [] cs in 
      try CSCache.find cset_cache cs' 
      with Not_found -> 
	let res = mk_t (CSet cs') in 
        res.representative <- Some (Some (string_of_char_code c1));
	CSCache.add cset_cache cs' res;
	res

and mk_neg_cset cs = 
  let cs' = Safelist.fold_left (fun l p -> CharSet.add p l) [] cs in 
    match CharSet.negate min_code max_code cs' with 
      | [] -> empty
      | (c1,_)::_ as cs'' -> 
	  try CSCache.find neg_cset_cache cs''
	  with Not_found -> 
	    let res = mk_t (CSet cs'') in 
	    CSCache.add neg_cset_cache cs'' res;
            res.representative <- Some (Some (string_of_char_code c1));
	    res

and mk_seq t1 t2 = 
  let p = (t1,t2) in 
  try TTCache.find seq_cache p
  with Not_found -> 
    let rec aux acc ti = match ti.desc with
      | Seq(ti1,ti2) -> aux (ti1::acc) ti2 
      | _            -> Safelist.fold_left (fun acc ti -> mk_t(Seq(ti,acc))) t2 (ti::acc) in 
    let res = match t1.desc,t2.desc with
      | Epsilon,_       -> t2
      | _,Epsilon       -> t1
      | _               -> 
          if easy_empty t1 || easy_empty t2 then empty else aux [] t1 in 
    TTCache.add seq_cache p res;
    res   

and mk_seqs tl = 
  try TLCache.find seqs_cache tl
  with Not_found -> 
    let res = Safelist.fold_left mk_seq epsilon tl in 
    TLCache.add seqs_cache tl res;
    res

and mk_alt t1 t2 = 
  let p = (t1,t2) in 
  try TTCache.find alt_cache p
  with Not_found -> 
    let rec go acc l = match acc,l with
      | (t,[]),[] -> 
          if easy_empty t then empty else t
      | (t,t1::l1),[] -> 
          if easy_empty t then mk_t(Alt(t1,l1))
          else if t = anything then anything
          else mk_t(Alt(t,t1::l1))
      | (t,l1),(t1::rest) -> 
          if easy_empty t then go (t1,l1) rest 
          else if t = anything then anything
          else go (t1,t::l1) rest in 
    let rec merge acc l1 l2 = match l1,l2 with 
      | [],[] -> begin match acc with
          | [] -> empty
          | t1::rest -> go (t1,[]) rest
	end
      | t1::l1',[] -> merge (t1::acc) l1' []
      | [],t2::l2' -> merge (t2::acc) [] l2'
      | t1::l1',t2::l2' ->           
          let c = compare_t t1 t2 in 
            if c=0 then merge (t1::acc) l1' l2'
            else if c < 0 then merge (t1::acc) l1' l2
            else merge (t2::acc) l1 l2' in 
    let res = match t1.desc,t2.desc with
	| Empty,_               -> t2
	| _,Empty               -> t1
	| Anything,_            -> t1
	| _,Anything            -> t2
	| CSet s1,CSet s2       -> mk_cset (CharSet.union s1 s2)
	| Alt(t1,l1),Alt(t2,l2) -> merge [] (t1::l1) (t2::l2)
	| Alt(t1,l1),_          -> merge [] (t1::l1) [t2]
	| _,Alt(t2,l2)          -> merge [] [t1] (t2::l2)
	| _                     -> merge [] [t1] [t2] in 
    TTCache.add alt_cache p res;
    res
	    
and mk_alts tl = 
  try TLCache.find alts_cache tl
  with Not_found -> 
    let res = Safelist.fold_right mk_alt tl empty in 
    TLCache.add alts_cache tl res;
    res

and mk_star t0 = 
  try TCache.find star_cache t0 
  with Not_found -> 
    let res = 
      match t0.desc with 
	| Epsilon     -> epsilon
	| Empty       -> epsilon
	| Anything    -> anything
	| Star _      -> t0
	| CSet[mi,ma] -> 
	    if mi=min_code && ma=max_code then anything
	    else mk_t(Star t0)
	| _  -> mk_t(Star t0) in 
    TCache.add star_cache t0 res;
    res.representative <- Some (Some "");
    res
        
and mk_inter t1 t2 = 
  let p = (t1,t2) in 
  try TTCache.find inter_cache p
  with Not_found -> 
    let rec go acc l = match acc,l with
      | (t,[]),[] -> 
          if easy_empty t then empty else t
      | (t,t1::l1),[] -> 
          if easy_empty t then empty
          else if t = anything then mk_t(Inter(t1,l1))
          else mk_t(Inter(t,t1::l1))
      | (t,l1),(t1::rest) -> 
          if easy_empty t then empty
          else if t = anything then go (t1,l1) rest
          else go (t1,t::l1) rest in
    let rec merge acc l1 l2 = match l1,l2 with 
      | [],[] -> begin match acc with
          | [] -> anything
          | t1::rest -> 
              go (t1,[]) rest
	end
      | t1::l1',[] -> merge (t1::acc) l1' []
      | [],t2::l2' -> merge (t2::acc) [] l2'
      | t1::l1',t2::l2' ->           
          let c = compare_t t1 t2 in 
            if c=0 then merge (t1::acc) l1' l2'
            else if c < 0 then merge (t1::acc) l1' l2
            else merge (t2::acc) l1 l2' in 
    let res = 
      if easy_empty t1 || easy_empty t2 then empty
      else
        match t1.desc,t2.desc with
	  | Anything,_                -> t2
	  | _,Anything                -> t1
	  | Epsilon,_                 -> if t2.final then t1 else empty
	  | _,Epsilon                 -> if t1.final then t2 else empty
	  | CSet s1,CSet s2           -> mk_cset (CharSet.inter s1 s2)
	  | Inter(t1,l1),Inter(t2,l2) -> merge [] (t1::l1) (t2::l2)
	  | Inter(t1,l1),_            -> merge [] (t1::l1) [t2]
	  | _,Inter(t2,l2)            -> merge [] [t1] (t2::l2)
	  | _                         -> merge [] [t1] [t2] in
    TTCache.add inter_cache p res;
    res


and mk_inters tl = 
  try TLCache.find inters_cache tl
  with Not_found -> 
    let res = Safelist.fold_left mk_inter anything tl in 
    TLCache.add inters_cache tl res;
    res

and mk_diff t1 t2 = 
  let p = (t1,t2) in 
  try TTCache.find diff_cache p 
  with Not_found -> 
    let res = 
      if t1.uid = t2.uid || easy_empty t1 then empty 
      else if easy_empty t2 then t1
      else
	match t1.desc,t2.desc with
	  | _,Anything       -> empty
	  | Empty,_          -> empty
	  | _,Empty          -> t1
	  | CSet s1, CSet s2 -> mk_cset (CharSet.diff s1 s2)
	  | CSet _,Epsilon   -> t1
	  | Star t11,Epsilon -> mk_seq (mk_diff t11 t2) t1
	  | Epsilon,_        -> if t2.final then empty else epsilon
	  | Diff(t11,t12),_  -> mk_t(Diff(t11,mk_alt t12 t2))
	  | Inter(t1,tl),_   -> mk_inters (Safelist.map (fun ti -> mk_diff ti t2) (t1::tl))
	  | _                -> mk_t(Diff(t1,t2)) in 
    TTCache.add diff_cache p res;
    res

(* OPERATIONS *)
let mk_complement t0 = mk_diff anything t0

let mk_reverse t0 = get_reverse t0

let representative t0 = get_representative t0 

let is_empty t0 = representative t0 = None

let suffs t0 = get_suffs t0 

let splittable_cex t1 t2 = 
  let t2_rev = mk_reverse t2 in 
  let overlap_or_epsilon = mk_inter (suffs t1) (mk_reverse (suffs t2_rev)) in 
  let overlap = mk_diff overlap_or_epsilon epsilon in 
  representative overlap

let iterable_cex t1 = 
  splittable_cex t1 (mk_star t1)

let match_string t0 w = 
  let n = String.length w in 
  let rec loop i ti =     
    if i = n then ti.final
    else loop (succ i) (ti.derivative (Char.code w.[i])) in 
  loop 0 t0
      
let match_string_positions t0 w = 
  let n = String.length w in 
  let rec loop acc i ti = 
    let acc' = 
      if ti.final then Int.Set.add i acc 
      else acc in 
    if i=n then acc'
    else loop acc' (succ i) (ti.derivative (Char.code w.[i])) in 
  loop Int.Set.empty 0 t0

let match_prefix_positions t0 w = 
  let n = String.length w in 
  let rec loop acc i ti = 
    let acc' = 
      if is_empty ti then acc else Int.Set.add i acc in
    if i=n then acc'
    else loop acc' (succ i) (ti.derivative (Char.code w.[i])) in
  loop Int.Set.empty 0 t0

let match_string_reverse_positions t0 w = 
  let n = String.length w in 
  let rec loop acc i ti = 
    let acc' = 
      if ti.final then Int.Set.add (succ i) acc 
      else acc in 
    if i < 0 then acc'
    else loop acc' (pred i) (ti.derivative (Char.code w.[i])) in
  loop Int.Set.empty (pred n) t0

let mk_string s = 
  let n = String.length s in 
  let rec loop i acc = 
    if i >= n then acc
    else
      let m = Char.code s.[pred n-i] in 
      let ti = mk_cset [(m,m)] in 
      loop (succ i) (ti::acc) in 
  mk_seqs (loop 0 [])

let disjoint_cex s1 s2 = 
  representative (mk_inter s1 s2) 

let disjoint s1 s2 = 
  is_empty (mk_inter s1 s2) 

let equiv s1 s2 = 
  is_empty (mk_diff s1 s2) 
  && is_empty (mk_diff s2 s1) 

let splittable s1 s2 = match splittable_cex s1 s2 with 
  | None -> true
  | Some _ -> false

let iterable s0 = match iterable_cex s0 with 
  | None -> true
  | Some _ -> false

let is_singleton s0 = 
  match representative s0 with 
    | None -> false
    | Some w -> is_empty (mk_diff s0 (mk_string w))

let split_positions t1 t2 w = 
  let ps1 = match_string_positions t1 w in 
  let ps2 = match_string_reverse_positions (mk_reverse t2) w in 
    Int.Set.inter ps1 ps2

let split_bad_prefix t1 s = 
  let ps = Int.Set.add 0 (match_prefix_positions t1 s) in 
  let n = String.length s in
  let j = Int.Set.max_elt ps in
    (String.sub s 0 j, String.sub s j (n-j))

let seq_split s1 s2 w =
  let ps = split_positions s1 s2 w in 
    if not (Int.Set.cardinal ps = 1) then 
      None
    else
      let n = String.length w in 
      let j = Int.Set.choose ps in 
      let s1,s2 = (String.sub w 0 j, String.sub w j (n-j)) in 
	Some (s1,s2)

let star_split s1 w = 
  let s1_star = mk_star s1 in 
  let ps = Int.Set.remove 0 (split_positions s1_star s1_star w) in 
  let _,rev = 
    Int.Set.fold 
      (fun j (i,acc) -> (j,(String.sub w i (j-i))::acc)) 
      ps (0,[]) in 
    Safelist.rev rev 

