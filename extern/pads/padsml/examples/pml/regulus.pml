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
*                 David Walker <dpw@cs.princeton.edu>                  *
*              Kathleen Fisher <kfisher@research.att.com>              *
*                                                                      *
***********************************************************************)
open Built_ins

let gmt = Pads.timezone_of_string "GMT"

ptype timestamp = ptimestamp_explicit_FW(8, "%H:%M:%S", gmt)
ptype pip = puint8 * '.' * puint8 * '.' * puint8 * '.' * puint8
  
(* Generic name value pair. *)
ptype (alpha) pnvp = pstring('=') * '=' * alpha

(* Name value pair with name specified. *)
ptype (alpha) nvp(name:string) = [nvp: alpha pnvp | fst nvp = name]

(* pstring terminated by semicolon or vertical bar. *)
(* ptype SVString = pstring_SE("/[;|]/") *)
ptype sv_string = pstring_SE("/;|\\|/")

ptype details = {
      source      : pip nvp("src_addr");
';';  dest        : pip nvp("dst_addr");
';';  start_time  : timestamp nvp("start_time");
';';  end_time    : timestamp nvp("end_time");
';';  cycle_time  : puint32 nvp("cycle_time")
}

ptype info(alarm_code : int64) =
  pmatch alarm_code with
    5074L -> Details of details
  | _    -> Generic of sv_string pnvp plist(';','|')

ptype service = 
    DOMESTIC of "DOMESTIC" 
  | INTERNATIONAL of "INTERNATIONAL" 
  | SPECIAL of "SPECIAL"

ptype raw_alarm = {
       alarm    : [ alarm : pint | alarm = 2 or alarm = 3];
 ':';  start    : timestamp popt;
 '|';  clear    : timestamp popt;
 '|';  code     : puint32;
 '|';  src_dns  : sv_string nvp("dns1");
 ';';  dest_dns : sv_string nvp("dns2");
 '|';  info     : info(code);
 '|';  service  : service
}

let checkCorr = function
    {alarm=2; start=Some _; clear= None} -> true
  | {alarm=3; start=None;   clear= Some _} -> true
  |  _ -> false

ptype alarm = [x:raw_alarm | checkCorr x]

ptype source = alarm precord plist_np
