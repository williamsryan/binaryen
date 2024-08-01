;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.

;; Test that we can write a binary without crashing when using shared reference
;; types without GC enabled.

;; RUN: wasm-opt %s --enable-reference-types --enable-shared-everything --roundtrip -S -o - | filecheck %s

(module
 ;; CHECK:      (func $null
 ;; CHECK-NEXT:  (drop
 ;; CHECK-NEXT:   (ref.null (shared nofunc))
 ;; CHECK-NEXT:  )
 ;; CHECK-NEXT: )
 (func $null
  (drop
   (ref.null (shared func))
  )
 )

 ;; CHECK:      (func $signature (result (ref null (shared func)))
 ;; CHECK-NEXT:  (unreachable)
 ;; CHECK-NEXT: )
 (func $signature (result (ref null (shared func)))
  (unreachable)
 )
)