(****************************************************************)
(* The Harmony Project                                          *)
(* harmony@lists.seas.upenn.edu                                 *)
(*                                                              *)
(* syntax.ml - Focal abstract syntax                            *)
(****************************************************************)
(* $Id: syntax.ml,v 1.2 2005/04/11 18:24:47 jnfoster Exp $ *)

let ( @ ) = Safelist.append  (* redefine @ to use stack-safe append *)
let sprintf = Printf.sprintf (* import selectively *)

(* identifiers *)
type i = Info.t
type id = i * string
type qid = id list * id

(* functions on identifiers *)
(* equality: ignore parsing Info.t *)
let id_compare (_,x1) (_,x2) = compare x1 x2
let id_equal i1 i2 = (id_compare i1 i2 = 0)
let qid_compare (qs1,x1) (qs2,x2) = 
  let rec ids_compare xs1 xs2 = match xs1,xs2 with
      [],[] -> 0
    | _,[]  -> 1
    | [],_  -> -1
    | (x1::t1),(x2::t2) -> 
	let hd_compare = id_compare x1 x2 in
	  if (hd_compare <> 0) then hd_compare 
	  else ids_compare t1 t2
  in
    ids_compare (qs1@[x1]) (qs2@[x2])
let qid_equal q1 q2 = (qid_compare q1 q2 = 0)
	
let qid_prefix q1 q2 = 
  let (is1,i1) = q1 in
  let (is2,i2) = q2 in 
  let il1 = is1 @ [i1] in
  let il2 = is2 @ [i2] in
    ((Safelist.length il1) <= (Safelist.length il2)) 
    && (Safelist.for_all 
	  (fun (i1,i2) -> id_equal i1 i2)
	  (Safelist.combine il1 (Misc.take (Safelist.length il1) il2)))
	
let string_of_id (_,i) = i
let string_of_qid (q,i) = Misc.concat_list "." (Safelist.map string_of_id q@[string_of_id i])

let qid_hash q = Hashtbl.hash (string_of_qid q)

(* utility functions *)
let qid_of_id id = [],id
let id_of_string i s = (i,s)
let dot (qs1,x1) (qs2,x2) = (qs1@(x1::qs2),x2)


(* abstract syntax *)

(* sorts *)
type sort = 
    SName of i
  | SLens of i
  | SType of i 
  | SView of i  
  | SArrow of i * sort * sort
  | STOper of i * sort * sort

(* parameters *)
type param = PDef of i * id * sort

(* expressions *)
type exp = 
    EVar of i * qid
  | EFun of i * param list * sort option * exp 
  | EMap of i * (i * exp * exp) list
  | EApp of i * exp * exp
  | ELet of i * binding list * exp
  | EName of i * id
  | EType of i * typeexp
  | EView of i * (i * exp * exp) list 
  | EConsView of i * exp * exp

(* types *)
and typeexp = TT of ptypeexp | NT of ptypeexp 

and ptypeexp = 
    TEmpty of i
  | TAny of i
  | TVar of i * qid
  | TApp of i * ptypeexp * ptypeexp
  | TFun of i * id list * sort * ptypeexp (* only used internally *)
  | TName of i * exp * ptypeexp 
  | TBang of i * exp list * ptypeexp
  | TStar of i * exp list * ptypeexp
  | TCat of i * ptypeexp list 
  | TUnion of i * ptypeexp list
      
(* bindings *)
and binding = BDef of i * id * param list * sort option * exp

type typebinding = (id * id list * typeexp)

(* declarations *)
type decl = 
    DLet of i * binding list 
  | DType of i * typebinding list 
  | DMod of i * id * decl list 
  | DTestGet of i * exp * exp * exp option 
  | DTestPut of i * exp * (exp * exp option) * exp option
      
(* modules *)
type modl = MDef of i * id * qid list * decl list

(* simple constants *)
let emptyView i = EView(i,[])
let emptyViewType i = TStar(i,[], (TEmpty(i)))
  
