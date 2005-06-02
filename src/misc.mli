(** Miscellaneous useful functions *)

(** {2 Hashtbl utility functions} *)

val safe_hash_add : ('a,'b) Hashtbl.t -> 'a -> 'b -> unit
(** [safe_hash_add ht key data] safely adds a binding between [key] and [data] in [ht].
    @raise Failure if a previous binding for [key] aldready existed *)

(** {2 List utility functions} *)

val enum : 'a list -> (int * 'a) list
(** [enum l] returns a list of pairs [(K,lK)] where the elements [lK] of the list [l]
    are associated with their position in [l] (starting at O). *)

val uniq : 'a list -> bool
(** [uniq l] returns [true] if and only if all the elements in [l] are different. *)

val union : 'a list -> 'a list -> 'a list
(** [union l1 l2] appends the list [l1] to [l2]. Elements that were already in [l2]
    are not appended. *)

val remove : 'a -> 'a list -> 'a list
(** [remove n l] returns the list [l] without the element [n]. *)

val safeheadtail : 'a list -> 'a option * 'a list
(** [safeheadtail l] returns the pair [(Some(hd l), tl l)] if [l] is not empty,
    and [(None, [])] otherwise. *)

val safetail : 'a list -> 'a list
(** [safetail l] returns the tail of [l] or [] if it encounters a failure. *)

val map_option : ('a -> 'b) -> 'a option -> 'b option
(** [map_option f o] returns [Some(f v)] if [o] is [Some v], and [None] otherwise. *)

val fold_left2 :
  ('a -> 'b option -> 'c option -> 'a) -> 'a -> 'b list -> 'c list -> 'a
(** [fold_left2 f a b c] is similar to [List.fold_left2], but the two lists can have different sizes since [f] uses options. *)

