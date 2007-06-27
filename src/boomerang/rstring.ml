(*********************************************************)
(* The Harmony Project                                   *)
(* harmony@lists.seas.upenn.edu                          *)
(*                                                       *)
(* fclstr.ml - an abstract implementation for strings    *)
(*********************************************************)
(* $Id$ *)
module SM = Map.Make(
  struct
    type t = string
    let compare (s1:string) s2 = compare s1 s2
  end)

module Int_array = 
struct
  module IM = Int.Map
  let map_repr = ref IM.empty
  let map_special = ref SM.empty
    
  let char_code_min = 0
  let char_code_max = 255

  let next_special = ref char_code_max
  type sym = int

  let leq (a:int) (b:int) = a <= b
  let l (a:int) (b:int) = a < b

  let compare_sym i1 i2 = 
    let diff = i1 - i2 in (* the substraction works because i1 and i2 are always positive *)
      if diff = 0 then 0
      else if diff < 0 then -1 
      else (*if diff > 0 then *) 1
  let of_char = Char.code
  let of_int = fun x -> x
  let to_int = fun x -> x

  let succ = succ
  let pred = pred

  let repr i = 
    if char_code_min <= i && i <= char_code_max then 
      String.make 1 (Char.chr i)
    else IM.find i !map_repr
  
  let size_of_repr i = 
    if char_code_min <= i && i <= char_code_max then 1
    else String.length (IM.find i !map_repr)

  let new_special s = 
    if SM.mem s !map_special then SM.find s !map_special 
    else
      begin
	incr next_special;
	map_repr := IM.add !next_special ("[." ^ s ^ ".]") !map_repr;
	map_special := SM.add s !next_special !map_special;
	!next_special
      end

  type t = int array
  
  let empty = Array.make 0 0

  let compare (a1:t) (a2:t) = 
    let n1 = Array.length a1 in
    let n2 = Array.length a2 in
      if n1 < n2 then -1
      else if n2 < n1 then 1 
      else
	(let rec loop i =
	   if i = n1 then 0 else
	     let xi1 = a1.(i) in
	     let xi2 = a2.(i) in
	       if xi1 < xi2 then -1
	       else if xi2 < xi1 then 1
	       else loop (succ i) in
	   loop 0)

  let of_string s = 
    let n = String.length s in
    let a = Array.make n 0 in
      for i = 0 to (pred n) do
	a.(i) <- Char.code (s.[i])
      done;
      a

  let to_string a = 
    let n = Array.length a in
    let rec loop_length i l = 
      if i = n then l else
	loop_length (succ i) (l + (size_of_repr a.(i))) in
    let l = loop_length 0 0 in
    let s = String.create l in
    let rec loop_fill ia is = 
      if ia = n then ()
      else
	let sr = repr a.(ia) in
	let srl = String.length sr in
	  String.blit sr 0 s is srl;
	  loop_fill (succ ia) (is + srl) in
      loop_fill 0 0;
      s
  
  let make = Array.make
  
  let length = Array.length
  
  let mk_box e = Array.make 1 e 

  let sub = Array.sub

  let get = Array.get
  
  let set = Array.set
  
  let append = Array.append

  let blit = Array.blit

  let escaped = String.escaped

  let escaped_repr i = escaped (repr i)
end

(* MAIN *)
module IM = Int.Map
let map_repr = ref IM.empty
let map_special = ref SM.empty
  
let char_code_min = 0
let char_code_max = 255
  
let next_special = ref char_code_max
type sym = int
    
let leq (a:int) (b:int) = a <= b
let l (a:int) (b:int) = a < b
  
let is_char e = 
  (char_code_min <= e) && (e <= char_code_max)
    
let is_lower e = 
  is_char e && (Char.code 'a' <= e) && (e <= Char.code 'z')
    
let is_upper e = 
  is_char e && (Char.code 'A' <= e) && (e <= Char.code 'Z')
    
let is_alpha e = (is_upper e || is_lower e)
  
let lowercase e = 
  if is_char e then Char.code (Char.lowercase (Char.chr e)) else e
    
let uppercase e = 
  if is_char e then Char.code (Char.uppercase (Char.chr e)) else e
    
let compare_sym i1 i2 = 
  let diff = i1 - i2 in (* the substraction works because i1 and i2 are always positive *)
    if diff = 0 then 0
    else if diff < 0 then -1 
    else (*if diff > 0 then *) 1
let of_char = Char.code
let of_int = fun x -> x
let to_int = fun x -> x
  
let succ = succ
let pred = pred
  
let repr i = 
  if char_code_min <= i && i <= char_code_max then 
    String.make 1 (Char.chr i)
  else IM.find i !map_repr
    
let size_of_repr i = 
  if char_code_min <= i && i <= char_code_max then 1
  else String.length (IM.find i !map_repr)
    
