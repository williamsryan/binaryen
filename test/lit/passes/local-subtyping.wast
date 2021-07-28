;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s --local-subtyping -all -S -o - \
;; RUN:   | filecheck %s

(module
  ;; CHECK:      (import "out" "i32" (func $i32 (result i32)))
  (import "out" "i32" (func $i32 (result i32)))
  ;; CHECK:      (import "out" "i64" (func $i64 (result i64)))
  (import "out" "i64" (func $i64 (result i64)))

  ;; Refinalization can find a more specific type, where the declared type was
  ;; not the optimal LUB.
  ;; CHECK:      (func $refinalize (param $x i32)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (if (result (ref func))
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:    (ref.func $i32)
  ;; CHECK-NEXT:    (ref.func $i64)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (block $block (result (ref func))
  ;; CHECK-NEXT:    (br $block
  ;; CHECK-NEXT:     (ref.func $i32)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (ref.func $i64)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $refinalize (param $x i32)
    (drop
      (if (result anyref)
        (local.get $x)
        (ref.func $i32)
        (ref.func $i64)
      )
    )
    (drop
      (block $block (result anyref)
        (br $block
          (ref.func $i32)
        )
        (ref.func $i64)
      )
    )
  )

  ;; A simple case where a local has a single assignment that we can use as a
  ;; more specific type. A similar thing with a parameter, however, is not a
  ;; thing we can optimize. Also, ignore a local with zero assignments.
  ;; CHECK:      (func $simple-local-but-not-param (param $x anyref)
  ;; CHECK-NEXT:  (local $y (ref null $none_=>_i32))
  ;; CHECK-NEXT:  (local $unused anyref)
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (ref.func $i32)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $y
  ;; CHECK-NEXT:   (ref.func $i32)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $simple-local-but-not-param (param $x anyref)
    (local $y anyref)
    (local $unused anyref)
    (local.set $x
      (ref.func $i32)
    )
    (local.set $y
      (ref.func $i32)
    )
  )

  ;; CHECK:      (func $locals-with-multiple-assignments
  ;; CHECK-NEXT:  (local $x funcref)
  ;; CHECK-NEXT:  (local $y (ref null $none_=>_i32))
  ;; CHECK-NEXT:  (local $z (ref null $none_=>_i64))
  ;; CHECK-NEXT:  (local $w funcref)
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (ref.func $i32)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (ref.func $i64)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $y
  ;; CHECK-NEXT:   (ref.func $i32)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $y
  ;; CHECK-NEXT:   (ref.func $i32)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $z
  ;; CHECK-NEXT:   (ref.func $i64)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $z
  ;; CHECK-NEXT:   (ref.func $i64)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $w
  ;; CHECK-NEXT:   (ref.func $i32)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $w
  ;; CHECK-NEXT:   (ref.func $i64)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $locals-with-multiple-assignments
    (local $x anyref)
    (local $y anyref)
    (local $z anyref)
    (local $w funcref)
    ;; x is assigned two different types with a new LUB possible
    (local.set $x
      (ref.func $i32)
    )
    (local.set $x
      (ref.func $i64)
    )
    ;; y and z are assigned the same more specific type twice
    (local.set $y
      (ref.func $i32)
    )
    (local.set $y
      (ref.func $i32)
    )
    (local.set $z
      (ref.func $i64)
    )
    (local.set $z
      (ref.func $i64)
    )
    ;; w is assigned two different types *without* a new LUB possible, as it
    ;; already had the optimal LUB
    (local.set $w
      (ref.func $i32)
    )
    (local.set $w
      (ref.func $i64)
    )
  )

  ;; In some cases multiple iterations are necessary, as one inferred new type
  ;; applies to a get which then allows another inference.
  ;; CHECK:      (func $multiple-iterations
  ;; CHECK-NEXT:  (local $x (ref null $none_=>_i32))
  ;; CHECK-NEXT:  (local $y (ref null $none_=>_i32))
  ;; CHECK-NEXT:  (local $z (ref null $none_=>_i32))
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (ref.func $i32)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $y
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $z
  ;; CHECK-NEXT:   (local.get $y)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $multiple-iterations
    (local $x anyref)
    (local $y anyref)
    (local $z anyref)
    (local.set $x
      (ref.func $i32)
    )
    (local.set $y
      (local.get $x)
    )
    (local.set $z
      (local.get $y)
    )
  )

  ;; Sometimes a refinalize is necessary in between the iterations.
  ;; CHECK:      (func $multiple-iterations-refinalize (param $i i32)
  ;; CHECK-NEXT:  (local $x (ref null $none_=>_i32))
  ;; CHECK-NEXT:  (local $y (ref null $none_=>_i64))
  ;; CHECK-NEXT:  (local $z funcref)
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (ref.func $i32)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $y
  ;; CHECK-NEXT:   (ref.func $i64)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $z
  ;; CHECK-NEXT:   (select (result funcref)
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:    (local.get $y)
  ;; CHECK-NEXT:    (local.get $i)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $multiple-iterations-refinalize (param $i i32)
    (local $x anyref)
    (local $y anyref)
    (local $z anyref)
    (local.set $x
      (ref.func $i32)
    )
    (local.set $y
      (ref.func $i64)
    )
    (local.set $z
      (select
        (local.get $x)
        (local.get $y)
        (local.get $i)
      )
    )
  )

  ;; CHECK:      (func $nondefaultable
  ;; CHECK-NEXT:  (local $x (anyref anyref))
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (tuple.make
  ;; CHECK-NEXT:    (ref.func $i32)
  ;; CHECK-NEXT:    (ref.func $i32)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $nondefaultable
    (local $x (anyref anyref))
    ;; This tuple is assigned non-nullable values, which means the subtype is
    ;; nondefaultable, and we must not apply it.
    (local.set $x
      (tuple.make
        (ref.func $i32)
        (ref.func $i32)
      )
    )
  )
)