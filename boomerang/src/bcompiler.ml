(*******************************************************************************)
(* The Harmony Project                                                         *)
(* harmony@lists.seas.upenn.edu                                                *)
(*******************************************************************************)
(* Copyright (C) 2007-2008                                                     *)
(* J. Nathan Foster, Alexandre Pilkiewicz, and Benjamin C. Pierce              *)
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
(* /boomerang/src/compiler.ml                                                  *)
(* Boomerang type checker and interpreter                                      *)
(* $Id$ *)
(*******************************************************************************)

open Bsyntax
open Bprint
open Berror
module RS = Bstring
module R = Bregexp
module L = Blenses.DLens
module C = Blenses.Canonizer
module V = Bvalue

(* --------------- Imports --------------- *)
let sprintf = Printf.sprintf  
let msg = Util.format
let (@) = Safelist.append

let s_of_rv = Bregistry.sort_or_scheme_of_rv 
let v_of_rv = Bregistry.value_of_rv 
let p_of_rv rv = (s_of_rv rv, v_of_rv rv)
let mk_rv = Bregistry.make_rv

(* --------------- Unit tests --------------- *)

(* unit tests either succeed, yielding a value, or fail with a msg *)
type testresult = OK of sort * Bvalue.t | Error of (unit -> unit)

let tests = Prefs.createStringList
  "test"
  "run unit test for the specified module"
  "run unit tests for the specified module"
let _ = Prefs.alias tests "t"

let test_all = Prefs.createBool "test-all" false
  "run unit tests for all modules"
  "run unit tests for all modules"

(* [check_test m] returns true iff the command line arguments
   '-test-all' or '-test m' are set *)
let check_test ms = 
  Safelist.fold_left 
    (fun r qs -> r or (Qid.id_prefix (Bvalue.parse_qid qs) ms))
    (Prefs.read test_all)
    (Prefs.read tests)

(* --------------- Error Reporting --------------- *)
let debug s_thk = 
  Trace.debug "compiler" (fun () -> msg "@[%s@\n%!@]" (s_thk ()))

let test_error i msg_thk = 
  raise (Error.Harmony_error
           (fun () -> msg "@[%s: Unit test failed @ " (Info.string_of_t i); 
              msg_thk ();
              msg "@]"))

let run_error i msg_thk = 
  raise (Error.Harmony_error
           (fun () -> msg "@[%s: Unexpected run-time error @\n"
              (Info.string_of_t i);
              msg_thk ();
              msg "@]"))

(* --------------- Environments --------------- *)
module type CEnvSig = 
sig
  type t 
  type v
  val empty : Qid.t -> t
  val get_ev : t -> Bregistry.REnv.t
  val set_ev : t -> Bregistry.REnv.t -> t
  val get_ctx : t -> Id.t list
  val set_ctx : t -> Id.t list -> t
  val get_mod : t -> Qid.t 
  val set_mod : t -> Qid.t -> t
  val lookup : t -> Qid.t -> v option
  val lookup_type : t -> Qid.t -> Bregistry.tspec option
  val lookup_con : t -> Qid.t -> (Qid.t * Bregistry.tspec) option
  val update : t -> Qid.t -> v -> t
  val update_type : t -> Bsyntax.svar list -> Qid.t -> Bregistry.tcon list -> t
  val fold : (Qid.t -> v -> 'a -> 'a) -> t -> 'a -> 'a
end

module CEnv : CEnvSig with type v = (sort_or_scheme * Bvalue.t) = 
struct
  type t = (Id.t list * Qid.t) * (Bregistry.REnv.t)
  type v = sort_or_scheme * Bvalue.t

  let empty m = (([],m), (Bregistry.REnv.empty ()))

  (* getters and setters *)
  let get_ev cev = let (_,ev) = cev in ev
  let set_ev cev ev = let (os,_) = cev in (os,ev)
  let get_ctx cev = let ((os,_),_) = cev in os
  let set_ctx cev os = let ((_,m),ev) = cev in ((os,m),ev)
  let get_mod cev = let ((_,m),_) = cev in m
  let set_mod cev m = let ((os,_),ev) = cev in ((os,m),ev)

  (* lookup from a cev, then from the library *)
  let lookup_generic lookup_fun lookup_library_fun cev q = 
    match lookup_fun (get_ev cev) q with
      | None -> 
          begin 
            match lookup_library_fun (get_ctx cev) q with
              | None -> None
              | Some r -> Some r
          end
      | Some r -> Some r
          
  let lookup cev q = 
    match lookup_generic 
      Bregistry.REnv.lookup 
      Bregistry.lookup_library_ctx 
      cev q with
        | None -> None
        | Some rv -> Some (p_of_rv rv)

  let lookup_type cev q = 
    lookup_generic 
      Bregistry.REnv.lookup_type
      Bregistry.lookup_type_library_ctx 
      cev q 

  let lookup_con cev q = 
    lookup_generic 
      Bregistry.REnv.lookup_con
      Bregistry.lookup_con_library_ctx 
      cev q 

  let update cev q (s,v) = 
    set_ev cev (Bregistry.REnv.update (get_ev cev) q (mk_rv s v))

  let update_type cev svars q cl = 
    set_ev cev (Bregistry.REnv.update_type (get_ev cev) svars q cl)

  let fold f cev a = 
    let ev = get_ev cev in   
    Bregistry.REnv.fold (fun q v a -> f q (s_of_rv v,v_of_rv v) a) ev a
