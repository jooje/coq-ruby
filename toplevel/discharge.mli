(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, * CNRS-Ecole Polytechnique-INRIA Futurs-Universite Paris Sud *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(*i $Id: discharge.mli 6748 2005-02-18 22:17:50Z herbelin $ i*)

open Sign
open Cooking
open Declarations
open Entries

val process_inductive : 
  named_context -> work_list -> mutual_inductive_body -> mutual_inductive_entry
