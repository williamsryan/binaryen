;; NOTE: Assertions have been generated by update_lit_checks.py --output=fuzz-exec and should not be edited.

;; RUN: wasm-opt %s -all --fuzz-exec-before -q -o /dev/null 2>&1 | filecheck %s

(module
 (type $i32 (func (result i32)))

 (table $table 32 32 funcref)

 (func $i32 (type $i32) (result i32)
  (i32.const 0)
 )

 ;; CHECK:      [fuzz-exec] calling fill
 ;; CHECK-NEXT: [trap out of bounds table access]
 (func $fill (export "fill")
  ;; This fill is out of bounds as the -1 is unsigned. Nothing will be written.
  (table.fill $table
   (i32.const 1)
   (ref.func $i32)
   (i32.const -1)
  )
 )
 ;; CHECK:      [fuzz-exec] calling call
 ;; CHECK-NEXT: [trap uninitialized table element]
 (func $call (export "call") (result i32)
  ;; Nothing was written, so this traps.
  (call_indirect $table (type $i32)
   (i32.const 1)
  )
 )
)