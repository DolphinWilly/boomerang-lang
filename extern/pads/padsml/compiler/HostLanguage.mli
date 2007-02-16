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
(* module HostLanguage *)
(** Interface to host language in which embedded expressions and patterns are written.
 *)

(** host language expression *)
type expr

(** host language patt *)
type patt

(** host language type *)
type tp

(** types of literals supported by pads *)
type literal_tp = Char_lit | String_lit | Int_lit | RegExp_lit

(** typing context - maps ids to types*)
type tp_ctxt

val empty_ctxt : tp_ctxt
val add_var : tp_ctxt -> Id.id -> tp -> tp_ctxt
val lookup_var: tp_ctxt -> Id.id -> tp option
  
val host_of_ocaml_e : MLast.expr -> expr
val host_of_regexp : MLast.expr -> expr
val ocaml_of_host_e : expr -> MLast.expr

val host_of_ocaml_p : MLast.patt -> patt
val ocaml_of_host_p : patt -> MLast.patt

val tp_of_ctyp : MLast.ctyp -> tp
val ctyp_of_tp : tp -> MLast.ctyp

val infer_lit_tp : expr -> literal_tp
val infer_type : tp_ctxt -> expr -> tp

