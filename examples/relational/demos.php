<?

$demogroupname = "Relational Lenses";

$demo["democmd"] = "./harmonize-relational";
$demo["schema"] = "List.T Value";
$demo["r1format"] = $demo["r2format"] = "meta";
$demo["forcer1"] = true;
$demo["default_h"] = 200;
$demo["r1_title"] = "Database";
$demo["r2_title"] = "View";
$demo["l1_title"] = "Lens";
$demo["l1_d"] = true;
$demo["l2_d"] = false;
$demo["l2_title"] = "(Not needed)";
$demo["r1_shows"] = true;
$demo["l2"] = "id";
$demo["output_d"] = "block";
$demo["output_w"] = 450;

# ---------------------------------------------------------
$demo["instr"] = <<<XXX

<div id="section">Relational Lenses</div>

We have been experimenting recently with transferring ideas from the
domain of tree transformations, where Harmony started, to the more
"classical" domain of bi-directional transformations on relational
databases---often known as the <i>view update problem</i>.

<p>

The examples in this section are drawn from the paper <i>Relational
Lenses: A language for defining updateable views</i> (PODS 2006,
available <a href="../#BohannonPierceVaughan">here</a>).  
XXX;
$demo["splash"] = true;
savedemo();
# ---------------------------------------------------------
$demo["splash"] = false;
        
$demo["instr"] = <<<XXX

The panes below show a complete example of how Harmony's relational
lenses can be used to construct an updateable view of a small
database.  

<p>

The "Database" pane shows the source database---a collection of facts
about some independent music albums and songs such as might be
maintained by a record shop.  The triple brackets at the outside tell
Harmony's parser that this is relational data, not a tree.  Inside the
brackets are two tables: the Albums table keeps track of the number of
copies of each album in stock, while the Tracks table lists the
individual tracks on the albums, along with their dates and ratings.
Note that some tracks appear on multiple albums.  We also impose some
functional dependencies (formally, these are stated in the database's
schema, which we are not showing here): in the Albums table, there is
just one Quantity for a given Album, and in the Tracks table, there is
just one Date or Rating for a given Track.

<p>

The "View" pane shows a particular view of this data, defined by the
bi-directional program in the "Lens" pane.  It contains just one table
combining the columns from the original Albums and Tracks tables, and
it omits the Date column as well as all albums of which the store has
fewer than three copies.  

<p> 

The program in the "Lens" pane is composed from three primitive
operations: a join, a projection (which we write "drop," because it
projects away just one field at a time), and a selection.  Each of the
primitives carries annotations describing its "local" update
translation policy.  At the top is an "assert" records the expected
schema of the source database, and at the bottom is another "assert"
that records the schema of the view.

<p>

The following pages break this lens down into its components and
examines their behavior separately.  But to get started, let's try
making a few changes to the view and seeing how they are reflected in
the database.

<ul>
<li> ...
</ul>

XXX;

$demo["forcer1"] = true;
$demo["l1"] = <<<XXX
(* Schema of source database: *)
assert
  {{
     Albums(Album, Quantity) with {Album -> Quantity}, 
     Tracks(Track, Date, Rating, Album) with {Track -> Date, Track -> Rating}
  }} ;

(* Join Tracks with Albums to yield a new relation Tracks1 *)
Relational.join_dl "Tracks" with {Track -> Date, Track -> Rating}
  "Albums" with {Album -> Quantity}
  "Tracks1" ;

(* Drop the Date column from Tracks1 to yield a new relation Tracks2.  
   Use "unknown track" as the default value when new tuples are created 
   in the view.*)
Relational.drop "Tracks1" "Tracks2" "Date" {Track} "unknown date" ;

(* Select just tuples with quantity greater than 2, yielding a new
   relation Tracks3. *)
Relational.select "Tracks2" with {Album -> Quantity, Track -> Rating} "Tracks3"
  where (Quantity <> "0" /\ (Quantity <> "1" /\ Quantity <> "2")) ;

(* Schema of the final view: *)
assert
  {{
     Tracks3(Track, Rating, Album, Quantity)
       with {Album -> Quantity, Track -> Rating}
       where (Quantity <> "0" /\ (Quantity <> "1" /\ Quantity <> "2"))
  }}
XXX;
$demo["r1"] = <<<XXX
  {{{
    Albums (Album,           Quantity) = {
           (Disintegration,  6       )
           (Show,            3       )
           (Galore,          1       )
           (Paris,           4       )
           (Wish,            5       )   }

    Tracks (Track,    Date, Rating, Album) = {
           (Lulluby,  1989, 3,      Galore)
           (Lulluby,  1989, 3,      Show) 
           (Lovesong, 1989, 5,      Galore)
           (Lovesong, 1989, 5,      Paris)
           (Trust,    1992, 4,      Wish)
    }
  }}} 
XXX;
savedemo();
# ---------------------------------------------------------
$demo["instr"] = <<<XXX
(testing)
XXX;

$demo["l1"] = <<<XXX
Relational.join_dl "Tracks" with {Track -> Date, Track -> Rating}
  "Albums" with {Album -> Quantity}
    "Tracks1" 
;
Relational.drop "Tracks1" "Tracks2" "Date" {Track} "unknown date"
;
Relational.select "Tracks2" with {Album -> Quantity, Track -> Rating} "Tracks3"
  where (Quantity <> "0" /\ (Quantity <> "1" /\ Quantity <> "2"))
XXX;
$demo["r1"] = <<<XXX
  {{{
    Albums (Album,           Quantity) = {
           (Disintegration,  6       )
           (Show,            3       )
           (Galore,          1       )
           (Paris,           4       )
           (Wish,            5       )   }

    Tracks (Track,    Date, Rating, Album) = {
           (Lulluby,  1989, 3,      Galore)
           (Lulluby,  1989, 3,      Show) 
           (Lovesong, 1989, 5,      Galore)
           (Lovesong, 1989, 5,      Paris)
           (Trust,    1992, 4,      Wish)
    }
  }}} 
XXX;
$demo["r2"] = <<<XXX
{{{ Tracks3(Track, Rating, Album, Quantity) =
          {(Lovesong, 5, Paris, 4),
           (Lulluby, 3, Show, 3),
           (Trust, 4, Wish, 5)} }}}
XXX;
savedemo();
# ---------------------------------------------------------

