(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, * CNRS-Ecole Polytechnique-INRIA Futurs-Universite Paris Sud *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(*i $Id: vernacexpr.ml 12187 2009-06-13 19:36:59Z msozeau $ i*)

open Util
open Names
open Tacexpr
open Extend
open Genarg
open Topconstr
open Decl_kinds
open Ppextend

(* Toplevel control exceptions *)
exception ProtectedLoop
exception Drop
exception Quit

open Libnames
open Nametab

type lident = identifier located
type lname = name located
type lstring = string
type lreference = reference

type class_rawexpr = FunClass | SortClass | RefClass of reference
  
type printable =
  | PrintTables
  | PrintFullContext
  | PrintSectionContext of reference
  | PrintInspect of int
  | PrintGrammar of string
  | PrintLoadPath of dir_path option
  | PrintModules
  | PrintModule of reference
  | PrintModuleType of reference
  | PrintMLLoadPath
  | PrintMLModules
  | PrintName of reference
  | PrintOpaqueName of reference
  | PrintGraph
  | PrintClasses
  | PrintTypeClasses
  | PrintInstances of reference
  | PrintLtac of reference
  | PrintCoercions
  | PrintCoercionPaths of class_rawexpr * class_rawexpr
  | PrintCanonicalConversions
  | PrintUniverses of string option
  | PrintHint of reference
  | PrintHintGoal
  | PrintHintDbName of string
  | PrintRewriteHintDbName of string
  | PrintHintDb
  | PrintScopes
  | PrintScope of string
  | PrintVisibility of string option
  | PrintAbout of reference
  | PrintImplicit of reference
  | PrintAssumptions of bool * reference

type search_about_item =
  | SearchSubPattern of constr_pattern_expr
  | SearchString of string * scope_name option

type searchable =
  | SearchPattern of constr_pattern_expr
  | SearchRewrite of constr_pattern_expr
  | SearchHead of reference
  | SearchAbout of (bool * search_about_item) list

type locatable =
  | LocateTerm of reference
  | LocateLibrary of reference
  | LocateModule of reference
  | LocateFile of string
  | LocateNotation of notation

type goable =
  | GoTo of int
  | GoTop
  | GoNext
  | GoPrev

type showable =
  | ShowGoal of int option
  | ShowGoalImplicitly of int option
  | ShowProof
  | ShowNode
  | ShowScript
  | ShowExistentials
  | ShowTree
  | ShowProofNames
  | ShowIntros of bool
  | ShowMatch of lident
  | ShowThesis
  | ExplainProof of int list
  | ExplainTree of int list

type comment =
  | CommentConstr of constr_expr
  | CommentString of string
  | CommentInt of int

type hints =
  | HintsResolve of (int option * bool * constr_expr) list
  | HintsImmediate of constr_expr list
  | HintsUnfold of reference list
  | HintsTransparency of reference list * bool
  | HintsConstructors of reference list
  | HintsExtern of int * constr_expr option * raw_tactic_expr
  | HintsDestruct of identifier *
      int * (bool,unit) location * constr_expr * raw_tactic_expr

type search_restriction =
  | SearchInside of reference list
  | SearchOutside of reference list

type option_value =
  | StringValue of string
  | IntValue of int
  | BoolValue of bool

type option_ref_value =
  | StringRefValue of string
  | QualidRefValue of reference

type rec_flag       = bool (* true = Rec;           false = NoRec          *)
type verbose_flag   = bool (* true = Verbose;       false = Silent         *)
type opacity_flag   = bool (* true = Opaque;        false = Transparent    *)
type locality_flag  = bool (* true = Local;         false = Global         *)
type coercion_flag  = bool (* true = AddCoercion;   false = NoCoercion     *)
type export_flag    = bool (* true = Export;        false = Import         *)
type specif_flag    = bool (* true = Specification; false = Implementation *)
type inductive_flag = Decl_kinds.recursivity_kind
type onlyparsing_flag = bool (* true = Parse only;  false = Print also     *)

type sort_expr = Rawterm.rawsort

type definition_expr =
  | ProveBody of local_binder list * constr_expr
  | DefineBody of local_binder list * raw_red_expr option * constr_expr
      * constr_expr option

type local_decl_expr =
  | AssumExpr of lname * constr_expr
  | DefExpr of lname * constr_expr * constr_expr option

type inductive_kind = Inductive_kw | CoInductive | Record | Structure | Class of bool (* true = definitional, false = inductive *)
type decl_notation = (string * constr_expr * scope_name option) option
type simple_binder = lident list  * constr_expr
type class_binder = lident * constr_expr list
type 'a with_coercion = coercion_flag * 'a
type 'a with_notation = 'a * decl_notation
type constructor_expr = (lident * constr_expr) with_coercion
type constructor_list_or_record_decl_expr =
  | Constructors of constructor_expr list
  | RecordDecl of lident option * local_decl_expr with_coercion with_notation list
type inductive_expr =
  lident with_coercion * local_binder list * constr_expr option * inductive_kind * 
    constructor_list_or_record_decl_expr

type module_binder = bool option * lident list * module_type_ast

type grammar_production =
  | VTerm of string
  | VNonTerm of loc * string * Names.identifier option

type proof_end =
  | Admitted
  | Proved of opacity_flag * (lident * theorem_kind option) option

type scheme =
  | InductionScheme of bool * lreference * sort_expr
  | EqualityScheme of lreference

type vernac_expr =
  (* Control *)
  | VernacList of located_vernac_expr list
  | VernacLoad of verbose_flag * lstring
  | VernacTime of vernac_expr

  (* Syntax *) 
  | VernacTacticNotation of int * grammar_production list * raw_tactic_expr
  | VernacSyntaxExtension of locality_flag * (lstring * syntax_modifier list)
  | VernacOpenCloseScope of (locality_flag * bool * scope_name)
  | VernacDelimiters of scope_name * lstring
  | VernacBindScope of scope_name * class_rawexpr list
  | VernacArgumentsScope of locality_flag * lreference * scope_name option list
  | VernacInfix of locality_flag * (lstring * syntax_modifier list) *
      lreference * scope_name option
  | VernacNotation of
      locality_flag * constr_expr * (lstring * syntax_modifier list) *
      scope_name option

  (* Gallina *)
  | VernacDefinition of definition_kind * lident * definition_expr * 
      declaration_hook
  | VernacStartTheoremProof of theorem_kind * 
      (lident option * (local_binder list * constr_expr)) list *
        bool * declaration_hook
  | VernacEndProof of proof_end
  | VernacExactProof of constr_expr
  | VernacAssumption of assumption_kind * bool * simple_binder with_coercion list
  | VernacInductive of inductive_flag * (inductive_expr * decl_notation) list
  | VernacFixpoint of (fixpoint_expr * decl_notation) list * bool
  | VernacCoFixpoint of (cofixpoint_expr * decl_notation) list * bool
  | VernacScheme of (lident option * scheme) list
  | VernacCombinedScheme of lident * lident list

  (* Gallina extensions *)
  | VernacBeginSection of lident
  | VernacEndSegment of lident
  | VernacRequire of
      export_flag option * specif_flag option * lreference list
  | VernacImport of export_flag * lreference list
  | VernacCanonical of lreference
  | VernacCoercion of locality * lreference * class_rawexpr * class_rawexpr
  | VernacIdentityCoercion of locality * lident * 
      class_rawexpr * class_rawexpr

  (* Type classes *)
(*   | VernacClass of *)
(*       lident * (\* name *\) *)
(* 	local_binder list * (\* params *\) *)
(* 	sort_expr located option * (\* arity *\) *)
(* 	local_binder list * (\* constraints *\) *)
(* 	(lident * bool * constr_expr) list (\* props, with substructure hints *\) *)
	
  | VernacInstance of
      bool * (* global *)
      local_binder list * (* super *)
	typeclass_constraint * (* instance name, class name, params *)
	constr_expr * (* props *)
	int option (* Priority *)

  | VernacContext of local_binder list
	
  | VernacDeclareInstance of
      lident (* instance name *)

  (* Modules and Module Types *)
  | VernacDeclareModule of bool option * lident * 
      module_binder list * (module_type_ast * bool)
  | VernacDefineModule of bool option * lident * 
      module_binder list * (module_type_ast * bool) option * module_ast option
  | VernacDeclareModuleType of lident * 
      module_binder list * module_type_ast option
  | VernacInclude of include_ast

  (* Solving *)

  | VernacSolve of int * raw_tactic_expr * bool
  | VernacSolveExistential of int * constr_expr

  (* Proof Mode *)

  | VernacDeclProof
  | VernacReturn
  | VernacProofInstr of Decl_expr.raw_proof_instr


  (* Auxiliary file and library management *)
  | VernacRequireFrom of export_flag option * specif_flag option * lstring
  | VernacAddLoadPath of rec_flag * lstring * dir_path option
  | VernacRemoveLoadPath of lstring
  | VernacAddMLPath of rec_flag * lstring
  | VernacDeclareMLModule of lstring list
  | VernacChdir of lstring option

  (* State management *)
  | VernacWriteState of lstring
  | VernacRestoreState of lstring

  (* Resetting *)
  | VernacRemoveName of lident
  | VernacResetName of lident
  | VernacResetInitial
  | VernacBack of int
  | VernacBackTo of int

  (* Commands *)
  | VernacDeclareTacticDefinition of
      rec_flag * (reference * bool * raw_tactic_expr) list
  | VernacCreateHintDb of locality_flag * lstring * bool
  | VernacHints of locality_flag * lstring list * hints
  | VernacSyntacticDefinition of identifier located * (identifier list * constr_expr) *
      locality_flag * onlyparsing_flag
  | VernacDeclareImplicits of locality_flag * lreference * 
      (explicitation * bool * bool) list option
  | VernacReserve of lident list * constr_expr
  | VernacSetOpacity of
      locality_flag * (Conv_oracle.level * lreference list) list
  | VernacUnsetOption of Goptions.option_name
  | VernacSetOption of Goptions.option_name * option_value
  | VernacAddOption of Goptions.option_name * option_ref_value list
  | VernacRemoveOption of Goptions.option_name * option_ref_value list
  | VernacMemOption of Goptions.option_name * option_ref_value list
  | VernacPrintOption of Goptions.option_name
  | VernacCheckMayEval of raw_red_expr option * int option * constr_expr
  | VernacGlobalCheck of constr_expr
  | VernacPrint of printable
  | VernacSearch of searchable * search_restriction
  | VernacLocate of locatable
  | VernacComments of comment list
  | VernacNop

  (* Proof management *)
  | VernacGoal of constr_expr
  | VernacAbort of lident option
  | VernacAbortAll
  | VernacRestart
  | VernacSuspend
  | VernacResume of lident option
  | VernacUndo of int
  | VernacUndoTo of int
  | VernacBacktrack of int*int*int
  | VernacFocus of int option
  | VernacUnfocus
  | VernacGo of goable
  | VernacShow of showable
  | VernacCheckGuard
  | VernacProof of raw_tactic_expr
  (* Toplevel control *)
  | VernacToplevelControl of exn

  (* For extension *)
  | VernacExtend of string * raw_generic_argument list

and located_vernac_expr = loc * vernac_expr

(* Locating errors raised just after the dot is parsed but before the
   interpretation phase *)

exception DuringSyntaxChecking of exn

let syntax_checking_error s = 
  raise (DuringSyntaxChecking (UserError ("",Pp.str s)))

(* Managing locality *)

let locality_flag = ref None

let local_of_bool = function true -> Local | false -> Global

let check_locality () =
  if !locality_flag = Some true then
    syntax_checking_error "This command does not support the \"Local\" prefix.";
  if !locality_flag = Some false then
    syntax_checking_error "This command does not support the \"Global\" prefix."

let use_locality () =
  let local = match !locality_flag with Some true -> true | _ -> false in
  locality_flag := None;
  local

let use_locality_exp () = local_of_bool (use_locality ())

let use_section_locality () =
  let local = 
    match !locality_flag with Some b -> b | None -> Lib.sections_are_opened ()
  in
  locality_flag := None;
  local

let use_non_locality () =
  let local = match !locality_flag with Some false -> false | _ -> true in
  locality_flag := None;
  local

let enforce_locality () =
  let local =
    match !locality_flag with 
    | Some false ->
	error "Cannot be simultaneously Local and Global."
    | _ -> 
	Flags.if_verbose
	  Pp.warning "Obsolete syntax: use \"Local\" as a prefix."; 
	true in
  locality_flag := None;
  local

let enforce_locality_exp () = local_of_bool (enforce_locality ())

let enforce_locality_of local =
  let local = 
    match !locality_flag with 
    | Some false when local ->
	error "Cannot be simultaneously Local and Global."
    | Some true when local ->
	error "Use only prefix \"Local\"."
    | None ->
	if local then
	  Flags.if_verbose
	    Pp.warning "Obsolete syntax: use \"Local\" as a prefix.";
	local
    | Some b -> b in
  locality_flag := None;
  local