end

type cenv = CEnv.t

module SCEnv : CEnvSig with type v = sort_or_scheme = 
struct
  type t = CEnv.t
  type v = sort_or_scheme 

  let dummy_value = Bvalue.Unt (V.Pos (Info.M "dummy value"))
  let empty = CEnv.empty        
  let get_ev = CEnv.get_ev
  let set_ev = CEnv.set_ev   
  let get_ctx = CEnv.get_ctx
  let set_ctx = CEnv.set_ctx
  let get_mod = CEnv.get_mod
  let set_mod = CEnv.set_mod

  let lookup sev q = 
    match CEnv.lookup sev q with 
    | None -> None
    | Some (s,_) -> Some s
  let lookup_type = CEnv.lookup_type
  let lookup_con = CEnv.lookup_con 
  let update sev q s = CEnv.update sev q (s,dummy_value)
  let update_type sev svars q cs = CEnv.update_type sev svars q cs
  let fold f sev a = CEnv.fold (fun q (s,_) a -> f q s a) sev a
end

(* --------------- Checker --------------- *)
let cenv_free_svs i cev = 
  CEnv.fold 
    (fun _ (ss,_) acc -> match ss with 
       | Sort _ -> acc
       | Scheme (svsi,si) -> SVSet.union acc (SVSet.diff (free_svs i si) svsi))
    cev SVSet.empty

let scenv_free_svs i sev = 
  SCEnv.fold 
    (fun _ ss acc -> match ss with 
       | Sort _ -> acc
       | Scheme (svsi,si) -> SVSet.union acc (SVSet.diff (free_svs i si) svsi))
    sev SVSet.empty

(* helper: check if a sort matches a pattern; return bindings for variables *)
let rec static_match i sev p0 s = 
(*   msg "STATIC_MATCH: %s # %s@\n" (string_of_pat p0) (string_of_sort s); *)
  let err p s1 s2 = sort_error i 
    (fun () -> msg "@[in@ pattern@ %s:@ expected %s,@ but@ found@ %s@]"
       (string_of_pat p)
       (string_of_sort s1)
       (string_of_sort s2)) in 
  match p0 with 
    | PWld _ -> 
        Some (p0,[])
    | PVar(i,x,_) -> 
        Some (PVar(i,x,Some s), [(x,Sort s)])
    | PUnt(_) -> 
        if not (Bunify.unify i (SCEnv.get_ctx sev) s SUnit) then err p0 SUnit s;
        (Some (p0,[]))
    | PVnt(i,li,pio) -> 
        (* lookup which datatype we have using li *)
(*         msg "LOOKING UP %s@\n" (Qid.string_of_t li); *)
        begin match SCEnv.lookup_con sev li with
          | None -> sort_error i (fun () -> msg "@[Unbound@ constructor@ %s@]" (Qid.string_of_t li))
          | Some (qx,(svl,cl)) ->            
(*               msg "QX: %s SVL: %t@\n" (Qid.string_of_t qx) (fun _ -> Misc.format_list "," (format_svar false) svl); *)
              let svs,sl = Bunify.svs_sl_of_svl svl in
              let s_expect,cl_inst = Bunify.instantiate_cases i (svs,SData(sl,qx)) cl in 