val fold_left3 :
  ('a -> 'b option -> 'c option -> 'd option -> 'a) ->
  'a -> 'b list -> 'c list -> 'd list -> 'a
(** [fold_left3 f a b c d] is similar to [fold_left2], but with three lists. *)

val fold_left2_with_pad :
  ('a -> 'b -> 'c -> 'a) -> 'a -> 'b list -> 'c list -> 'b -> 'c -> 'a
(** [fold_left2_with_pad f c xs ys padx ypadx] is similar to [fold_left2] but does not use options. Instead,
    [padx] (resp. [pady]) are passed to [f] if [xs] (resp. [ys]) is shorter than [ys] (resp. [xs]). *)

val map2opt : ('a option -> 'b option -> 'c) -> 'a list -> 'b list -> 'c list
(** [map2opt] is similar to [List.map2] but the function expects options, so the two lists do not have to be of the same size. *)

val map2_with_pad :
  ('a -> 'b -> 'c) -> 'a list -> 'b list -> 'a -> 'b -> 'c list
(** [map2_with_pad] is similar to [map2opt], but instead of using options, it uses the pads passed as arguments for missing values. *)

val zip_with_pad : 'a -> 'b -> 'a list -> 'b list -> ('a * 'b) list
(** [zip_with_pad pad1 pad2 l1 l2] returns the list of pairs of elements taken from [l1] and [l2]. [padx] and [pady] are being used
    for missing values when one list is shorter than the other. *)

val iter_with_sep : ('a -> unit) -> (unit -> 'b) -> 'a list -> unit
(** [iter_with_sep f fsep [x1;x2;...xn]] computes [f x1; fsep (); f x2; fsep (); ... ; f xn]. *)

val rev_and_flatten : 'a list list -> 'a list
(** [rev_and_flatten [l1; l2; ... ; ln]] returns [ln@...@l2@l1]. *)

val safeassoc : ('a * 'a) list -> 'a -> 'a
(** [safeassoc l a] returns [b] is there is some [(a,b)] in [l], and [a] otherwise. *)

val partition : int -> 'a list -> 'a list * 'a list
(** [partition n l] divides the list [l] into two segments, where the first
    segment has length [n]. If there are not [n] elements in [l], the result
    is [(l,[])]. *)

val take : int -> 'a list -> 'a list
(** [take n l] returns the [n] first elements of [l]. If [l] has less than [n] elements,
    then [l] is fully returned. *)

val composel : ('a -> 'a) list -> ('a -> 'a)
(** composes a list of functions,  applying the leftmost function first. *)

(** {2 Exceptions} *)

exception Bad of string
val bad : string -> 'a
(** [bad s] raises Bad s. *)

exception Unimplemented of string

(** {2 String utility functions} *)

val escape : (char -> string) -> string -> string
(** [escape escapeChar s] returns [s] where every char in [s] has been escaped with [escapeChar]. *)

val unescaped : string -> string 
(** [unescaped] is the inverse of String.escaped. *)

val generic_escape_char : string -> char -> string
(** Escapes all instances of the char passed as argument in the string passed as argument with a \, and returns the result.
    Also replaces \ with \\. *)

val generic_unescape : string -> string
(** Replaces every \x in the string with x, and returns the result. *)

val index_rec_nonescape : string -> int -> char -> int
(** [index_rec_nonescape s i c] returns the leftmost occurrence of [c] greater or equal than [i],
    skippin all escaped characters, e.g., "\c". *)

val split_nonescape : char -> string -> string list
(** [split_nonescape c text] splits the string [text] according to non-escaped occurrences of [c]. *)

val is_blank : string -> bool
(** Returns true if the string consists only in blank characters, ie spaces, new lines and tabulations. *)

val bounded_index_from : string -> int -> int -> char -> int
(** [bounded_index_from buf pos len char] returns the leftmost position of [c] in the substring of [buf] at position [pos] and length [len].
    @raise Not_found if [c] does not appear in that substring. *)

val findsubstring : string -> string -> int option
(** [findsubstring s1 s2] finds the leftmost occurrence of [s1] in [s2] and returns its position. Returns [None] is [s1] is not to be found in [s2]. *)

val trimLeadingSpaces : string -> string
(** Returns the string without its leading spaces. *)

val replace_substring : string -> string -> string -> string
(** [replace_substring s froms tos] returns [s] where all occurrences of [froms] have been replaced by [tos]. *)

val replace_substrings : string -> (string * string) list -> string
(** [replace_substrings] is similar to [replace_substring], but iterates on a list of substitution. The leftmost substitution is applied first. *)

val whack_chars : string -> char list -> string
(** [whack_chars s cl] escapes [s], puts it between double quotes if it contains some of the characters in [cl], and returns the result.*)

val whack : string -> string
(** [whack s = whack_chars s [' ';'"']] *)

val unwhack : string -> string
(** the (almost) inverse of [whack_chars] *)

val hexify_string : string -> string

val splitIntoWords : string -> char -> string list
(** [splitIntoWords s c] splits [s] into words separated by [c], and returns them as a list. *)

val filename_extension : string -> string
(** returns the extension of a filename. *)

type color = Black | Red | Green | Yellow | Blue | Pink | Cyan | White
val color : string -> ?bold:bool -> color -> string
(** ansi-colors a string.  defaults to not bold. *)

(** {2 File handling functions} *)

val is_dir : string -> bool
(** [is_dir f] evaluates to true iff the file at location f is a directory *)

val mkdir_forsure : string -> unit
(** [mkdir_forsure d] checks if a directory exists.  If not, it tries to make it. *)

val read_dir : string -> string list
(** [read_dir dir] evaluates to the list of files within [dir]. *)

val in_dir : string -> (unit -> 'a) -> 'a
(** [in_dir d f] evaluates the function [f] with the working directory set to
    [d], and restores the original working directory before returning. *)

val remove_file_or_dir : string -> unit
(** [remove_file_or_dir s] has the same behaviour as {i rm -rf s}. *)

val read : string -> string
(** Reads a file and returns its contents as a string. *)

val write : string -> string -> unit
(** [write file s] opens file and erase every previous contents to [s]. If the file did not exist, it is created. *)

val backup : string -> unit
(** Writes a backup of the filename passed as argument. *)

val tempFileName : string -> string
(** Returns a fresh temporary filename tagged with the string passed as argument. *)

(** {2 I/O}*)

val read_char : unit -> char
(** Reads a char from the shell.*)

(** {2 Dynamically scoped variables} *)

val dynamic_var : 'a -> 'a ref
(** Returns a reference containing the value passed as argument. *)

val dynamic_lookup : 'a ref -> 'a
(** [dynamic_lookup d = !d]*)

val dynamic_bind : 'a ref -> 'a -> (unit -> 'b) -> 'b
(** [dynamic_bind d v f] executes [f] with [d] containing [v], and then restores [d]'s original value. *)
