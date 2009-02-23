(******************************************************************************)
(* The Harmony Project                                                        *)
(* harmony@lists.seas.upenn.edu                                               *)
(******************************************************************************)
(* Copyright (C) 2008 J. Nathan Foster and Benjamin C. Pierce                 *)
(*                                                                            *)
(* This library is free software; you can redistribute it and/or              *)
(* modify it under the terms of the GNU Lesser General Public                 *)
(* License as published by the Free Software Foundation; either               *)
(* version 2.1 of the License, or (at your option) any later version.         *)
(*                                                                            *)
(* This library is distributed in the hope that it will be useful,            *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU          *)
(* Lesser General Public License for more details.                            *)
(******************************************************************************)
(* /boomerang/src/bsyntax.ml                                                  *)
(* Boomerang abstract syntax                                                  *)
(* $Id$ *)
(******************************************************************************)

(* ----- imports and abbreviations ----- *)
let (@) = Safelist.append 
let sprintf = Printf.sprintf
let msg = Util.format

open Bident

(* ----- blame ----- *)
type blame = Blame of Info.t 

let mk_blame i = Blame i 

let info_of_blame b = match b with
  | Blame(i) -> i

let invert_blame b = b

(* ----- sorts, parameters, expressions ----- *)
type sort = 
    (* base sorts *)
    | SUnit                           (* unit *)
    | SBool                           (* booleans *)
    | SInteger                        (* integers *)
    | SChar                           (* chars *)
    | SString                         (* strings *)
    | SRegexp                         (* regular expressions *)
    | SLens                           (* lenses *)
    | SCanonizer                      (* canonizers *)

    (* products and sums *)
    | SProduct of sort * sort         (* products *)
    | SData of sort list * Qid.t      (* data types *)

    (* dependent function types *)
    | SFunction of Bident.Id.t * sort *  sort 
    | SRefine of Id.t * sort * exp    (* refinement types *)
    | SVar of Id.t                    (* variables *)
    | SForall of Id.t * sort          (* universals *)
 
(* parameters *)
and param = Param of Info.t * Id.t * sort

(* variable bindings *)
and binding = Bind of Info.t * pat * sort option * exp 

(* expressions *)
and exp = 
    (* lambda calculus *)
    | EApp  of Info.t * exp * exp 
    | EVar  of Info.t * Qid.t 
    | EOver of Info.t * op * exp list 
    | EFun  of Info.t * param * sort option * exp 
    | ELet  of Info.t * binding * exp 

    (* or rather... System F *)
    | ETyFun of Info.t * Id.t * exp 
    | ETyApp of Info.t * exp * sort

    (* with products, case *)
    | EPair of Info.t * exp * exp 
    | ECase of Info.t * exp * (pat * exp) list * sort

    (* casts, locations, and allocations *)
    | ECast    of Info.t * sort * sort * blame * exp
        
    (* unit, strings, ints, character sets *)
    | EUnit    of Info.t  
    | EInteger of Info.t * int    
    | EChar    of Info.t * char
    | EString  of Info.t * string
    | ECSet    of Info.t * bool * (char * char) list 

    (* booleans with counter examples *)
    (* None ~ true; Some s ~ false with counterexample s *)
    | EBoolean of Info.t * exp option 

(* overloaded operators *)
and op = 
  | OIter of int * int
  | ODot
  | OTilde
  | OMinus
  | OBar
  | OAmp
  | OBarBar
  | OAmpAmp
  | ODarrow
  | ODeqarrow
  | OEqual
  | OLt
  | OLeq
  | OGt
  | OGeq

(* patterns *)
and pat = 
  | PWld of Info.t
  | PUnt of Info.t
  | PBol of Info.t * bool
  | PCex of Info.t * pat
  | PInt of Info.t * int
  | PStr of Info.t * string
  | PVar of Info.t * Id.t * sort option
  | PVnt of Info.t * Qid.t * pat option 
  | PPar of Info.t * pat * pat

(* test results *)
type test_result =
    | TestError
    | TestPrint
    | TestEqual of exp
    | TestSortPrint of sort option
    | TestSortEqual of sort option * sort 

(* declarations *)
type decl = 
    | DLet  of Info.t * binding 
    | DType of Info.t * Id.t list * Qid.t * (Id.t * sort option) list 
    | DMod  of Info.t * Id.t * decl list 
    | DTest of Info.t * exp * test_result

(* modules *)
type modl = Mod of Info.t * Id.t * Qid.t list * decl list

(* infix constructor for non-dependent functions and products*)
let (^>) s1 s2 = SFunction(Id.wild,s1,s2)
let (^*) s1 s2 = SProduct(s1,s2)

(* ----- accessor functions ----- *)
let sort_of_param p0 = match p0 with
  | Param(_,_,s) -> s