(*               msg "RAW DATA         : %s@\n" (string_of_sort (SData(sl,qx))); *)
(*               msg "INSTANTIATED DATA: %s@\n" (string_of_sort s_expect); *)
              if not (Bunify.unify i (SCEnv.get_ctx sev) s s_expect) then err p0 s_expect s;
              let rec aux = function
                | [] -> None
                | (lj,sjo)::rest -> 
                    if (Qid.equal_ctx (SCEnv.get_ctx sev) li lj) then 
                      (match pio,sjo with 
                         | None,None -> Some (PVnt(i,li,None),[])
                         | Some pi,Some sj -> 
                             Misc.map_option 
                               (fun (new_pi,l) -> PVnt(i,li,Some new_pi),l)
                               (static_match i sev pi sj)                             
                         | _ -> sort_error i (fun () -> msg "@[wrong@ number@ of@ arguments@ to@ constructor@ %s@]" (Qid.string_of_t li)))
                    else aux rest in 
              aux cl_inst
        end
    | PPar(i,p1,p2) -> 
        let s1 = Bunify.fresh_sort Fre in 
        let s2 = Bunify.fresh_sort Fre in 
        let s_expect = SProduct(s1,s2) in 
        if not (Bunify.unify i (SCEnv.get_ctx sev) s s_expect) then err p0 s_expect s;
        (match static_match i sev p1 s1, static_match i sev p2 s2 with 
           | Some (new_p1,l1), Some(new_p2,l2) -> Some (PPar(i,new_p1,new_p2), l1 @ l2)
           | _ -> None)

let rec dynamic_match i cev p v = match p,v with 
  | PWld(_),_ -> Some []
  | PVar(_,q,Some s),_ -> Some [(q,s,v)]
  | PUnt(_),V.Unt(_) -> Some []
  | PVnt(_,li,pio),V.Vnt(_,_,lj,vjo) -> 
      if (Qid.equal_ctx (CEnv.get_ctx cev) li lj) then 
        (match pio,vjo with 
           | None,None -> Some []
           | Some pi,Some vj -> dynamic_match i cev pi vj
           | _ -> 
               run_error i 
                 (fun () -> msg "@[wrong@ number@ of@ arguments@ to@ constructor@ %s@]" (Qid.string_of_t li)))
      else None
  | PPar(_,p1,p2),V.Par(_,v1,v2) -> 
      (match dynamic_match i cev p1 v1,dynamic_match i cev p2 v2 with 
         | Some l1,Some l2 -> Some (l1 @ l2)
         | _ -> None)
  | _ -> None 

