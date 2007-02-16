(***********************************************************************
*                                                                      *
*             This software is part of the padsml package              *
*           Copyright (c) 2006-2007 Knowledge Ventures Corp.           *
*                         All Rights Reserved                          *
*        This software is licensed by Knowledge Ventures Corp.         *
*           under the terms and conditions of the license in           *
*                    www.padsproj.org/License.html                     *
*                                                                      *
*  This program contains certain software code or other information    *
*  ("AT&T Software") proprietary to AT&T Corp. ("AT&T").  The AT&T     *
*  Software is provided to you "AS IS". YOU ASSUME TOTAL RESPONSIBILITY*
*  AND RISK FOR USE OF THE AT&T SOFTWARE. AT&T DOES NOT MAKE, AND      *
*  EXPRESSLY DISCLAIMS, ANY EXPRESS OR IMPLIED WARRANTIES OF ANY KIND  *
*  WHATSOEVER, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF*
*  MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, WARRANTIES OF  *
*  TITLE OR NON-INFRINGEMENT.  (c) AT&T Corp.  All rights              *
*  reserved.  AT&T is a registered trademark of AT&T Corp.             *
*                                                                      *
*                   Network Services Research Center                   *
*                   Knowledge Ventures Labs Research                   *
*                           Florham Park NJ                            *
*                                                                      *
*            Yitzhak Mandelbaum <yitzhak@research.att.com>>            *
*                                                                      *
***********************************************************************)
(* references to empty string to be used to store command-line args. *)
let clean_arg        = ref false
let ptype_arg        = ref ""
let idl_mod_arg      = ref ""
let rep_type_arg     = ref ""
let def_val_arg      = ref ""
let params_arg       = ref []
let paramtys_arg     = ref []
let gentool_conv_arg = ref ""
let genuntool_conv_arg = ref ""
let gentool_mod_arg  = ref ""

;;

let arg_specs = [
  ("-i",Arg.Set_string idl_mod_arg,
   "Name of module exported through CamlIDL. Required.");
  ("-p",Arg.Set_string ptype_arg,
   "Name of PADS type. Required.");
  ("-r",Arg.Set_string rep_type_arg,
   "OCaml representation type. Required.");
  ("-d",Arg.Set_string def_val_arg,
   "Default value for type. Required.");
  ("-a",Arg.Tuple 
     [Arg.String (fun p -> params_arg := !params_arg @ [p]);
      Arg.String (fun t -> paramtys_arg := !paramtys_arg @ [t])],
   "The name and type of an additional paramater. This option can be used multiple times to specify multiple additional parameters.");
  ("-c",Arg.Set_string gentool_conv_arg,
   "Function to convert rep before passing to generic tool.");
  ("-u",Arg.Set_string genuntool_conv_arg,
   "Function to convert result from untool to rep.");
  ("-m",Arg.Set_string gentool_mod_arg,
   "The gentool base-type module with which to process the rep. Required.");
  ("--clean", Arg.String (fun s -> clean_arg := true; ptype_arg := s),
   "Remove all files created for the specified type.")
]

let usage_message = 
  "--clean <pads type> | <require options>\n" ^
  "When --clean is specified, only the PADS/ML type must be supplied." ^
  " Otherwise, all arguments marked required must be supplied in some order."
;;

Arg.parse arg_specs (fun s -> raise (Arg.Bad ("anonymous argument \"" ^ s ^ "\" is invalid."))) usage_message
;;

(* If not cleaning, then check that all required arguments have been provided. *)
if not !clean_arg then
  List.fold_left
    (fun () (s,o) -> if !s = "" then (
       Arg.usage arg_specs ("Missing -"^o^" argument.\n" ^ usage_message);
       raise Exit)
     else ())
    ()
    [(idl_mod_arg,     "i");
     (ptype_arg,       "p");
     (rep_type_arg,    "r");
     (def_val_arg,     "d");
     (gentool_mod_arg, "m")]
else ()
;;

(** Name of the base type. *)
let ptype = !ptype_arg in
  
(** Uncapitalized version of name of the base type - i.e. first letter set to lower-case. *)
let ptype_uc = String.uncapitalize ptype in
let intf = ptype ^ ".mli" in
let impl = ptype ^ ".ml" in
  if !clean_arg then
    begin
      if Sys.file_exists intf then
	begin
	  print_endline ("Removing PADS/ML base type interface " ^ intf ^ ".");
	  Sys.remove intf
	end
      else ();      
      if Sys.file_exists impl then
	begin
	  print_endline ("Removing PADS/ML base type implementation " ^ impl ^ ".");
	  Sys.remove impl
	end
      else ()
    end
  else   
    (** Name of module exported by IDL interface *)
    let idl_mod = !idl_mod_arg in

    let rep_type = !rep_type_arg in

    let def_val = !def_val_arg in

    let params = !params_arg in
    let (params_tuple, params_curry) = 
      match params with 
	  [] -> ("","")
	| [p] -> (p, p)
	| _ -> ("(" ^ String.concat ", " params ^ ")",
		String.concat " " params)
    in 
    let paramtys = !paramtys_arg in
    let paramtys_ty = 
      match paramtys with 
	  [] -> ""
	| [t] -> t ^ " ->"
	| _ -> "(" ^ String.concat " * " paramtys ^ ") ->"
    in
      (** Function to convert rep before passing to generic tool. *)
    let gentool_conv = !gentool_conv_arg in
    let genuntool_conv = !genuntool_conv_arg in

    (** The gentool base-type module that should process the rep. *)
    let gentool_mod = !gentool_mod_arg in
    let output_endline oc l = (output_string oc l; output_string oc "\n") in
      begin
	print_endline ("Creating PADS/ML base type interface " ^ intf ^ ".");    
	let intf_oc = open_out intf in
	  output_endline intf_oc ("type rep = "^ rep_type);
	  output_endline intf_oc ("type pd_body = Pads.base_pd_body");
	  output_endline intf_oc ("type pd = Pads.base_pd");
	  output_endline intf_oc ("");