let new_special s = 
  if SM.mem s !map_special then SM.find s !map_special 
  else
    begin
      incr next_special;
      map_repr := IM.add !next_special ("[." ^ s ^ ".]") !map_repr;
      map_special := SM.add s !next_special !map_special;
      !next_special
    end
      
type u = FString of string | FArray of int array
type t = u ref
    
let empty = ref (FString "")
  
let comp t1 l1 get1 ti1 t2 l2 get2 ti2 = 
  if l1 < l2 then -1
  else if l2 < l1 then 1
  else let rec loop i = 
    if i = l1 then 0 else
      let e1 = ti1 (get1 t1 i) in
      let e2 = ti2 (get2 t2 i) in
	if e1 < e2 then -1
	else if e2 < e1 then 1
	else loop (succ i) in
         loop 0
	   
let id x = x
  
let compare (t1:t) (t2:t) =
  match !t1,!t2 with
    | FArray a1, FArray a2 ->
	comp a1 (Array.length a1) Array.get id a2 (Array.length a2) Array.get id
    | FString s1, FString s2 ->
	comp s1 (String.length s1) String.get id s2 (String.length s2) String.get id
    | FArray a1, FString s2 ->
	comp a1 (Array.length a1) Array.get id s2 (String.length s2) String.get Char.code
    | FString s1, FArray a2 ->
	comp s1 (String.length s1) String.get Char.code a2 (Array.length a2) Array.get id
          

let of_string s =
  ref (FString s)

let to_string t = match !t with
  | FString s -> s
  | FArray a -> 
      (let n = Array.length a in
      let rec loop_length i l = 
	if i = n then l else
	  loop_length (succ i) (l + (size_of_repr a.(i))) in
      let l = loop_length 0 0 in
      let s = String.make l 'X' in
      let rec loop_fill ia is = 
	if ia = n then ()
	else
	  let sr = repr a.(ia) in
	  let srl = String.length sr in
	    String.blit sr 0 s is srl;
	    loop_fill (succ ia) (is + srl) in
	loop_fill 0 0;
	s)
        
let make i e = 
  if is_char e then
    ref (FString (String.make i (Char.chr e)))
  else ref (FArray (Array.make i e ))
    
let length t = 
  match !t with 
    | FString s -> String.length s
    | FArray a -> Array.length a
        
let mk_box e = 
  ref (FArray (Array.make 1 e ))

let sub t i1 i2 = 
  match !t with
    | FString s -> ref (FString (String.sub s i1 i2))
    | FArray a -> ref (FArray (Array.sub a i1 i2))

let get t i =
  match !t with 
    | FString s -> Char.code (s.[i])
    | FArray a -> a.(i)
        
let array_of_string s = 
  let n = String.length s in
  let a = Array.make n 0 in
    for j = 0 to (pred n) do
      a.(j) <- Char.code s.[j]
    done;
    a

let set t i e =
  match !t with
    | FArray a -> a.(i) <- e
    | FString s ->
	if is_char e then s.[i] <- Char.chr e
	else
	  (let a = array_of_string s in
	     a.(i) <- e;
	    t := FArray a)

let append t1 t2 = 
  match !t1,!t2 with
    | FString s1, FString s2 -> 
	ref (FString ( s1 ^ s2))
    | FArray a1, FArray a2 -> 
	ref (FArray (Array.append a1 a2))
    | FString s1, FArray a2 -> 
	let a1 = array_of_string s1 in
	  ref (FArray (Array.append a1 a2))
    | FArray a1, FString s2 ->
	let a2 = array_of_string s2 in
	  ref (FArray (Array.append a1 a2))

	    
let blit src srcoff dst dstoff len = 
  match !src,!dst with
    | FString s1, FString s2 -> 
	String.blit s1 srcoff s2 dstoff len
    | FArray a1, FArray a2 -> 
	Array.blit a1 srcoff a2 dstoff len
    | FString s1, FArray a2 -> 
	let a1 = array_of_string s1 in
	  Array.blit a1 srcoff a2 dstoff len
    | FArray a1, FString s2 ->
	let a2 = array_of_string s2 in
	  Array.blit a1 srcoff a2 dstoff len

let split_prefix s1 s2 = 
  let go len sub ith mk t1 t2 = 
    let m = len t1 in 
    let n = len t2 in 
    let rec loop i = 
      if i=m then Some (ref (mk (sub t2 i (n-i))))
      else if ith t1 i = ith t2 i then loop (succ i)
      else None in 
      loop 0 in 
  let do_string = go String.length String.sub String.get (fun x -> FString x) in 
  let do_array = go Array.length Array.sub Array.get (fun x -> FArray x) in 
    match !s1,!s2 with
      | FString s1, FString s2 -> do_string s1 s2
      | FArray a1, FArray a2 -> do_array a1 a2 
      | FString s, FArray a -> do_array (array_of_string s) a
      | FArray a, FString s -> do_array a (array_of_string s)

let escaped = String.escaped

let escaped_repr i = escaped (repr i)

