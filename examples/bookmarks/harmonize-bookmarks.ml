let orderedpref = Prefs.createBool "ordered" true "keep bookmark ordering" ""

let recompressPlists = Prefs.createBool "compress" false "convert plist files to binary form after sync" ""

let archNameUniquifier () =
  if Prefs.read orderedpref then "ord" else "nonord"

type bookmarkType = Mozilla | Safari | Meta

let bookmarktype2string = function
  | Mozilla -> "Mozilla"
  | Safari  -> "Safari"
  | Meta    -> "Meta"
        
let moz2xml f fpre =
  if Sys.file_exists f then
    Toplevel.runcmd (Printf.sprintf "./moz2xml < %s > %s" (Misc.whack f) (Misc.whack fpre))

let xml2moz fpost f =
  if Sys.file_exists fpost then
    Toplevel.runcmd (Printf.sprintf "./xml2moz < %s > %s" (Misc.whack fpost) (Misc.whack f))

let plutil f fpre =
  Toplevel.runcmd (Printf.sprintf "plutil -convert xml1 %s -o %s" (Misc.whack f) (Misc.whack fpre))

let plutilback f fpost =
  if Prefs.read recompressPlists then
    Toplevel.runcmd (Printf.sprintf "plutil -convert binary1 %s -o %s" (Misc.whack f) (Misc.whack fpost))
  else 
    Toplevel.runcmd (Printf.sprintf "cp %s %s" (Misc.whack f) (Misc.whack fpost))
  
let chooseEncoding f =
  if Filename.check_suffix f ".html" then ("xml",Mozilla,Some moz2xml,Some xml2moz)
  else if Filename.check_suffix f ".plist" then ("xml",Safari,Some plutil,Some plutilback)
  else if Filename.check_suffix f ".xml" then ("xml",Safari,None,None)
  else if Filename.check_suffix f ".meta" then ("meta",Meta,None,None)
  else raise Not_found

let chooseAbstractSchema types =
  let ordered = Prefs.read orderedpref in
  match types,ordered with
      [Safari],false -> "Bookmarks.BushAbstract"
    | _ -> "Bookmarks.Abstract"
        
let chooseLens t schema =
  match t,schema with
    Safari,"Bookmarks.Abstract"     -> "Safari.l2"
  | Safari,"Bookmarks.BushAbstract" -> "Safari.l3"
  | Mozilla,"Bookmarks.Abstract"    -> "Mozilla.l2"
  | Meta, "Bookmarks.Abstract"      -> "Prelude.id"
  | _                               -> assert false;;

Toplevel.toplevel
  "harmonize-bookmarks"
  archNameUniquifier
  chooseEncoding
  chooseAbstractSchema
  chooseLens