let rec check_exp ((tev,sev) as evs) e0 = match e0.desc with
  (* overloaded, polymorphic operators *)
  | EVar(q) ->
      let e0_sort = match SCEnv.lookup sev q with
        | Some (Sort s) -> s
        | Some (Scheme ss) -> Bunify.instantiate e0.info ss 
        | None -> 
            sort_error e0.info
              (fun () -> msg "@[%s is not bound@]" 
                 (Qid.string_of_t q)) in 
      let new_e0 = mk_checked_exp e0.info e0.desc e0_sort in 
      (e0_sort,new_e0)

  | EFun(Param(p_i,p_x,p_s),ret_sorto,body) ->      
      let tev',p_s' = Bunify.fix_sort tev p_s in 
      let body_sev = SCEnv.update sev (Qid.t_of_id p_x) (Sort p_s') in
      let body_sort,new_body = 
        match ret_sorto with 
          | None -> check_exp (tev',body_sev) body 
          | Some ret_sort -> 
              let tev'',ret_sort' = Bunify.fix_sort tev' ret_sort in 
              let body_sort,new_body = check_exp (tev'',body_sev) body in       
              if not (Bunify.unify e0.info (SCEnv.get_ctx sev) body_sort ret_sort') then 
                sort_error e0.info
                  (fun () -> 
                     msg "@[in@ function:@ %s@ expected@ but@ %s@ found@]"
                       (string_of_sort ret_sort')
                       (string_of_sort body_sort));
              (body_sort,new_body) in 
      let dep_x = 
        if VSet.mem p_x (free_vars_sort body_sort)
        then p_x
        else Id.wild
      in
      let e0_sort = SFunction(dep_x,p_s',body_sort) in 
      let new_e0 = mk_checked_exp e0.info (EFun(Param(p_i,p_x,p_s'),Some body_sort,new_body)) e0_sort in 
      (e0_sort,new_e0)

  | ELet(b,e) ->
      let bevs,_,new_b = check_binding evs b in 
      let e0_sort,new_e = check_exp bevs e in 
      let new_e0 = mk_checked_exp e0.info (ELet(new_b,new_e)) e0_sort in 
      (e0_sort,new_e0)

  | EUnit -> 
      let new_e0 = mk_checked_exp e0.info e0.desc SUnit in
      (SUnit,new_e0)

  | EString(_) -> 
      let new_e0 = mk_checked_exp e0.info e0.desc SString in 
      (SString,new_e0)

  | ECSet(_) -> 
      let new_e0 = mk_checked_exp e0.info e0.desc SRegexp in 
      (SRegexp,new_e0)

  | EPair(e1,e2) -> 
      let e1_sort,new_e1 = check_exp evs e1 in 
      let e2_sort,new_e2 = check_exp evs e2 in 
      let e0_sort = SProduct(e1_sort,e2_sort) in 
      let new_e0 = mk_checked_exp e0.info (EPair(new_e1,new_e2)) e0_sort in 
      (e0_sort,new_e0)

  (* elimination forms *)
  | EApp(e1,e2) ->  
(*       msg "@[IN APP: "; format_exp e0; msg "@]@\n"; *)
(*       msg "@[E1_SORT: %s@\n@]" (string_of_sort e1_sort); *)
(*       msg "@[E2_SORT: %s@\n@]" (string_of_sort e2_sort); *)
(*       msg "@[RESULT: %s@\n@]" (string_of_sort ret_sort); *)
      let e1_sort,new_e1 = check_exp evs e1 in 
      let e2_sort,new_e2 = check_exp evs e2 in 
      let param_sort = Bunify.fresh_sort Fre in 
      let ret_sort = Bunify.fresh_sort Fre in      
      let sf = SFunction(Id.wild,param_sort,ret_sort) in        
      if not (Bunify.unify e0.info (SCEnv.get_ctx sev) e1_sort sf) then
        sort_error e0.info
          (fun () -> 
             msg "@[in@ application:@ %s@ expected@ but@ %s@ found@]"
               (string_of_sort sf)
               (string_of_sort e1_sort));
      if not (Bunify.unify e0.info (SCEnv.get_ctx sev) e2_sort param_sort) then 
        sort_error e0.info
          (fun () -> 
             msg "@[in@ application:@ %s@ expected@ but@ %s@ found@]"
               (string_of_sort param_sort)
               (string_of_sort e2_sort));
      let e0_sort = ret_sort in 
      let new_e0 = mk_checked_exp e0.info (EApp(new_e1,new_e2)) e0_sort in 
      (e0_sort,new_e0)

  | ECase(e1,pl) -> 
(*       msg "ECASE: %s@\n" (string_of_sort e1_sort); *)
(*       msg "BRANCHES SORT: %s@\n" (string_of_sort branches_sort); *)
(*            msg "CHECKING BRANCH: "; *)
(*            format_pat pi; *)
(*            msg " -> "; *)
(*            format_exp ei; *)
(*            msg "@\n"; *)
(*                  msg "EI_SORT: %s@\n" (string_of_sort ei_sort); *)
(*                  msg "BRANCHES_SORT: %s@\n" (string_of_sort branches_sort); *)
(*       msg "END OF CASE %t@\n" (fun _ -> format_sort e0_sort); *)
      let err2 i p s1 s2 = sort_error i (fun () -> msg p s1 s2) in 
      let e1_sort,new_e1 = check_exp evs e1 in 
      let branches_sort = Bunify.fresh_sort Fre in 
      let new_pl_rev = Safelist.fold_left 
        (fun new_pl_rev (pi,ei) -> 
           match static_match e0.info sev pi e1_sort with 
             | None -> 
                 err2 e0.info "@[pattern@ %s@ does@ not@ match@ sort@ %s@]" 
                   (string_of_pat pi) 
                   (string_of_sort e1_sort)
             | Some (new_pi,binds) ->                
                 let ei_sev = Safelist.fold_left 
                   (fun ei_sev (qj,sj) -> SCEnv.update ei_sev qj sj)
                   sev binds in 
                 let ei_sort,new_ei = check_exp (tev,ei_sev) ei in                 
                 if not (Bunify.unify e0.info (SCEnv.get_ctx sev) ei_sort branches_sort) then
                   sort_error e0.info 
                     (fun () -> 
                        msg "@[in@ match:@ %s@ expected@ but@ %s@ found@]"
                          (string_of_sort branches_sort)
                          (string_of_sort ei_sort));                   
                 let new_pl_rev' = (new_pi,new_ei)::new_pl_rev in 
                 new_pl_rev')
        [] pl in 
      let e0_sort = branches_sort in 
      let new_e0 = mk_checked_exp e0.info (ECase(new_e1,Safelist.rev new_pl_rev)) e0_sort in 
      (e0_sort,new_e0)
        
and check_binding ((tev,sev) as evs) = function
  | Bind(i,PVar(ix,qx,_),sorto,e) -> 
(*       msg "@[BINDING %s has sort %s@\n@]" (string_of_id x) (string_of_scheme x_scheme); *)
      let sev_fsvs = scenv_free_svs i sev in 
      let tev',(e_sort,new_e) = match sorto with 
        | None -> (tev,check_exp evs e)
        | Some s -> 
            let tev',s' = Bunify.fix_sort tev s in 
            let e_sort,new_e = check_exp (tev',sev) e in 
            if not (Bunify.unify i (SCEnv.get_ctx sev) e_sort s') then 
              sort_error i 
                (fun () -> 
                   msg "@[in@ let-binding:@ %s@ expected@ but@ %s@ found@]"
                     (string_of_sort s')
                     (string_of_sort e_sort));
              (tev',(e_sort,new_e)) in 
      let x_scheme = Scheme (Bunify.generalize i sev_fsvs e_sort) in 
      let bsev = SCEnv.update sev qx x_scheme in 
      let new_b = Bind(i,PVar(ix,qx,Some e_sort),Some e_sort,new_e) in 
      ((tev',bsev),[qx],new_b)
  | Bind(i,p,sorto,e) ->
      let tev',(e_sort,new_e) = match sorto with 
        | None -> (tev,check_exp evs e)
        | Some s -> 
            let tev',s' = Bunify.fix_sort tev s in             
            let e_sort,new_e = check_exp (tev',sev) e in 
            if not (Bunify.unify i (SCEnv.get_ctx sev) e_sort s') then 
              sort_error i 
                (fun () -> 
                   msg "@[in@ let-binding:@ %s@ expected@ but@ %s@ found@]"
                     (string_of_sort s')
                     (string_of_sort e_sort));
              (tev',(e_sort,new_e)) in 
      let bindso = static_match i sev p e_sort in 
      let new_p,(bsev,xs_rev) = match bindso with 
        | None -> sort_error i 
            (fun () -> msg "@[pattern@ %s@ does@ not@ match@ sort@ %s@]"
               (string_of_pat p) 
               (string_of_sort e_sort))
        | Some (new_p,binds) -> 
            (new_p,
             Safelist.fold_left 
               (fun (bsev,xs) (q,s) -> (SCEnv.update bsev q s, q::xs))
               (sev,[]) binds) in 
      let new_b = Bind(i,new_p,Some e_sort,new_e) in 
      ((tev',bsev),Safelist.rev xs_rev,new_b)

(* type check a single declaration *)
let rec check_decl ((tev,sev) as evs) ms = function 
  | DLet(i,b) -> 
      let tev' = [] in (* discard old tev *)
      let evs' = (tev',sev) in 
      let bevs',xs,new_b = check_binding evs' b in 
      let new_d = DLet(i,new_b) in      
        (bevs',xs,new_d)
  | DMod(i,n,ds) ->
      let ms = ms @ [n] in 
      let (m_tev,m_sev),names,new_ds= check_module_aux evs ms ds in
      let n_sev, names_rev = Safelist.fold_left 
        (fun (n_sev, names) q -> 
           match SCEnv.lookup m_sev q with
               None -> run_error i 
                 (fun () -> 
                    msg "@[declaration for %s missing@]"
                      (Qid.string_of_t q))
             | Some s ->
                 let nq = Qid.splice_id_dot n q in
                   (SCEnv.update n_sev nq s, nq::names))
        (sev,[])
        names in 
      let new_d = DMod(i,n,new_ds) in 
        ((m_tev,n_sev),Safelist.rev names_rev,new_d)

  | DType(i,sl,x,cl) -> 
      (* allocate / substitute SVars for SRawVars *)
      let qx = Qid.t_dot_id (SCEnv.get_mod sev) x in 
      (* create association list *)
      let sl',al = 
        let svl_rev,al = 
          Safelist.fold_left 
            (fun (svl,al) si -> 
               match si with 
                 | SRawVar(x) -> begin 
                     try (Safelist.assoc x al::svl,al)
                     with Not_found -> 
                       let s_fresh = Bunify.fresh_sort Fre in 
                         (s_fresh::svl, (x,s_fresh)::al)
                   end
                 | _ -> Berror.run_error i (fun () -> msg "expected sort variable"))
            ([],[]) sl in 
          (Safelist.rev svl_rev,al) in 
      let svl = Bunify.svl_of_sl i sl' in 
      let eq = function
        | SRawVar(x) -> Id.equal x
        | _ -> (fun _ -> false) in 
      let cl' = 
        Safelist.map 
          (fun (x,so) -> (x,Misc.map_option (Bunify.subst_sort al eq) so)) 
          cl in 
      let qcl' = Safelist.map (fun (x,so) -> (Qid.t_of_id x,so)) cl' in 
      let sx = SData(sl',qx) in 
      let new_sev = Safelist.fold_left 
        (fun sev (ql,so) ->            
           let s = match so with 
             | None -> sx
                 (* generate non-dependent function type *)
             | Some s -> SFunction (Id.wild,s,sx) in
           let scheme = Scheme (mk_scheme svl s) in
(*            msg "%s := %s@\n" (Qid.string_of_t ql) (string_of_scheme (svs,s)); *)
             SCEnv.update sev ql scheme)
        sev qcl' in 
      let new_sev' = SCEnv.update_type new_sev svl qx qcl' in 
      let new_d = DType(i,sl',x,cl') in 
        ((tev,new_sev'),[],new_d)
          
  | DTest(i,e1,tr) -> 
      let e1_sort,new_e1 = check_exp evs e1 in
      let tev',new_tr = match tr with 
        | TestError | TestShow -> tev,tr
        | TestValue e2 -> 
            let e2_sort,new_e2 = check_exp evs e2 in 
              if not (Bunify.unify i (SCEnv.get_ctx sev) e2_sort e1_sort) then
                sort_error i 
                  (fun () -> 
                     msg "@[in@ type test:@ %s@ expected@ but@ %s@ found@]"
                       (string_of_sort e1_sort)
                       (string_of_sort e2_sort));
              tev, TestValue (new_e2)
        | TestSort None -> tev,tr
        | TestSort (Some s) -> 
            let tev',s' = Bunify.fix_sort tev s in 
            (tev',TestSort (Some s'))
        | TestLensType(e21o,e22o) -> 
            let chk_eo = function
              | None -> None
              | Some e -> 
                  let e_sort,new_e = check_exp evs e in 
                    if not (Bunify.unify i (SCEnv.get_ctx sev) e_sort SRegexp) then
                      sort_error i 
                        (fun () ->
                           msg "@[in@ type test:@ %s@ expected@ but@ %s@ found@]"
                             (string_of_sort SRegexp)
                             (string_of_sort e_sort));
                    Some new_e in 
              (tev,TestLensType(chk_eo e21o, chk_eo e22o)) in 
      let new_d = DTest(i,new_e1,new_tr) in 
      let evs' = (tev',sev) in 
      (evs',[],new_d)
          
and check_module_aux evs m ds = 
  let m_evs, names, new_ds_rev = 
    Safelist.fold_left 
      (fun (evs, names, new_ds_rev) di -> 
         let m_evs,new_names,new_di = check_decl evs m di in
           m_evs, names@new_names,new_di::new_ds_rev)
      (evs,[],[])
      ds in
    (m_evs, names, Safelist.rev new_ds_rev)

let check_module = function
  | Mod(i,m,nctx,ds) -> 
      let tev = [] in 
      let sev = SCEnv.set_ctx (SCEnv.empty (Qid.t_of_id m)) (m::nctx@Bregistry.pre_ctx) in
      let _,_,new_ds = check_module_aux (tev,sev) [m] ds in 
      Mod(i,m,nctx,new_ds)
 
(* --------------- Compiler --------------- *)
(* checking of refinement types *)
let rec instrument cev s0 v0 = match s0 with 
  | SProduct(s1,s2) -> 
      begin match v0 with
        | V.Par(b,v1,v2) -> 
            let v1' = instrument cev s1 v1 in 
            let v2' = instrument cev s2 v2 in 
              V.Par(b,v1',v2')
        | _ -> assert false
      end
  | SFunction(dep,s1,s2) -> 
      begin match v0 with 
        | V.Fun(b,f) -> 
            let f' x = 
              let x' = instrument cev s1 (V.merge_blame b x) in
              let r = f x' in
              let cod_cev = CEnv.update cev (Qid.t_of_id dep) (Sort s1, x') in
                instrument cod_cev s2 (V.install_blame b r) in 
            V.Fun(b,f')
        | _ -> assert false
      end
  | SRefine(x,s1,e1) -> 
      let cev' = CEnv.update cev (Qid.t_of_id x) (Sort s1, v0) in
      let (_,pred) = compile_exp cev' e1 in
      if V.get_b pred then v0 else 
        begin 
          (* BLAME! *)
          raise 
            (Error.Harmony_error
               (fun () -> 
                  Util.format "%s: %s did not have sort %s"
                    (Info.string_of_t (V.info_of_t v0))
                    (V.string_of_t v0)
                    (string_of_sort s0)))
        end
  | SData _ -> assert false
  | _ -> v0

(* expressions *)
and compile_exp cev e0 = match e0.desc,e0.sorto with 
  | EVar(q),Some s0 ->       
      begin match s0,CEnv.lookup cev q with
        | SRegexp,Some(_,v) -> 
            (* rewrite this: it renames regexps too agressively! To do
               it right, the environment needs to maintain a list of
               already-def'd regexps that it can rename.  --JNF *)
            let x = Qid.string_of_t q in 
            let r' = Bregexp.set_str (Bvalue.get_r v) x in
            let rv' = SRegexp, Bvalue.Rx(V.blame_of_info e0.info,r') in 
              rv'
        | _,Some(_,v) -> (s0,v)
        | _,None -> run_error e0.info 
            (fun () -> msg "@[%s is not bound@]" (Qid.string_of_t q))
      end

  | EApp(e1,e2),Some s0 ->
      let s1,v1 = compile_exp cev e1 in
      let _,v2 = compile_exp cev e2 in
        begin match v1 with
          | Bvalue.Fun(_,f) -> (s0,f v2)
          | _   -> 
              run_error e0.info 
                (fun () -> 
                   msg
                     "@[expected function in left-hand side of application but found %s"
                     (string_of_sort s1))
        end


  | ELet(b,e),_ -> 
      let bcev,_ = compile_binding cev b in
        compile_exp bcev e
          
  | EFun(p,Some ret_sort,e),Some s0 ->
      let p_sort = sort_of_param p in 
      let f_impl v =
        let p_qid = Qid.t_of_id (id_of_param p) in 
        let body_cev = CEnv.update cev p_qid (Sort p_sort, v) in
          snd (compile_exp body_cev e) in 
        (s0, (Bvalue.Fun (V.blame_of_info e0.info,f_impl)))

  | EUnit,_ -> (SUnit,Bvalue.Unt (V.blame_of_info e0.info))

  | EPair(e1,e2),Some s0 -> 
      let _,v1 = compile_exp cev e1 in 
      let _,v2 = compile_exp cev e2 in 
        (s0,Bvalue.Par(V.blame_of_info e0.info,v1,v2))

  | ECase(e1,pl),_ -> 
      let _,v1 = compile_exp cev e1 in 
      let rec find_match = function
        | [] -> run_error e0.info (fun () -> msg "@[match@ failure@]")
        | (pi,ei)::rest -> 
            (match dynamic_match e0.info cev pi v1 with 
               | None -> find_match rest
               | Some l -> l,ei) in 
      let binds,ei = find_match pl in 
      let ei_cev = Safelist.fold_left 
        (fun ei_cev (q,s,v) -> CEnv.update ei_cev q (Sort s,v))
        cev binds in 
        compile_exp ei_cev ei

  | EString(s),_ -> (SString,Bvalue.Str(V.blame_of_info e0.info,s))

  | ECSet(pos,cs),_ -> 
      let mk_r = if pos then R.set else R.negset in 
        (SRegexp,Bvalue.Rx (V.blame_of_info e0.info, mk_r cs))

  | _ -> 
      run_error (info_of_exp e0)
        (fun () -> 
           msg "@[compiler bug: unchecked expression!@]")
        
and compile_binding cev = function
  | Bind(i,p,so,e) ->
      let s,v = compile_exp cev e in 
      let bindso = dynamic_match i cev p v in 
      let cev_fsvs = cenv_free_svs i cev in 
      let bcev,xs_rev = match bindso with 
        | None -> run_error i 
            (fun () -> msg "@[pattern %s and value %s do not match@]" 
               (string_of_pat p)
               (V.string_of_t v))
        | Some binds -> 
            Safelist.fold_left 
              (fun (bcev,xs) (q,s,v) -> 
                 let x_scheme = Scheme (Bunify.generalize i cev_fsvs s) in 
                   (CEnv.update bcev q (x_scheme,v), q::xs))
              (cev,[]) binds in 
        (bcev,Safelist.rev xs_rev)

let rec compile_decl cev ms d0 = match d0 with 
  | DLet(i,b) -> 
      let bcev,xs = compile_binding cev b in
        (bcev,xs)
  | DType(i,sl,x,cl) -> 
(*       msg "COMPILING %t@\n" (fun _ -> format_decl d); *)
(*       msg "X_SORT %t@\n" (fun _ -> format_sort x_sort); *)
      let qx = Qid.t_dot_id (CEnv.get_mod cev) x in 
      let svl =       (* SLOW! *)
        Safelist.rev 
          (Safelist.fold_left 
             (fun l si -> 
                match si with 
                  | SVar svi -> svi::l
                  | _ -> assert false)
             [] sl) in  
      let svs,sl = Bunify.svs_sl_of_svl svl in 
      let x_sort = SData(sl,qx) in
      let x_scheme = Scheme (svs,x_sort) in 
      let new_cev = Safelist.fold_left 
        (fun cev (l,so) -> 
           let ql = Qid.t_of_id l in 
           let qml = Qid.t_dot_id (CEnv.get_mod cev) l in 
           let rv = match so with 
             | None -> (x_scheme,V.Vnt(V.blame_of_info i,qx,qml,None))
             | Some s -> 
                 let sf = SFunction(Id.wild,s,x_sort) in 
                 let sf_scheme = Scheme (svs,sf) in                    
                 (sf_scheme, 
                  V.Fun(V.blame_of_info i,
                        (fun v -> V.Vnt(V.blame_of_t v,qx,qml,Some v)))) in 
           CEnv.update cev ql rv)
        cev cl in 
      let qcl = Safelist.map (fun (x,so) -> (Qid.t_of_id x,so)) cl in 
      let new_cev' = CEnv.update_type new_cev svl qx qcl in   
      (new_cev',[qx])

  | DMod(i,n,ds) ->
      let m_cev, names = compile_mod_aux cev ms ds in
      let n_cev,names_rev = 
        Safelist.fold_left
          (fun (n_cev, names) q ->
             match CEnv.lookup m_cev q with
               | Some rv ->
                   let nq = Qid.splice_id_dot n q in
                   (CEnv.update n_cev nq rv, nq::names)
               | None -> 
                   run_error i 
                     (fun () -> msg "@[compiled declaration for %s missing@]"
                        (Qid.string_of_t q)))
          (cev,[])
          names in
        (n_cev, Safelist.rev names_rev)
  | DTest(i,e,tr) ->
      if check_test ms then 
        begin
          let vo = 
            try let s,v = compile_exp cev e in 
            OK(s,v)
            with (Error.Harmony_error(err)) -> Error err in 
          match vo,tr with 
            | OK (_,v), TestShow ->
                msg "Test result:@ "; 
                Bvalue.format v; 
                msg "@\n%!"
            | OK (s0,v), TestSort(Some s) -> 
                if not (Bunify.unify i (CEnv.get_ctx cev) s0 s) then
                  test_error i
                    (fun () -> 
                       msg "@\nExpected@ "; format_sort s;
                       msg "@ but found@ "; format_sort s0; 
                       msg "@\n%!")
            | OK(s0,v), TestSort None -> 
                msg "Test sort:@ %t@\n%!" (fun _ -> format_scheme (free_svs i s0,s0));
            | OK(s0,v), TestLensType(e1o,e2o) -> 
                if not (Bunify.unify i (CEnv.get_ctx cev) s0 SLens) then 
                  test_error i 
                    (fun () -> 
                       msg "@\nExpected@ "; format_sort SLens;
                       msg "@ but found@ "; Bvalue.format v;
                       msg "@\n%!");
                let l = Bvalue.get_l v in 
                let c,a = L.ctype l,L.atype l in 
                let chk_eo r = function
                  | None -> true,"?"
                  | Some e -> 
                      let expected = Bvalue.get_r (snd (compile_exp cev e)) in 
                      (R.equiv r expected, R.string_of_t expected) in 
                let c_ok,c_str = chk_eo c e1o in 
                let a_ok,a_str = chk_eo a e2o in 
                  if c_ok && a_ok then 
                    (if e1o = None || e2o = None then 
                      begin 
                        msg "Test type:@ ";
                        msg "@[<2>%s <-> %s@]" (R.string_of_t c) (R.string_of_t a);
                        msg "@\n%!"
                      end)
                  else
                    begin
                  test_error i 
                    (fun () -> 
                       msg "@\nExpected@ "; 
                       msg "@[<2>%s <-> %s@]" c_str a_str;
                       msg "@ but found@ "; 
                       msg "@[<2>%s <-> %s@]" (R.string_of_t c) (R.string_of_t a);
                       msg "@\n%!");
                    end                      
            | Error err, TestShow 
            | Error err, TestSort _ 
            | Error err, TestLensType _ -> 
                test_error i 
                  (fun () -> 
                    msg "Test result: error@\n";
                    err (); 
                    msg "%!")
            | Error _, TestError -> ()
            | OK(_,v), TestValue res -> 
                let resv = snd (compile_exp cev res) in
                  if not (Bvalue.equal v resv) then
                    test_error i 
                      (fun () ->
                        msg "@\nExpected@ "; Bvalue.format resv;
                        msg "@ but found@ "; Bvalue.format v; 
                        msg "@\n%!")
            | Error err, TestValue res -> 
                let resv = snd (compile_exp cev res) in
                  test_error i 
                    (fun () ->
                      msg "@\nExpected@ "; Bvalue.format resv; 
                      msg "@ but found an error:@ "; 
                      err (); 
                      msg "@\n%!")
            | OK(_,v), TestError -> 
                test_error i 
                  (fun () ->
                    msg "@\nExpected an error@ "; 
                    msg "@ but found:@ "; 
                    Bvalue.format v; 
                    msg "@\n%!")
        end;
      (cev, [])
        
and compile_mod_aux cev ms ds = 
  Safelist.fold_left
    (fun (cev, names) di ->
      let m_cev, new_names = compile_decl cev ms di in
        (m_cev, names@new_names))
    (cev,[])
    ds

let compile_module = function
  | Mod(i,m,nctx,ds) -> 
      let cev = CEnv.set_ctx (CEnv.empty (Qid.t_of_id m)) (m::nctx@Bregistry.pre_ctx) in
      let new_cev,_ = compile_mod_aux cev [m] ds in
      Bregistry.register_env (CEnv.get_ev new_cev) m
