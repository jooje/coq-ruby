(* Check the behaviour of Discriminate *)

(* Check that Discriminate tries Intro until *)

Lemma l1 : 0 = 1 -> False.   
 discriminate 1.
Qed.

Lemma l2 : forall H : 0 = 1, H = H.   
 discriminate H.
Qed.

(* Check the variants of discriminate *)

Goal O = S O -> True.
discriminate 1.
Undo.
intros.
discriminate H.
Undo.
Ltac g x := discriminate x.
g H.
Abort.

Goal (forall x y : nat, x = y -> x = S y) -> True.
intros.
try discriminate (H O) || exact I.
Qed.

Goal (forall x y : nat, x = y -> x = S y) -> True.
intros.
ediscriminate (H O).
instantiate (1:=O).
Abort.