let id_of_param p0 = match p0 with
  | Param(_,x,_) -> x

let pat_of_binding b0 = match b0 with 
  | Bind(_,p,_,_) -> p

let exp_of_binding b0 = match b0 with 
  | Bind(_,_,_,e) -> e

let rec info_of_exp e = match e with 
  | EApp     (i,_,_)     -> i
  | EVar     (i,_)       -> i
  | EOver    (i,_,_)     -> i
  | EFun     (i,_,_,_)   -> i
  | ELet     (i,_,_)     -> i 
  | ETyFun   (i,_,_)     -> i
  | ETyApp   (i,_,_)     -> i
  | EPair    (i,_,_)     -> i
  | ECase    (i,_,_,_)   -> i
  | ECast    (i,_,_,_,_) -> i
  | EUnit    (i)         -> i
  | EBoolean (i,_)       -> i
  | EInteger (i,_)       -> i    
  | EChar    (i,_)       -> i 
  | EString  (i,_)       -> i
  | ECSet    (i,_,_)     -> i
      
let info_of_pat = function
  | PWld (i)     -> i
  | PUnt (i)     -> i
  | PBol (i,_)   -> i
  | PCex (i,_)   -> i
  | PInt (i,_)   -> i
  | PStr (i,_)   -> i
  | PVar (i,_,_) -> i 
  | PVnt (i,_,_) -> i
  | PPar (i,_,_) -> i

let info_of_module = function
  | Mod(i,_,_,_) -> i

let id_of_module = function
  | Mod(_,x,_,_) -> x

let sl_of_svl svl = 
  Safelist.map (fun svi -> SVar svi) svl 

let mk_app i e1 e2 = 
  EApp(i,e1,e2)

let mk_app3 i e1 e2 e3 = 
  mk_app i (mk_app i e1 e2) e3

let mk_let i x s1 e1 e2 =
  let b = Bind(i,PVar(i,x,Some s1),None,e1) in 
  ELet(i,b,e2)

let mk_fun i x s e1 =
  let p = Param(i,x,s) in  
  EFun(i,p,None,e1)

let mk_if i e0 e1 e2 s =
  let bs = [(PBol(i,true),e1);(PBol(i,false),e2)] in 
  ECase(i,e0,bs,s)

let mk_native_prelude_var i s = 
  EVar(i,Qid.mk_native_prelude_t s)

let mk_string_of_char i e = 
  EApp(i,mk_native_prelude_var i "string_of_char",e)

let mk_regexp_of_string i e = 
  EApp(i,mk_native_prelude_var i "str",e)

let mk_lens_of_regexp i e = 
  EApp(i,mk_native_prelude_var i "copy",e)

let mk_qid_var x = 
  EVar(Qid.info_of_t x,x)

let mk_var x = 
  mk_qid_var (Qid.t_of_id x)

let mk_native_prelude_var x = 
  mk_qid_var (Qid.mk_native_prelude_t x)

let mk_core_var x = 
  mk_qid_var (Qid.mk_core_t x)

let mk_list_var x = 
  mk_qid_var (Qid.mk_list_t x)

let mk_over i op el = 
  EOver(i,op,el)

let mk_app i e1 e2 = 
  EApp(i,e1,e2)

let mk_bin_op i o e1 e2 = 
  mk_app i (mk_app i o e1) e2

let mk_tern_op i o e1 e2 e3 = 
  mk_app i (mk_bin_op i o e1 e2) e3

let mk_cat i e1 e2 = 
  mk_over i ODot [e1;e2]

let mk_iter i min max e1 = 
  mk_over i (OIter(min,max)) [e1]

let mk_acond i e1 e2 = 
  mk_over i OBar [e1;e2]

let mk_cond i e1 e2 = 
  mk_over i OBar [e1;e2]

let mk_swap i e1 e2 = 
  mk_over i OTilde [e1;e2]

let mk_diff i e1 e2 = 
  mk_bin_op i (mk_core_var "diff") e1 e2

let mk_inter i e1 e2 = 
  mk_bin_op i (mk_core_var "inter") e1 e2

let mk_compose i e1 e2 = 
  mk_bin_op i (mk_core_var "compose") e1 e2

let mk_set i e1 e2 = 
  mk_bin_op i (mk_qid_var (Qid.mk_core_t "set")) e1 e2

let mk_match i x q =   
  mk_bin_op i 
    (mk_core_var "dmatch")
    (EString(i,x)) 
    (mk_qid_var q)

let mk_sim_match i e t q = 
  mk_tern_op i 
    (mk_core_var "smatch")
    (EString(i,string_of_float e))
    (EString(i,t))
    (mk_qid_var q)

let mk_rx i e = 
  mk_app i (mk_core_var "str") e
