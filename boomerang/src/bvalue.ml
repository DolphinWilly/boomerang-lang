(*******************************************************************************)
(* The Harmony Project                                                         *)
(* harmony@lists.seas.upenn.edu                                                *)
(*******************************************************************************)
(* Copyright (C) 2007 J. Nathan Foster and Benjamin C. Pierce                  *)
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
(* /boomerang/src/bvalue.ml                                                    *)
(* Boomerang run-time values                                                   *)
(* $Id$ *)
(*******************************************************************************)

(* module imports and abbreviations *)
module S = Bsyntax
module P = Bprint
module R = Bregexp
module L = Blenses.DLens
module C = Blenses.Canonizer
module RS = Bstring

(* function abbreviations *)
let sprintf = Printf.sprintf 
let (@) = Safelist.append 

(* run-time values; correspond to each sort *)
type t = 
  | Unt of Info.t 
  | Bol of Info.t * bool
  | Int of Info.t * int
  | Str of Info.t * RS.t 
  | Rx  of Info.t * R.t
  | Lns of Info.t * L.t
  | Can of Info.t * C.t
  | Fun of Info.t * (t -> t)
  | Par of Info.t * t * t
  | Vnt of Info.t * S.Qid.t * S.Id.t * t option

let info_of_t = function
  | Unt(i)       -> i
  | Int(i,_)     -> i
  | Bol(i,_)     -> i
  | Str(i,_)     -> i
  |  Rx(i,_)     -> i
  | Lns(i,_)     -> i
  | Can(i,_)     -> i
  | Fun(i,_)     -> i
  | Par(i,_,_)   -> i
  | Vnt(i,_,_,_) -> i         