(* Is there any reason to export the default value? It's for internal use only. *)
(* 	  output_endline intf_oc ("val default : rep"); *)
(* 	  output_endline intf_oc (""); *)
	  output_endline intf_oc ("val parse  : " ^ paramtys_ty ^ " ");
	  output_endline intf_oc ("  (rep,pd_body) Pads.parser");
	  output_endline intf_oc ("");
	  output_endline intf_oc ("val print  : " ^ paramtys_ty ^ " ");
	  output_endline intf_oc ("  (rep,pd_body) Pads.printer");
	  output_endline intf_oc ("");
	  output_endline intf_oc ("val gen_pd : " ^ paramtys_ty ^ " rep -> pd");
	  output_endline intf_oc ("");
	  output_endline intf_oc ("module Traverse :");
	  output_endline intf_oc ("sig");
	  output_endline intf_oc ("  val init : ('state,'rps,'dps,'cps,'lps) Generic_tool.Rec_ver.t -> unit -> 'state");
	  output_endline intf_oc ("  val traverse : ('state,'rps,'dps,'cps,'lps) Generic_tool.Rec_ver.t -> rep -> pd -> 'state -> 'state");
	  output_endline intf_oc ("end");
	  output_endline intf_oc ("module Untraverse :");
	  output_endline intf_oc ("sig");
	  output_endline intf_oc ("  val untraverse : 'a Generic_untool.Rec_ver.t -> 'a -> rep");
	  output_endline intf_oc ("end");
	  output_endline intf_oc ("");
	  
	  close_out intf_oc
      end;
      begin
	print_endline ("Creating PADS/ML base type implementation " ^ impl ^ ".");
	let impl_oc = open_out impl in
	  output_endline impl_oc ("open Generic_tool.Rec_ver");
	  output_endline impl_oc ("open Generic_untool.Rec_ver");
	  output_endline impl_oc ("type rep = " ^ rep_type);
	  output_endline impl_oc ("type pd_body = Pads.base_pd_body" );
	  output_endline impl_oc ("type pd = Pads.base_pd" );
	  output_endline impl_oc ("" );
	  output_endline impl_oc ("let default = " ^ def_val);
	  output_endline impl_oc ("" );
	  output_endline impl_oc ("let parse " ^ params_tuple ^ " pads =" );
	  output_endline impl_oc ("  let (res,pd,rep) =" );
	  output_endline impl_oc ("    " ^ idl_mod ^ "." ^ ptype_uc  ^ "_read " );
	  output_endline impl_oc ("      (Pads.get_padsc_handle pads) Padsc.p_CheckAndSet" );
	  output_endline impl_oc ("      " ^ params_curry);
	  output_endline impl_oc ("  in"       );
	  output_endline impl_oc ("  let c_pos = Pads.get_current_pos pads in" );
	  output_endline impl_oc ("  let new_pd = Pads.base_pd_of_pbase_pd pd c_pos in" );
	  output_endline impl_oc ("    match res with" );
	  output_endline impl_oc ("	Padsc.P_OK -> (rep,new_pd)" );
	  output_endline impl_oc ("      | Padsc.P_ERR -> " );
	  output_endline impl_oc ("	  if Pads.IO.is_speculative pads then" );
	  output_endline impl_oc ("	    raise Pads.Speculation_failure" );
	  output_endline impl_oc ("	  else (default,new_pd)" );
	  output_endline impl_oc (""		 );
	  output_endline impl_oc ("let gen_pd " ^ params_tuple ^ " r = Pads.gen_base_pd" );
	  output_endline impl_oc ("" );
	  output_endline impl_oc ("let print " ^ params_tuple ^ " rep pd pads = " );
	  output_endline impl_oc ("  let new_pd = Pads.pbase_pd_of_base_pd pd in" );
	  output_endline impl_oc ("    ignore (" ^ idl_mod ^ "." ^ ptype_uc ^ "_write2io" );
	  output_endline impl_oc ("	      (Pads.get_padsc_handle pads) (Pads.get_out_stream pads) " );
	  output_endline impl_oc ("	      new_pd rep " ^ params_curry ^ ")" );
	  output_endline impl_oc ("" );
	  output_endline impl_oc ("module Traverse = struct" );
	  output_endline impl_oc ("  let init tool = tool." ^ String.uncapitalize gentool_mod ^ "_t.bt_init" );
	  output_endline impl_oc ("  let traverse tool r pd state = " );
	  output_endline impl_oc ("    let (h,_) = pd in " );
	  output_endline impl_oc ("    let res = if Pads.pd_is_ok pd then Pads.Ok(" ^ gentool_conv ^ " r) else Pads.Error in" );
	  output_endline impl_oc ("      tool." ^ String.uncapitalize gentool_mod ^ "_t.bt_process state res h" );
	  output_endline impl_oc ("end" );
	  output_endline impl_oc ("module Untraverse = struct" );
	  output_endline impl_oc ("  let untraverse untool t = " ^ genuntool_conv ^ "(untool.process" ^ gentool_mod ^ " t)");
	  output_endline impl_oc ("end" );
	  close_out impl_oc
      end