(* accessor functions *)
let name_of_id (_,x) = x
let id_of_binding (BDef(_,x,_,_,_)) = x
let id_of_typebinding (x,_,_) = x

(* read off info fields *)
let info_of_list (e2i:'a -> Info.t) (i:Info.t) (l: 'a list) : Info.t = Safelist.fold_left (fun i ei -> Info.merge_inc (e2i ei) i) i l
let info_of_id = function (i,_) -> i
let info_of_qid = function (_,id) -> info_of_id id
let info_of_exp = function
    ELet(i,_,_) -> i
  | EFun(i,_,_,_) -> i
  | EApp(i,_,_) -> i
  | EVar(i,_) -> i
  | EName(i,_) -> i
  | EMap(i,_) -> i
  | EView(i,_) -> i
  | EConsView(i,_,_) -> i
  | EType(i,_) -> i

let info_of_ptypeexp = function
    TEmpty(i) -> i
  | TAny(i) -> i
  | TFun(i,_,_,_) -> i
  | TApp(i,_,_) -> i
  | TVar(i,_)   -> i
  | TStar(i,_,_) -> i
  | TBang(i,_,_) -> i
  | TName(i,_,_) -> i
  | TCat(i,_) -> i
  | TUnion(i,_t) -> i

let info_of_typeexp = function
    TT pt -> info_of_ptypeexp pt
  | NT pt -> info_of_ptypeexp pt

let info_of_sort = function
    SName(i)      -> i 
  | SLens(i)      -> i 
  | SType(i)      -> i 
  | SView(i)      -> i 
  | SArrow(i,_,_) -> i
  | STOper(i,_,_) -> i

let info_of_binding (BDef(i,_,_,_,_)) = i
let info_of_typebinding (x,_,t) = Info.merge_inc (info_of_id x) (info_of_typeexp t)
let info_of_bindings (i:Info.t) (bs:binding list) : Info.t = info_of_list info_of_binding i bs
let info_of_typebindings i ts = info_of_list info_of_typebinding i ts

(* read off pieces of parameters *)
let id_of_param = function PDef(_,x,_) -> x
let sort_of_param = function PDef(_,_,s) -> s

(* pretty printing stuff *)

(* sorts *)
let rec string_of_sort = function
    SName(_)        -> "name"
  | SLens(_)        -> "lens"
  | SType(_)        -> "type"
  | SView(_)        -> "view"
  | SArrow(_,s1,s2) -> sprintf "(%s -> %s)" (string_of_sort s1) (string_of_sort s2)
  | STOper(_,s1,s2) -> sprintf "(%s => %s)" (string_of_sort s1) (string_of_sort s2)

(* params *)
let string_of_param (PDef(_,i,s)) = Misc.parens(string_of_id i ^ ":" ^ string_of_sort s)

(* expressions *)
let rec string_of_exp = function 
    EVar(_,q)       -> string_of_qid q
  | EFun(_,ps,so,e) -> ("fun " 
			       ^ (Misc.concat_list " " (Safelist.map string_of_param ps))
			       ^ (match so with 
				    | None -> "" 
				    | Some s -> " : " ^ string_of_sort s)
			       ^ " -> "
			       ^ (string_of_exp e))
  | EApp(_,e1,e2)    -> Misc.parens (sprintf "%s %s" (string_of_exp e1) (string_of_exp e2))
  | EMap(_,ms)       -> 
      Misc.curlybraces (Misc.concat_list ", " 
		     (Safelist.map (fun (_,e1,e2) -> 
				      sprintf "%s -> %s"
					(string_of_exp e1)
					(string_of_exp e2))
			ms))
	
  | ELet(i,bs,e)     -> ("let " 
			 ^ (string_of_bindings bs)
			 ^ " in "
			 ^ (string_of_exp e))
  | EName(_,i)       -> string_of_id i
  | EType(_,t)       -> string_of_typeexp t
  | EView(_,vbs) -> 
      Misc.curlybraces
	(Misc.concat_list ", " 
	   (Safelist.map (fun (_,n,v) -> 
			    (string_of_exp n) 
			    ^ "=" 
			    ^ (string_of_exp v))
	      vbs))
  | EConsView(_,e1,e2) -> sprintf ("%s::%s") (string_of_exp e1) (string_of_exp e2)

