(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, * CNRS-Ecole Polytechnique-INRIA Futurs-Universite Paris Sud *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(*i $Id: typeclasses_errors.mli 11282 2008-07-28 11:51:53Z msozeau $ i*)

(*i*)
open Names
open Decl_kinds
open Term
open Sign
open Evd
open Environ
open Nametab
open Mod_subst
open Topconstr
open Util
open Libnames
(*i*)

type contexts = Parameters | Properties

type typeclass_error = 
    | NotAClass of constr
    | UnboundMethod of global_reference * identifier located (* Class name, method *)
    | NoInstance of identifier located * constr list
    | UnsatisfiableConstraints of evar_defs * (evar_info * hole_kind) option
    | MismatchedContextInstance of contexts * constr_expr list * rel_context (* found, expected *)

exception TypeClassError of env * typeclass_error

val not_a_class : env -> constr -> 'a

val unbound_method : env -> global_reference -> identifier located -> 'a

val no_instance : env -> identifier located -> constr list -> 'a

val unsatisfiable_constraints : env -> evar_defs -> evar option -> 'a

val mismatched_ctx_inst : env -> contexts -> constr_expr list -> rel_context -> 'a