let rec equal v1 v2 = match v1,v2 with
  | Unt _, Unt _ -> 
      true
  | Bol(_,b1), Bol(_,b2) -> 
      b1=b2
  | Int(_,n1), Int(_,n2) -> 
      n1=n2
  | Str(_,s1), Str(_,s2) -> 
      RS.equal s1 s2
  | Rx(_,r1), Rx(_,r2) -> 
      R.equiv r1 r2
  | Lns _, Lns _ -> 
      Error.simple_error (sprintf "Cannot test equality of lenses.")
  | Can _, Can _ -> 
      Error.simple_error (sprintf "Cannot test equality of canonizers.")
  | Fun _, Fun _ -> 
      Error.simple_error (sprintf "Cannot test equality of functions.")
  | Par(_,v1,v2),Par(_,v1',v2') -> 
      (equal v1 v1') && (equal v2 v2')
  | Vnt(_,qx,l,None), Vnt(_,qx',l',None) -> 
      S.Qid.equal qx qx' && S.Id.equal l l'
  | Vnt(_,qx,l,Some v), Vnt(_,qx',l',Some v') ->
      (S.Qid.equal qx qx') && (S.Id.equal l l') && (equal v v')
  | Vnt _,Vnt _ -> false
  | _, _ -> 
      Error.simple_error (sprintf "Cannot test equality of values with different sorts.")

let rec format = function
  | Unt(_)       -> Util.format "()"
  | Int(_,n)     -> Util.format "%d" n
  | Bol(_,b)     -> Util.format "%b" b
  | Str(_,rs)    -> Util.format "%s" (RS.string_of_t rs)
  | Rx(_,r)      -> Util.format "%s" (R.string_of_t r)
  | Lns(_,l)     -> Util.format "%s" (L.string l)
  | Can(_,c)     -> Util.format "%s" (C.string c)
  | Fun(_,f)     -> Util.format "<function>"
  | Par(_,v1,v2) -> 
      Util.format "@[(";
      format v1;
      Util.format ",@ ";
      format v2;
      Util.format ")@]"
  | Vnt(_,_,l,None) -> Util.format "%s" (S.Id.string_of_t l)
  | Vnt(_,_,l,Some v) ->  
      Util.format "@[(%s@ " (S.Id.string_of_t l);
      format v;
      Util.format ")@]"        

let string_of_t v = Util.format_to_string (fun () -> format v)
        
let rec sort_string_of_t = function
  | Unt _ -> "unit"
  | Bol _ -> "bool" 
  | Int _ -> "int" 
  | Str _ -> "string"
  | Rx _  -> "regexp"
  | Lns _ -> "lens"
  | Can _ -> "canonizer"
  | Fun _ -> "<function>"
  | Par(_,v1,v2) -> sprintf "(%s,%s)" (sort_string_of_t v1) (sort_string_of_t v2)
  | Vnt(_,qx,_,_) -> sprintf "%s" (S.Qid.string_of_t qx)

(* --------- conversions between run-time values ---------- *)
let conversion_error s1 v1 = 
  Error.simple_error 
    (sprintf "%s: expected %s, but found %s" 
        (Info.string_of_t (info_of_t v1)) 
        s1
        (string_of_t v1))

let get_s v = match v with
  | Str(_,s) -> s
  | _ -> conversion_error (P.string_of_sort S.SString) v

let get_b v = match v with
  | Bol(_,b) -> b
  | _ -> conversion_error (P.string_of_sort S.SBool) v

let get_i v = match v with
  | Int(_,n) -> n
  | _ -> conversion_error (P.string_of_sort S.SInteger) v

let get_r v = match v with
    Rx(_,r)  -> r
  | Str(_,s) -> R.str false s
  | _ -> conversion_error (P.string_of_sort S.SRegexp) v

let get_l v = 
  let i = info_of_t v in
    match v with 
      | Str(_,s) -> L.copy i (R.str false s)
      | Rx(_,r)  -> L.copy i r
      | Lns(_,l) -> l
      | _ -> conversion_error (P.string_of_sort S.SLens) v

let get_c v = match v with 
  | Can(_,c) -> c
  | _ -> conversion_error (P.string_of_sort S.SCanonizer) v

let get_f v = match v with
  | Fun(_,f) -> f
  | _ -> conversion_error "function" v

let get_u v = match v with
  | Unt(_) -> ()
  | _ -> conversion_error "unit" v

let get_p v = match v with
  | Par(_,v1,v2) -> (v1,v2)
  | _ -> conversion_error "pair" v

let get_v v = match v with
  | Vnt(_,_,l,v) -> (l,v)
  | _ -> conversion_error "variant" v

let get_b v = 
  let t_id = Bsyntax.Id.mk (Info.M "True built-in") "True" in 
  let f_id = Bsyntax.Id.mk (Info.M "False built-in") "False" in 
  match get_v v with
    | (l,_) -> 
        if Bsyntax.Id.equal l t_id
        then true
        else if Bsyntax.Id.equal l f_id
        then false
        else conversion_error "boolean" v
        
(* --------- constructors for functions on run-time values ---------- *)
let mk_sfun b f = Fun(b,(fun v -> f (get_s v)))

let mk_rfun b f = Fun(b,(fun v -> f (get_r v)))

let mk_lfun b f = Fun(b,(fun v -> f (get_l v)))

let mk_cfun b f = Fun(b,(fun v -> f (get_c v)))

let mk_ufun b f = Fun(b,(fun v -> f (get_u v)))

let mk_ifun b f = Fun(b,(fun v -> f (get_i v)))

let mk_poly_fun b f = Fun(b,f)

let parse_uid s = 
  let lexbuf = Lexing.from_string s in
    Blexer.setup "identifier constant";
    let x = 
      try Bparser.uid Blexer.main lexbuf
      with _ -> raise 
        (Error.Harmony_error
           (fun () -> 
              Util.format "%s: syntax error in identifier %s." 
                (Info.string_of_t (Blexer.info lexbuf))
                s)) in 
      Blexer.finish ();                    
      x

let parse_qid s = 
  let lexbuf = Lexing.from_string s in
    Blexer.setup "qualitified identifier constant";
    let q = 
      try Bparser.qid Blexer.main lexbuf
      with _ -> raise 
        (Error.Harmony_error
           (fun () -> 
              Util.format "%s: syntax error in qualified identifier %s." 
                (Info.string_of_t (Blexer.info lexbuf))
                s)) in 
      Blexer.finish ();                    
      q
