(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, * CNRS-Ecole Polytechnique-INRIA Futurs-Universite Paris Sud *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(*i $Id: flags.ml 11801 2009-01-18 20:11:41Z herbelin $ i*)

let with_option o f x =
  let old = !o in o:=true;
  try let r = f x in o := old; r
  with e -> o := old; raise e

let without_option o f x =
  let old = !o in o:=false;
  try let r = f x in o := old; r
  with e -> o := old; raise e

let boot = ref false

let batch_mode = ref false

let debug = ref false

let print_emacs = ref false
let print_emacs_safechar = ref false

let term_quality = ref false

let xml_export = ref false

let dont_load_proofs = ref false

let raw_print = ref false

let unicode_syntax = ref false

(* Translate *)
let beautify = ref false
let make_beautify f = beautify := f
let do_beautify () = !beautify
let beautify_file = ref false

(* Silent / Verbose *)
let silent = ref false
let make_silent flag = silent := flag; ()
let is_silent () = !silent
let is_verbose () = not !silent

let silently f x = with_option silent f x
let verbosely f x = without_option silent f x

let if_silent f x = if !silent then f x
let if_verbose f x = if not !silent then f x

let hash_cons_proofs = ref true

let warn = ref true
let make_warn flag = warn := flag;  ()
let if_warn f x = if !warn then f x

(* The number of printed hypothesis in a goal *)

let print_hyps_limit = ref (None : int option)
let set_print_hyps_limit n = print_hyps_limit := n
let print_hyps_limit () = !print_hyps_limit

(* A list of the areas of the system where "unsafe" operation
 * has been requested *)

module Stringset = Set.Make(struct type t = string let compare = compare end)

let unsafe_set = ref Stringset.empty
let add_unsafe s = unsafe_set := Stringset.add s !unsafe_set
let is_unsafe s = Stringset.mem s !unsafe_set

(* Flags for the virtual machine *)

let boxed_definitions = ref true
let set_boxed_definitions b = boxed_definitions := b
let boxed_definitions _ = !boxed_definitions 
 
(* Flags for external tools *)

let subst_command_placeholder s t =
  let buff = Buffer.create (String.length s + String.length t) in
  let i = ref 0 in
  while (!i < String.length s) do
    if s.[!i] = '%' & !i+1 < String.length s & s.[!i+1] = 's'
    then (Buffer.add_string buff t;incr i)
    else Buffer.add_char buff s.[!i];
    incr i
  done;
  Buffer.contents buff

let browser_cmd_fmt =
 try
  let coq_netscape_remote_var = "COQREMOTEBROWSER" in
  Sys.getenv coq_netscape_remote_var
 with
  Not_found -> Coq_config.browser

(* Options for changing coqlib *)
let coqlib_spec = ref false
let coqlib = ref Coq_config.coqlib

(* Options for changing camlbin (used by coqmktop) *)
let camlbin_spec = ref false
let camlbin = ref Coq_config.camlbin

(* Options for changing camlp4bin (used by coqmktop) *)
let camlp4bin_spec = ref false
let camlp4bin = ref Coq_config.camlp4bin

