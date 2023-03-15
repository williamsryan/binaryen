;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.

;; RUN: wasm-opt -all --roundtrip %s -S -o - | filecheck %s

;; Check that annotated select is propery roundtripped, even if the type is
;; only used in that one place in the whole module.

(module
  ;; CHECK:      (type $struct (struct ))
  (type $struct (struct))

  ;; CHECK:      (func $foo (type $none_=>_anyref) (result anyref)
  ;; CHECK-NEXT:  (select (result (ref null $struct))
  ;; CHECK-NEXT:   (ref.null none)
  ;; CHECK-NEXT:   (ref.null none)
  ;; CHECK-NEXT:   (i32.const 1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $foo (result anyref)
    (select (result (ref null $struct))
      (ref.null any)
      (ref.null eq)
      (i32.const 1)
    )
  )
)