and string_of_typeexp = function
  | TT pt -> string_of_ptypeexp pt
  | NT pt -> Misc.concat_list "" ["~"; "("; string_of_ptypeexp pt ;")"]

and string_of_ptypeexp = function 
    TEmpty(_)     -> "Empty"
  | TAny(_)       -> "Any"
  | TVar(_,q)     -> string_of_qid q
  | TFun(_,xs,s,pt)   -> 
      sprintf "tfun %s : %s => %s" 
	(Misc.concat_list ", " (List.map string_of_id xs))	
	(string_of_sort s)
	(string_of_ptypeexp pt)
  | TApp(_,pt1,pt2) -> Misc.concat_list "" ["("; string_of_ptypeexp pt1; " "; string_of_ptypeexp pt2; ")"]
  | TName(_,n,pt) -> sprintf "%s{%s}" (string_of_exp n) (string_of_ptypeexp pt)
  | TBang(_,f,pt)  ->
      Misc.concat_list ""
    	[ "!"
    	; if f = [] then "" else Misc.parens (Misc.concat_list " " (Safelist.map string_of_exp f))
    	; Misc.curlybraces (string_of_ptypeexp pt)]
  | TStar(_,f,pt)  ->
      Misc.concat_list ""
    	[ "*"
    	; if f = [] then "" else Misc.parens (Misc.concat_list " " (Safelist.map string_of_exp f))
    	; Misc.curlybraces (string_of_ptypeexp pt)]
  | TCat(_,cs) -> Misc.concat_list "," (Safelist.map string_of_ptypeexp cs)
  | TUnion(_,us) -> Misc.parens (Misc.concat_list " | " (Safelist.map string_of_ptypeexp us))

and string_of_binding (BDef(_,x,ps,so,e)) = 
  Misc.concat_list ""
    [string_of_id x
    ; Misc.concat_list " " (" " :: (Safelist.map string_of_param ps))
    ; (match so with 
	 | None -> ""
	 | Some s -> (" : " ^ string_of_sort s))
    ; " = "
    ; string_of_exp e]
and string_of_bindings bs = Misc.concat_list " and " (Safelist.map string_of_binding bs)

and string_of_typebinding (x,xs,t) = 
  sprintf "%s %s = %s"
    (string_of_id x)
    (Misc.concat_list " " (Safelist.map string_of_id xs))
    (string_of_typeexp t) 

and string_of_typebindings ts = 
  Misc.concat_list " and " (Safelist.map string_of_typebinding ts)

and string_of_decl = function
  | DLet(i,bs) -> "let " ^ (string_of_bindings bs)			
  | DType(i,ts) -> "type " ^ (string_of_typebindings ts)
  | DMod(_,i,ds) -> Misc.concat_list "" 
      (["module "
       ; string_of_id i
       ; " =\n"]
       @ (Safelist.map (fun di -> (string_of_decl di) ^ "\n") ds))
  | DTestGet(_) -> " TESTGET"
  | DTestPut(_) -> " TESTPUT"

let id_of_modl (MDef(_,m,_,_)) = m
let info_of_module (MDef(i,_,_,_)) = i

let string_of_module (MDef(_,id,qs,ds)) = 
  Misc.concat_list ""
    (["module "
     ; string_of_id id
     ; " =\n"
     ; (match qs with
	  | [] -> ""
	  | _  -> ("\nopen " ^ (Misc.concat_list "\n" (Safelist.map string_of_qid qs)) ^ "\nin"))
     ] @ (Safelist.map (fun di -> (string_of_decl di) ^ "\n") ds))

