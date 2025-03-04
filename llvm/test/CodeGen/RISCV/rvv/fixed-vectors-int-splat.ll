; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv32 -mattr=+v -riscv-v-vector-bits-min=128 -riscv-v-fixed-length-vector-lmul-max=8 -verify-machineinstrs < %s | FileCheck %s --check-prefixes=CHECK,LMULMAX8,LMULMAX8-RV32
; RUN: llc -mtriple=riscv32 -mattr=+v -riscv-v-vector-bits-min=128 -riscv-v-fixed-length-vector-lmul-max=2 -verify-machineinstrs < %s | FileCheck %s --check-prefixes=CHECK,LMULMAX2,LMULMAX2-RV32
; RUN: llc -mtriple=riscv32 -mattr=+v -riscv-v-vector-bits-min=128 -riscv-v-fixed-length-vector-lmul-max=1 -verify-machineinstrs < %s | FileCheck %s --check-prefixes=CHECK,LMULMAX1,LMULMAX1-RV32
; RUN: llc -mtriple=riscv64 -mattr=+v -riscv-v-vector-bits-min=128 -riscv-v-fixed-length-vector-lmul-max=8 -verify-machineinstrs < %s | FileCheck %s --check-prefixes=CHECK,LMULMAX8,LMULMAX8-RV64
; RUN: llc -mtriple=riscv64 -mattr=+v -riscv-v-vector-bits-min=128 -riscv-v-fixed-length-vector-lmul-max=2 -verify-machineinstrs < %s | FileCheck %s --check-prefixes=CHECK,LMULMAX2,LMULMAX2-RV64
; RUN: llc -mtriple=riscv64 -mattr=+v -riscv-v-vector-bits-min=128 -riscv-v-fixed-length-vector-lmul-max=1 -verify-machineinstrs < %s | FileCheck %s --check-prefixes=CHECK,LMULMAX1,LMULMAX1-RV64

define void @splat_v16i8(ptr %x, i8 %y) {
; CHECK-LABEL: splat_v16i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 16, e8, m1, ta, ma
; CHECK-NEXT:    vmv.v.x v8, a1
; CHECK-NEXT:    vse8.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <16 x i8> poison, i8 %y, i32 0
  %b = shufflevector <16 x i8> %a, <16 x i8> poison, <16 x i32> zeroinitializer
  store <16 x i8> %b, ptr %x
  ret void
}

define void @splat_v8i16(ptr %x, i16 %y) {
; CHECK-LABEL: splat_v8i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 8, e16, m1, ta, ma
; CHECK-NEXT:    vmv.v.x v8, a1
; CHECK-NEXT:    vse16.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <8 x i16> poison, i16 %y, i32 0
  %b = shufflevector <8 x i16> %a, <8 x i16> poison, <8 x i32> zeroinitializer
  store <8 x i16> %b, ptr %x
  ret void
}

define void @splat_v4i32(ptr %x, i32 %y) {
; CHECK-LABEL: splat_v4i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; CHECK-NEXT:    vmv.v.x v8, a1
; CHECK-NEXT:    vse32.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <4 x i32> poison, i32 %y, i32 0
  %b = shufflevector <4 x i32> %a, <4 x i32> poison, <4 x i32> zeroinitializer
  store <4 x i32> %b, ptr %x
  ret void
}

define void @splat_v2i64(ptr %x, i64 %y) {
; LMULMAX8-RV32-LABEL: splat_v2i64:
; LMULMAX8-RV32:       # %bb.0:
; LMULMAX8-RV32-NEXT:    addi sp, sp, -16
; LMULMAX8-RV32-NEXT:    .cfi_def_cfa_offset 16
; LMULMAX8-RV32-NEXT:    sw a2, 12(sp)
; LMULMAX8-RV32-NEXT:    sw a1, 8(sp)
; LMULMAX8-RV32-NEXT:    addi a1, sp, 8
; LMULMAX8-RV32-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX8-RV32-NEXT:    vlse64.v v8, (a1), zero
; LMULMAX8-RV32-NEXT:    vse64.v v8, (a0)
; LMULMAX8-RV32-NEXT:    addi sp, sp, 16
; LMULMAX8-RV32-NEXT:    ret
;
; LMULMAX2-RV32-LABEL: splat_v2i64:
; LMULMAX2-RV32:       # %bb.0:
; LMULMAX2-RV32-NEXT:    addi sp, sp, -16
; LMULMAX2-RV32-NEXT:    .cfi_def_cfa_offset 16
; LMULMAX2-RV32-NEXT:    sw a2, 12(sp)
; LMULMAX2-RV32-NEXT:    sw a1, 8(sp)
; LMULMAX2-RV32-NEXT:    addi a1, sp, 8
; LMULMAX2-RV32-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX2-RV32-NEXT:    vlse64.v v8, (a1), zero
; LMULMAX2-RV32-NEXT:    vse64.v v8, (a0)
; LMULMAX2-RV32-NEXT:    addi sp, sp, 16
; LMULMAX2-RV32-NEXT:    ret
;
; LMULMAX1-RV32-LABEL: splat_v2i64:
; LMULMAX1-RV32:       # %bb.0:
; LMULMAX1-RV32-NEXT:    addi sp, sp, -16
; LMULMAX1-RV32-NEXT:    .cfi_def_cfa_offset 16
; LMULMAX1-RV32-NEXT:    sw a2, 12(sp)
; LMULMAX1-RV32-NEXT:    sw a1, 8(sp)
; LMULMAX1-RV32-NEXT:    addi a1, sp, 8
; LMULMAX1-RV32-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vlse64.v v8, (a1), zero
; LMULMAX1-RV32-NEXT:    vse64.v v8, (a0)
; LMULMAX1-RV32-NEXT:    addi sp, sp, 16
; LMULMAX1-RV32-NEXT:    ret
;
; LMULMAX8-RV64-LABEL: splat_v2i64:
; LMULMAX8-RV64:       # %bb.0:
; LMULMAX8-RV64-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX8-RV64-NEXT:    vmv.v.x v8, a1
; LMULMAX8-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX8-RV64-NEXT:    ret
;
; LMULMAX2-RV64-LABEL: splat_v2i64:
; LMULMAX2-RV64:       # %bb.0:
; LMULMAX2-RV64-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX2-RV64-NEXT:    vmv.v.x v8, a1
; LMULMAX2-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX2-RV64-NEXT:    ret
;
; LMULMAX1-RV64-LABEL: splat_v2i64:
; LMULMAX1-RV64:       # %bb.0:
; LMULMAX1-RV64-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV64-NEXT:    vmv.v.x v8, a1
; LMULMAX1-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX1-RV64-NEXT:    ret
  %a = insertelement <2 x i64> poison, i64 %y, i32 0
  %b = shufflevector <2 x i64> %a, <2 x i64> poison, <2 x i32> zeroinitializer
  store <2 x i64> %b, ptr %x
  ret void
}

define void @splat_v32i8(ptr %x, i8 %y) {
; LMULMAX8-LABEL: splat_v32i8:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    li a2, 32
; LMULMAX8-NEXT:    vsetvli zero, a2, e8, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.x v8, a1
; LMULMAX8-NEXT:    vse8.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_v32i8:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    li a2, 32
; LMULMAX2-NEXT:    vsetvli zero, a2, e8, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.x v8, a1
; LMULMAX2-NEXT:    vse8.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-LABEL: splat_v32i8:
; LMULMAX1:       # %bb.0:
; LMULMAX1-NEXT:    vsetivli zero, 16, e8, m1, ta, ma
; LMULMAX1-NEXT:    vmv.v.x v8, a1
; LMULMAX1-NEXT:    addi a1, a0, 16
; LMULMAX1-NEXT:    vse8.v v8, (a1)
; LMULMAX1-NEXT:    vse8.v v8, (a0)
; LMULMAX1-NEXT:    ret
  %a = insertelement <32 x i8> poison, i8 %y, i32 0
  %b = shufflevector <32 x i8> %a, <32 x i8> poison, <32 x i32> zeroinitializer
  store <32 x i8> %b, ptr %x
  ret void
}

define void @splat_v16i16(ptr %x, i16 %y) {
; LMULMAX8-LABEL: splat_v16i16:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.x v8, a1
; LMULMAX8-NEXT:    vse16.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_v16i16:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.x v8, a1
; LMULMAX2-NEXT:    vse16.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-LABEL: splat_v16i16:
; LMULMAX1:       # %bb.0:
; LMULMAX1-NEXT:    vsetivli zero, 8, e16, m1, ta, ma
; LMULMAX1-NEXT:    vmv.v.x v8, a1
; LMULMAX1-NEXT:    addi a1, a0, 16
; LMULMAX1-NEXT:    vse16.v v8, (a1)
; LMULMAX1-NEXT:    vse16.v v8, (a0)
; LMULMAX1-NEXT:    ret
  %a = insertelement <16 x i16> poison, i16 %y, i32 0
  %b = shufflevector <16 x i16> %a, <16 x i16> poison, <16 x i32> zeroinitializer
  store <16 x i16> %b, ptr %x
  ret void
}

define void @splat_v8i32(ptr %x, i32 %y) {
; LMULMAX8-LABEL: splat_v8i32:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.x v8, a1
; LMULMAX8-NEXT:    vse32.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_v8i32:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.x v8, a1
; LMULMAX2-NEXT:    vse32.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-LABEL: splat_v8i32:
; LMULMAX1:       # %bb.0:
; LMULMAX1-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; LMULMAX1-NEXT:    vmv.v.x v8, a1
; LMULMAX1-NEXT:    addi a1, a0, 16
; LMULMAX1-NEXT:    vse32.v v8, (a1)
; LMULMAX1-NEXT:    vse32.v v8, (a0)
; LMULMAX1-NEXT:    ret
  %a = insertelement <8 x i32> poison, i32 %y, i32 0
  %b = shufflevector <8 x i32> %a, <8 x i32> poison, <8 x i32> zeroinitializer
  store <8 x i32> %b, ptr %x
  ret void
}

define void @splat_v4i64(ptr %x, i64 %y) {
; LMULMAX8-RV32-LABEL: splat_v4i64:
; LMULMAX8-RV32:       # %bb.0:
; LMULMAX8-RV32-NEXT:    addi sp, sp, -16
; LMULMAX8-RV32-NEXT:    .cfi_def_cfa_offset 16
; LMULMAX8-RV32-NEXT:    sw a2, 12(sp)
; LMULMAX8-RV32-NEXT:    sw a1, 8(sp)
; LMULMAX8-RV32-NEXT:    addi a1, sp, 8
; LMULMAX8-RV32-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX8-RV32-NEXT:    vlse64.v v8, (a1), zero
; LMULMAX8-RV32-NEXT:    vse64.v v8, (a0)
; LMULMAX8-RV32-NEXT:    addi sp, sp, 16
; LMULMAX8-RV32-NEXT:    ret
;
; LMULMAX2-RV32-LABEL: splat_v4i64:
; LMULMAX2-RV32:       # %bb.0:
; LMULMAX2-RV32-NEXT:    addi sp, sp, -16
; LMULMAX2-RV32-NEXT:    .cfi_def_cfa_offset 16
; LMULMAX2-RV32-NEXT:    sw a2, 12(sp)
; LMULMAX2-RV32-NEXT:    sw a1, 8(sp)
; LMULMAX2-RV32-NEXT:    addi a1, sp, 8
; LMULMAX2-RV32-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX2-RV32-NEXT:    vlse64.v v8, (a1), zero
; LMULMAX2-RV32-NEXT:    vse64.v v8, (a0)
; LMULMAX2-RV32-NEXT:    addi sp, sp, 16
; LMULMAX2-RV32-NEXT:    ret
;
; LMULMAX1-RV32-LABEL: splat_v4i64:
; LMULMAX1-RV32:       # %bb.0:
; LMULMAX1-RV32-NEXT:    li a3, 5
; LMULMAX1-RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vmv.s.x v0, a3
; LMULMAX1-RV32-NEXT:    vmv.v.x v8, a2
; LMULMAX1-RV32-NEXT:    vmerge.vxm v8, v8, a1, v0
; LMULMAX1-RV32-NEXT:    addi a1, a0, 16
; LMULMAX1-RV32-NEXT:    vse32.v v8, (a1)
; LMULMAX1-RV32-NEXT:    vse32.v v8, (a0)
; LMULMAX1-RV32-NEXT:    ret
;
; LMULMAX8-RV64-LABEL: splat_v4i64:
; LMULMAX8-RV64:       # %bb.0:
; LMULMAX8-RV64-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX8-RV64-NEXT:    vmv.v.x v8, a1
; LMULMAX8-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX8-RV64-NEXT:    ret
;
; LMULMAX2-RV64-LABEL: splat_v4i64:
; LMULMAX2-RV64:       # %bb.0:
; LMULMAX2-RV64-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX2-RV64-NEXT:    vmv.v.x v8, a1
; LMULMAX2-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX2-RV64-NEXT:    ret
;
; LMULMAX1-RV64-LABEL: splat_v4i64:
; LMULMAX1-RV64:       # %bb.0:
; LMULMAX1-RV64-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV64-NEXT:    vmv.v.x v8, a1
; LMULMAX1-RV64-NEXT:    addi a1, a0, 16
; LMULMAX1-RV64-NEXT:    vse64.v v8, (a1)
; LMULMAX1-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX1-RV64-NEXT:    ret
  %a = insertelement <4 x i64> poison, i64 %y, i32 0
  %b = shufflevector <4 x i64> %a, <4 x i64> poison, <4 x i32> zeroinitializer
  store <4 x i64> %b, ptr %x
  ret void
}

define void @splat_zero_v16i8(ptr %x) {
; CHECK-LABEL: splat_zero_v16i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 16, e8, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v8, 0
; CHECK-NEXT:    vse8.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <16 x i8> poison, i8 0, i32 0
  %b = shufflevector <16 x i8> %a, <16 x i8> poison, <16 x i32> zeroinitializer
  store <16 x i8> %b, ptr %x
  ret void
}

define void @splat_zero_v8i16(ptr %x) {
; CHECK-LABEL: splat_zero_v8i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 8, e16, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v8, 0
; CHECK-NEXT:    vse16.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <8 x i16> poison, i16 0, i32 0
  %b = shufflevector <8 x i16> %a, <8 x i16> poison, <8 x i32> zeroinitializer
  store <8 x i16> %b, ptr %x
  ret void
}

define void @splat_zero_v4i32(ptr %x) {
; CHECK-LABEL: splat_zero_v4i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v8, 0
; CHECK-NEXT:    vse32.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <4 x i32> poison, i32 0, i32 0
  %b = shufflevector <4 x i32> %a, <4 x i32> poison, <4 x i32> zeroinitializer
  store <4 x i32> %b, ptr %x
  ret void
}

define void @splat_zero_v2i64(ptr %x) {
; CHECK-LABEL: splat_zero_v2i64:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v8, 0
; CHECK-NEXT:    vse64.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <2 x i64> poison, i64 0, i32 0
  %b = shufflevector <2 x i64> %a, <2 x i64> poison, <2 x i32> zeroinitializer
  store <2 x i64> %b, ptr %x
  ret void
}

define void @splat_zero_v32i8(ptr %x) {
; LMULMAX8-LABEL: splat_zero_v32i8:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    li a1, 32
; LMULMAX8-NEXT:    vsetvli zero, a1, e8, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.i v8, 0
; LMULMAX8-NEXT:    vse8.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_zero_v32i8:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    li a1, 32
; LMULMAX2-NEXT:    vsetvli zero, a1, e8, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.i v8, 0
; LMULMAX2-NEXT:    vse8.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-LABEL: splat_zero_v32i8:
; LMULMAX1:       # %bb.0:
; LMULMAX1-NEXT:    vsetivli zero, 16, e8, m1, ta, ma
; LMULMAX1-NEXT:    vmv.v.i v8, 0
; LMULMAX1-NEXT:    vse8.v v8, (a0)
; LMULMAX1-NEXT:    addi a0, a0, 16
; LMULMAX1-NEXT:    vse8.v v8, (a0)
; LMULMAX1-NEXT:    ret
  %a = insertelement <32 x i8> poison, i8 0, i32 0
  %b = shufflevector <32 x i8> %a, <32 x i8> poison, <32 x i32> zeroinitializer
  store <32 x i8> %b, ptr %x
  ret void
}

define void @splat_zero_v16i16(ptr %x) {
; LMULMAX8-LABEL: splat_zero_v16i16:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.i v8, 0
; LMULMAX8-NEXT:    vse16.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_zero_v16i16:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.i v8, 0
; LMULMAX2-NEXT:    vse16.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-LABEL: splat_zero_v16i16:
; LMULMAX1:       # %bb.0:
; LMULMAX1-NEXT:    vsetivli zero, 8, e16, m1, ta, ma
; LMULMAX1-NEXT:    vmv.v.i v8, 0
; LMULMAX1-NEXT:    vse16.v v8, (a0)
; LMULMAX1-NEXT:    addi a0, a0, 16
; LMULMAX1-NEXT:    vse16.v v8, (a0)
; LMULMAX1-NEXT:    ret
  %a = insertelement <16 x i16> poison, i16 0, i32 0
  %b = shufflevector <16 x i16> %a, <16 x i16> poison, <16 x i32> zeroinitializer
  store <16 x i16> %b, ptr %x
  ret void
}

define void @splat_zero_v8i32(ptr %x) {
; LMULMAX8-LABEL: splat_zero_v8i32:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.i v8, 0
; LMULMAX8-NEXT:    vse32.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_zero_v8i32:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.i v8, 0
; LMULMAX2-NEXT:    vse32.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-LABEL: splat_zero_v8i32:
; LMULMAX1:       # %bb.0:
; LMULMAX1-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; LMULMAX1-NEXT:    vmv.v.i v8, 0
; LMULMAX1-NEXT:    vse32.v v8, (a0)
; LMULMAX1-NEXT:    addi a0, a0, 16
; LMULMAX1-NEXT:    vse32.v v8, (a0)
; LMULMAX1-NEXT:    ret
  %a = insertelement <8 x i32> poison, i32 0, i32 0
  %b = shufflevector <8 x i32> %a, <8 x i32> poison, <8 x i32> zeroinitializer
  store <8 x i32> %b, ptr %x
  ret void
}

define void @splat_zero_v4i64(ptr %x) {
; LMULMAX8-LABEL: splat_zero_v4i64:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.i v8, 0
; LMULMAX8-NEXT:    vse64.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_zero_v4i64:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.i v8, 0
; LMULMAX2-NEXT:    vse64.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-RV32-LABEL: splat_zero_v4i64:
; LMULMAX1-RV32:       # %bb.0:
; LMULMAX1-RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vmv.v.i v8, 0
; LMULMAX1-RV32-NEXT:    vse32.v v8, (a0)
; LMULMAX1-RV32-NEXT:    addi a0, a0, 16
; LMULMAX1-RV32-NEXT:    vse32.v v8, (a0)
; LMULMAX1-RV32-NEXT:    ret
;
; LMULMAX1-RV64-LABEL: splat_zero_v4i64:
; LMULMAX1-RV64:       # %bb.0:
; LMULMAX1-RV64-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV64-NEXT:    vmv.v.i v8, 0
; LMULMAX1-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX1-RV64-NEXT:    addi a0, a0, 16
; LMULMAX1-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX1-RV64-NEXT:    ret
  %a = insertelement <4 x i64> poison, i64 0, i32 0
  %b = shufflevector <4 x i64> %a, <4 x i64> poison, <4 x i32> zeroinitializer
  store <4 x i64> %b, ptr %x
  ret void
}

define void @splat_zero_v2i16(ptr %p) {
; CHECK-LABEL: splat_zero_v2i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    sw zero, 0(a0)
; CHECK-NEXT:    ret
  store <2 x i16> zeroinitializer, ptr %p
  ret void
}

define void @splat_zero_v2i16_unaligned(ptr %p) {
; CHECK-LABEL: splat_zero_v2i16_unaligned:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e16, mf4, ta, ma
; CHECK-NEXT:    vmv.v.i v8, 0
; CHECK-NEXT:    vsetivli zero, 4, e8, mf4, ta, ma
; CHECK-NEXT:    vse8.v v8, (a0)
; CHECK-NEXT:    ret
  store <2 x i16> zeroinitializer, ptr %p, align 1
  ret void
}

define void @splat_zero_v4i16(ptr %p) {
; LMULMAX8-RV32-LABEL: splat_zero_v4i16:
; LMULMAX8-RV32:       # %bb.0:
; LMULMAX8-RV32-NEXT:    vsetivli zero, 4, e16, mf2, ta, ma
; LMULMAX8-RV32-NEXT:    vmv.v.i v8, 0
; LMULMAX8-RV32-NEXT:    vse16.v v8, (a0)
; LMULMAX8-RV32-NEXT:    ret
;
; LMULMAX2-RV32-LABEL: splat_zero_v4i16:
; LMULMAX2-RV32:       # %bb.0:
; LMULMAX2-RV32-NEXT:    vsetivli zero, 4, e16, mf2, ta, ma
; LMULMAX2-RV32-NEXT:    vmv.v.i v8, 0
; LMULMAX2-RV32-NEXT:    vse16.v v8, (a0)
; LMULMAX2-RV32-NEXT:    ret
;
; LMULMAX1-RV32-LABEL: splat_zero_v4i16:
; LMULMAX1-RV32:       # %bb.0:
; LMULMAX1-RV32-NEXT:    vsetivli zero, 4, e16, mf2, ta, ma
; LMULMAX1-RV32-NEXT:    vmv.v.i v8, 0
; LMULMAX1-RV32-NEXT:    vse16.v v8, (a0)
; LMULMAX1-RV32-NEXT:    ret
;
; LMULMAX8-RV64-LABEL: splat_zero_v4i16:
; LMULMAX8-RV64:       # %bb.0:
; LMULMAX8-RV64-NEXT:    sd zero, 0(a0)
; LMULMAX8-RV64-NEXT:    ret
;
; LMULMAX2-RV64-LABEL: splat_zero_v4i16:
; LMULMAX2-RV64:       # %bb.0:
; LMULMAX2-RV64-NEXT:    sd zero, 0(a0)
; LMULMAX2-RV64-NEXT:    ret
;
; LMULMAX1-RV64-LABEL: splat_zero_v4i16:
; LMULMAX1-RV64:       # %bb.0:
; LMULMAX1-RV64-NEXT:    sd zero, 0(a0)
; LMULMAX1-RV64-NEXT:    ret
  store <4 x i16> zeroinitializer, ptr %p
  ret void
}

define void @splat_zero_v2i32(ptr %p) {
; LMULMAX8-RV32-LABEL: splat_zero_v2i32:
; LMULMAX8-RV32:       # %bb.0:
; LMULMAX8-RV32-NEXT:    vsetivli zero, 2, e32, mf2, ta, ma
; LMULMAX8-RV32-NEXT:    vmv.v.i v8, 0
; LMULMAX8-RV32-NEXT:    vse32.v v8, (a0)
; LMULMAX8-RV32-NEXT:    ret
;
; LMULMAX2-RV32-LABEL: splat_zero_v2i32:
; LMULMAX2-RV32:       # %bb.0:
; LMULMAX2-RV32-NEXT:    vsetivli zero, 2, e32, mf2, ta, ma
; LMULMAX2-RV32-NEXT:    vmv.v.i v8, 0
; LMULMAX2-RV32-NEXT:    vse32.v v8, (a0)
; LMULMAX2-RV32-NEXT:    ret
;
; LMULMAX1-RV32-LABEL: splat_zero_v2i32:
; LMULMAX1-RV32:       # %bb.0:
; LMULMAX1-RV32-NEXT:    vsetivli zero, 2, e32, mf2, ta, ma
; LMULMAX1-RV32-NEXT:    vmv.v.i v8, 0
; LMULMAX1-RV32-NEXT:    vse32.v v8, (a0)
; LMULMAX1-RV32-NEXT:    ret
;
; LMULMAX8-RV64-LABEL: splat_zero_v2i32:
; LMULMAX8-RV64:       # %bb.0:
; LMULMAX8-RV64-NEXT:    sd zero, 0(a0)
; LMULMAX8-RV64-NEXT:    ret
;
; LMULMAX2-RV64-LABEL: splat_zero_v2i32:
; LMULMAX2-RV64:       # %bb.0:
; LMULMAX2-RV64-NEXT:    sd zero, 0(a0)
; LMULMAX2-RV64-NEXT:    ret
;
; LMULMAX1-RV64-LABEL: splat_zero_v2i32:
; LMULMAX1-RV64:       # %bb.0:
; LMULMAX1-RV64-NEXT:    sd zero, 0(a0)
; LMULMAX1-RV64-NEXT:    ret
  store <2 x i32> zeroinitializer, ptr %p
  ret void
}

; Not a power of two and requires more than two scalar stores.
define void @splat_zero_v7i16(ptr %p) {
; CHECK-LABEL: splat_zero_v7i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 8, e16, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v8, 0
; CHECK-NEXT:    vsetivli zero, 7, e16, m1, ta, ma
; CHECK-NEXT:    vse16.v v8, (a0)
; CHECK-NEXT:    ret
  store <7 x i16> zeroinitializer, ptr %p
  ret void
}

define void @splat_allones_v16i8(ptr %x) {
; CHECK-LABEL: splat_allones_v16i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 16, e8, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v8, -1
; CHECK-NEXT:    vse8.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <16 x i8> poison, i8 -1, i32 0
  %b = shufflevector <16 x i8> %a, <16 x i8> poison, <16 x i32> zeroinitializer
  store <16 x i8> %b, ptr %x
  ret void
}

define void @splat_allones_v8i16(ptr %x) {
; CHECK-LABEL: splat_allones_v8i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 8, e16, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v8, -1
; CHECK-NEXT:    vse16.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <8 x i16> poison, i16 -1, i32 0
  %b = shufflevector <8 x i16> %a, <8 x i16> poison, <8 x i32> zeroinitializer
  store <8 x i16> %b, ptr %x
  ret void
}

define void @splat_allones_v4i32(ptr %x) {
; CHECK-LABEL: splat_allones_v4i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v8, -1
; CHECK-NEXT:    vse32.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <4 x i32> poison, i32 -1, i32 0
  %b = shufflevector <4 x i32> %a, <4 x i32> poison, <4 x i32> zeroinitializer
  store <4 x i32> %b, ptr %x
  ret void
}

define void @splat_allones_v2i64(ptr %x) {
; CHECK-LABEL: splat_allones_v2i64:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vmv.v.i v8, -1
; CHECK-NEXT:    vse64.v v8, (a0)
; CHECK-NEXT:    ret
  %a = insertelement <2 x i64> poison, i64 -1, i32 0
  %b = shufflevector <2 x i64> %a, <2 x i64> poison, <2 x i32> zeroinitializer
  store <2 x i64> %b, ptr %x
  ret void
}

define void @splat_allones_v32i8(ptr %x) {
; LMULMAX8-LABEL: splat_allones_v32i8:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    li a1, 32
; LMULMAX8-NEXT:    vsetvli zero, a1, e8, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.i v8, -1
; LMULMAX8-NEXT:    vse8.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_allones_v32i8:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    li a1, 32
; LMULMAX2-NEXT:    vsetvli zero, a1, e8, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.i v8, -1
; LMULMAX2-NEXT:    vse8.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-LABEL: splat_allones_v32i8:
; LMULMAX1:       # %bb.0:
; LMULMAX1-NEXT:    vsetivli zero, 16, e8, m1, ta, ma
; LMULMAX1-NEXT:    vmv.v.i v8, -1
; LMULMAX1-NEXT:    vse8.v v8, (a0)
; LMULMAX1-NEXT:    addi a0, a0, 16
; LMULMAX1-NEXT:    vse8.v v8, (a0)
; LMULMAX1-NEXT:    ret
  %a = insertelement <32 x i8> poison, i8 -1, i32 0
  %b = shufflevector <32 x i8> %a, <32 x i8> poison, <32 x i32> zeroinitializer
  store <32 x i8> %b, ptr %x
  ret void
}

define void @splat_allones_v16i16(ptr %x) {
; LMULMAX8-LABEL: splat_allones_v16i16:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.i v8, -1
; LMULMAX8-NEXT:    vse16.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_allones_v16i16:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    vsetivli zero, 16, e16, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.i v8, -1
; LMULMAX2-NEXT:    vse16.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-LABEL: splat_allones_v16i16:
; LMULMAX1:       # %bb.0:
; LMULMAX1-NEXT:    vsetivli zero, 8, e16, m1, ta, ma
; LMULMAX1-NEXT:    vmv.v.i v8, -1
; LMULMAX1-NEXT:    vse16.v v8, (a0)
; LMULMAX1-NEXT:    addi a0, a0, 16
; LMULMAX1-NEXT:    vse16.v v8, (a0)
; LMULMAX1-NEXT:    ret
  %a = insertelement <16 x i16> poison, i16 -1, i32 0
  %b = shufflevector <16 x i16> %a, <16 x i16> poison, <16 x i32> zeroinitializer
  store <16 x i16> %b, ptr %x
  ret void
}

define void @splat_allones_v8i32(ptr %x) {
; LMULMAX8-LABEL: splat_allones_v8i32:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.i v8, -1
; LMULMAX8-NEXT:    vse32.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_allones_v8i32:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.i v8, -1
; LMULMAX2-NEXT:    vse32.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-LABEL: splat_allones_v8i32:
; LMULMAX1:       # %bb.0:
; LMULMAX1-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; LMULMAX1-NEXT:    vmv.v.i v8, -1
; LMULMAX1-NEXT:    vse32.v v8, (a0)
; LMULMAX1-NEXT:    addi a0, a0, 16
; LMULMAX1-NEXT:    vse32.v v8, (a0)
; LMULMAX1-NEXT:    ret
  %a = insertelement <8 x i32> poison, i32 -1, i32 0
  %b = shufflevector <8 x i32> %a, <8 x i32> poison, <8 x i32> zeroinitializer
  store <8 x i32> %b, ptr %x
  ret void
}

define void @splat_allones_v4i64(ptr %x) {
; LMULMAX8-LABEL: splat_allones_v4i64:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX8-NEXT:    vmv.v.i v8, -1
; LMULMAX8-NEXT:    vse64.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_allones_v4i64:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX2-NEXT:    vmv.v.i v8, -1
; LMULMAX2-NEXT:    vse64.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-RV32-LABEL: splat_allones_v4i64:
; LMULMAX1-RV32:       # %bb.0:
; LMULMAX1-RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vmv.v.i v8, -1
; LMULMAX1-RV32-NEXT:    vse32.v v8, (a0)
; LMULMAX1-RV32-NEXT:    addi a0, a0, 16
; LMULMAX1-RV32-NEXT:    vse32.v v8, (a0)
; LMULMAX1-RV32-NEXT:    ret
;
; LMULMAX1-RV64-LABEL: splat_allones_v4i64:
; LMULMAX1-RV64:       # %bb.0:
; LMULMAX1-RV64-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV64-NEXT:    vmv.v.i v8, -1
; LMULMAX1-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX1-RV64-NEXT:    addi a0, a0, 16
; LMULMAX1-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX1-RV64-NEXT:    ret
  %a = insertelement <4 x i64> poison, i64 -1, i32 0
  %b = shufflevector <4 x i64> %a, <4 x i64> poison, <4 x i32> zeroinitializer
  store <4 x i64> %b, ptr %x
  ret void
}

; This requires a bitcast on RV32 due to type legalization rewriting the
; build_vector to v8i32.
; FIXME: We should prevent this and use the implicit sign extension of vmv.v.x
; with SEW=64 on RV32.
define void @splat_allones_with_use_v4i64(ptr %x) {
; LMULMAX8-LABEL: splat_allones_with_use_v4i64:
; LMULMAX8:       # %bb.0:
; LMULMAX8-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX8-NEXT:    vle64.v v8, (a0)
; LMULMAX8-NEXT:    vadd.vi v8, v8, -1
; LMULMAX8-NEXT:    vse64.v v8, (a0)
; LMULMAX8-NEXT:    ret
;
; LMULMAX2-LABEL: splat_allones_with_use_v4i64:
; LMULMAX2:       # %bb.0:
; LMULMAX2-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX2-NEXT:    vle64.v v8, (a0)
; LMULMAX2-NEXT:    vadd.vi v8, v8, -1
; LMULMAX2-NEXT:    vse64.v v8, (a0)
; LMULMAX2-NEXT:    ret
;
; LMULMAX1-RV32-LABEL: splat_allones_with_use_v4i64:
; LMULMAX1-RV32:       # %bb.0:
; LMULMAX1-RV32-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vle64.v v8, (a0)
; LMULMAX1-RV32-NEXT:    addi a1, a0, 16
; LMULMAX1-RV32-NEXT:    vle64.v v9, (a1)
; LMULMAX1-RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vmv.v.i v10, -1
; LMULMAX1-RV32-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vadd.vv v9, v9, v10
; LMULMAX1-RV32-NEXT:    vadd.vv v8, v8, v10
; LMULMAX1-RV32-NEXT:    vse64.v v8, (a0)
; LMULMAX1-RV32-NEXT:    vse64.v v9, (a1)
; LMULMAX1-RV32-NEXT:    ret
;
; LMULMAX1-RV64-LABEL: splat_allones_with_use_v4i64:
; LMULMAX1-RV64:       # %bb.0:
; LMULMAX1-RV64-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV64-NEXT:    addi a1, a0, 16
; LMULMAX1-RV64-NEXT:    vle64.v v8, (a1)
; LMULMAX1-RV64-NEXT:    vle64.v v9, (a0)
; LMULMAX1-RV64-NEXT:    vadd.vi v8, v8, -1
; LMULMAX1-RV64-NEXT:    vadd.vi v9, v9, -1
; LMULMAX1-RV64-NEXT:    vse64.v v9, (a0)
; LMULMAX1-RV64-NEXT:    vse64.v v8, (a1)
; LMULMAX1-RV64-NEXT:    ret
  %a = load <4 x i64>, ptr %x
  %b = add <4 x i64> %a, <i64 -1, i64 -1, i64 -1, i64 -1>
  store <4 x i64> %b, ptr %x
  ret void
}

; This test used to crash at LMUL=8 when inserting a v16i64 subvector into
; nxv8i64 at index 0: the v16i64 type was used to get the LMUL, the size of
; which exceeded maximum-expected size of 512. The scalable container type of
; nxv8i64 should have been used instead.
define void @vadd_vx_v16i64(ptr %a, i64 %b, ptr %c) {
; LMULMAX8-RV32-LABEL: vadd_vx_v16i64:
; LMULMAX8-RV32:       # %bb.0:
; LMULMAX8-RV32-NEXT:    addi sp, sp, -16
; LMULMAX8-RV32-NEXT:    .cfi_def_cfa_offset 16
; LMULMAX8-RV32-NEXT:    vsetivli zero, 16, e64, m8, ta, ma
; LMULMAX8-RV32-NEXT:    vle64.v v8, (a0)
; LMULMAX8-RV32-NEXT:    sw a2, 12(sp)
; LMULMAX8-RV32-NEXT:    sw a1, 8(sp)
; LMULMAX8-RV32-NEXT:    addi a0, sp, 8
; LMULMAX8-RV32-NEXT:    vlse64.v v16, (a0), zero
; LMULMAX8-RV32-NEXT:    vadd.vv v8, v8, v16
; LMULMAX8-RV32-NEXT:    vse64.v v8, (a3)
; LMULMAX8-RV32-NEXT:    addi sp, sp, 16
; LMULMAX8-RV32-NEXT:    ret
;
; LMULMAX2-RV32-LABEL: vadd_vx_v16i64:
; LMULMAX2-RV32:       # %bb.0:
; LMULMAX2-RV32-NEXT:    addi a4, a0, 64
; LMULMAX2-RV32-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX2-RV32-NEXT:    vle64.v v8, (a4)
; LMULMAX2-RV32-NEXT:    addi a4, a0, 96
; LMULMAX2-RV32-NEXT:    vle64.v v10, (a4)
; LMULMAX2-RV32-NEXT:    vle64.v v12, (a0)
; LMULMAX2-RV32-NEXT:    addi a0, a0, 32
; LMULMAX2-RV32-NEXT:    vle64.v v14, (a0)
; LMULMAX2-RV32-NEXT:    li a0, 85
; LMULMAX2-RV32-NEXT:    vmv.s.x v0, a0
; LMULMAX2-RV32-NEXT:    vsetivli zero, 8, e32, m2, ta, ma
; LMULMAX2-RV32-NEXT:    vmv.v.x v16, a2
; LMULMAX2-RV32-NEXT:    vmerge.vxm v16, v16, a1, v0
; LMULMAX2-RV32-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX2-RV32-NEXT:    vadd.vv v14, v14, v16
; LMULMAX2-RV32-NEXT:    vadd.vv v12, v12, v16
; LMULMAX2-RV32-NEXT:    vadd.vv v10, v10, v16
; LMULMAX2-RV32-NEXT:    vadd.vv v8, v8, v16
; LMULMAX2-RV32-NEXT:    addi a0, a3, 64
; LMULMAX2-RV32-NEXT:    vse64.v v8, (a0)
; LMULMAX2-RV32-NEXT:    addi a0, a3, 96
; LMULMAX2-RV32-NEXT:    vse64.v v10, (a0)
; LMULMAX2-RV32-NEXT:    vse64.v v12, (a3)
; LMULMAX2-RV32-NEXT:    addi a0, a3, 32
; LMULMAX2-RV32-NEXT:    vse64.v v14, (a0)
; LMULMAX2-RV32-NEXT:    ret
;
; LMULMAX1-RV32-LABEL: vadd_vx_v16i64:
; LMULMAX1-RV32:       # %bb.0:
; LMULMAX1-RV32-NEXT:    addi a4, a0, 96
; LMULMAX1-RV32-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vle64.v v8, (a4)
; LMULMAX1-RV32-NEXT:    addi a4, a0, 112
; LMULMAX1-RV32-NEXT:    vle64.v v9, (a4)
; LMULMAX1-RV32-NEXT:    addi a4, a0, 64
; LMULMAX1-RV32-NEXT:    vle64.v v10, (a4)
; LMULMAX1-RV32-NEXT:    addi a4, a0, 80
; LMULMAX1-RV32-NEXT:    vle64.v v11, (a4)
; LMULMAX1-RV32-NEXT:    addi a4, a0, 32
; LMULMAX1-RV32-NEXT:    vle64.v v12, (a4)
; LMULMAX1-RV32-NEXT:    addi a4, a0, 48
; LMULMAX1-RV32-NEXT:    vle64.v v13, (a4)
; LMULMAX1-RV32-NEXT:    vle64.v v14, (a0)
; LMULMAX1-RV32-NEXT:    addi a0, a0, 16
; LMULMAX1-RV32-NEXT:    vle64.v v15, (a0)
; LMULMAX1-RV32-NEXT:    li a0, 5
; LMULMAX1-RV32-NEXT:    vmv.s.x v0, a0
; LMULMAX1-RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vmv.v.x v16, a2
; LMULMAX1-RV32-NEXT:    vmerge.vxm v16, v16, a1, v0
; LMULMAX1-RV32-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV32-NEXT:    vadd.vv v15, v15, v16
; LMULMAX1-RV32-NEXT:    vadd.vv v14, v14, v16
; LMULMAX1-RV32-NEXT:    vadd.vv v13, v13, v16
; LMULMAX1-RV32-NEXT:    vadd.vv v12, v12, v16
; LMULMAX1-RV32-NEXT:    vadd.vv v11, v11, v16
; LMULMAX1-RV32-NEXT:    vadd.vv v10, v10, v16
; LMULMAX1-RV32-NEXT:    vadd.vv v9, v9, v16
; LMULMAX1-RV32-NEXT:    vadd.vv v8, v8, v16
; LMULMAX1-RV32-NEXT:    addi a0, a3, 96
; LMULMAX1-RV32-NEXT:    vse64.v v8, (a0)
; LMULMAX1-RV32-NEXT:    addi a0, a3, 112
; LMULMAX1-RV32-NEXT:    vse64.v v9, (a0)
; LMULMAX1-RV32-NEXT:    addi a0, a3, 64
; LMULMAX1-RV32-NEXT:    vse64.v v10, (a0)
; LMULMAX1-RV32-NEXT:    addi a0, a3, 80
; LMULMAX1-RV32-NEXT:    vse64.v v11, (a0)
; LMULMAX1-RV32-NEXT:    addi a0, a3, 32
; LMULMAX1-RV32-NEXT:    vse64.v v12, (a0)
; LMULMAX1-RV32-NEXT:    addi a0, a3, 48
; LMULMAX1-RV32-NEXT:    vse64.v v13, (a0)
; LMULMAX1-RV32-NEXT:    vse64.v v14, (a3)
; LMULMAX1-RV32-NEXT:    addi a3, a3, 16
; LMULMAX1-RV32-NEXT:    vse64.v v15, (a3)
; LMULMAX1-RV32-NEXT:    ret
;
; LMULMAX8-RV64-LABEL: vadd_vx_v16i64:
; LMULMAX8-RV64:       # %bb.0:
; LMULMAX8-RV64-NEXT:    vsetivli zero, 16, e64, m8, ta, ma
; LMULMAX8-RV64-NEXT:    vle64.v v8, (a0)
; LMULMAX8-RV64-NEXT:    vadd.vx v8, v8, a1
; LMULMAX8-RV64-NEXT:    vse64.v v8, (a2)
; LMULMAX8-RV64-NEXT:    ret
;
; LMULMAX2-RV64-LABEL: vadd_vx_v16i64:
; LMULMAX2-RV64:       # %bb.0:
; LMULMAX2-RV64-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; LMULMAX2-RV64-NEXT:    addi a3, a0, 96
; LMULMAX2-RV64-NEXT:    vle64.v v8, (a3)
; LMULMAX2-RV64-NEXT:    addi a3, a0, 32
; LMULMAX2-RV64-NEXT:    vle64.v v10, (a3)
; LMULMAX2-RV64-NEXT:    addi a3, a0, 64
; LMULMAX2-RV64-NEXT:    vle64.v v12, (a3)
; LMULMAX2-RV64-NEXT:    vle64.v v14, (a0)
; LMULMAX2-RV64-NEXT:    vadd.vx v10, v10, a1
; LMULMAX2-RV64-NEXT:    vadd.vx v8, v8, a1
; LMULMAX2-RV64-NEXT:    vadd.vx v12, v12, a1
; LMULMAX2-RV64-NEXT:    vadd.vx v14, v14, a1
; LMULMAX2-RV64-NEXT:    vse64.v v14, (a2)
; LMULMAX2-RV64-NEXT:    addi a0, a2, 64
; LMULMAX2-RV64-NEXT:    vse64.v v12, (a0)
; LMULMAX2-RV64-NEXT:    addi a0, a2, 96
; LMULMAX2-RV64-NEXT:    vse64.v v8, (a0)
; LMULMAX2-RV64-NEXT:    addi a0, a2, 32
; LMULMAX2-RV64-NEXT:    vse64.v v10, (a0)
; LMULMAX2-RV64-NEXT:    ret
;
; LMULMAX1-RV64-LABEL: vadd_vx_v16i64:
; LMULMAX1-RV64:       # %bb.0:
; LMULMAX1-RV64-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; LMULMAX1-RV64-NEXT:    vle64.v v8, (a0)
; LMULMAX1-RV64-NEXT:    addi a3, a0, 96
; LMULMAX1-RV64-NEXT:    vle64.v v9, (a3)
; LMULMAX1-RV64-NEXT:    addi a3, a0, 112
; LMULMAX1-RV64-NEXT:    vle64.v v10, (a3)
; LMULMAX1-RV64-NEXT:    addi a3, a0, 64
; LMULMAX1-RV64-NEXT:    vle64.v v11, (a3)
; LMULMAX1-RV64-NEXT:    addi a3, a0, 48
; LMULMAX1-RV64-NEXT:    vle64.v v12, (a3)
; LMULMAX1-RV64-NEXT:    addi a3, a0, 16
; LMULMAX1-RV64-NEXT:    vle64.v v13, (a3)
; LMULMAX1-RV64-NEXT:    addi a3, a0, 80
; LMULMAX1-RV64-NEXT:    addi a0, a0, 32
; LMULMAX1-RV64-NEXT:    vle64.v v14, (a0)
; LMULMAX1-RV64-NEXT:    vle64.v v15, (a3)
; LMULMAX1-RV64-NEXT:    vadd.vx v13, v13, a1
; LMULMAX1-RV64-NEXT:    vadd.vx v12, v12, a1
; LMULMAX1-RV64-NEXT:    vadd.vx v14, v14, a1
; LMULMAX1-RV64-NEXT:    vadd.vx v15, v15, a1
; LMULMAX1-RV64-NEXT:    vadd.vx v11, v11, a1
; LMULMAX1-RV64-NEXT:    vadd.vx v10, v10, a1
; LMULMAX1-RV64-NEXT:    vadd.vx v9, v9, a1
; LMULMAX1-RV64-NEXT:    vadd.vx v8, v8, a1
; LMULMAX1-RV64-NEXT:    vse64.v v8, (a2)
; LMULMAX1-RV64-NEXT:    addi a0, a2, 96
; LMULMAX1-RV64-NEXT:    vse64.v v9, (a0)
; LMULMAX1-RV64-NEXT:    addi a0, a2, 112
; LMULMAX1-RV64-NEXT:    vse64.v v10, (a0)
; LMULMAX1-RV64-NEXT:    addi a0, a2, 64
; LMULMAX1-RV64-NEXT:    vse64.v v11, (a0)
; LMULMAX1-RV64-NEXT:    addi a0, a2, 80
; LMULMAX1-RV64-NEXT:    vse64.v v15, (a0)
; LMULMAX1-RV64-NEXT:    addi a0, a2, 32
; LMULMAX1-RV64-NEXT:    vse64.v v14, (a0)
; LMULMAX1-RV64-NEXT:    addi a0, a2, 48
; LMULMAX1-RV64-NEXT:    vse64.v v12, (a0)
; LMULMAX1-RV64-NEXT:    addi a2, a2, 16
; LMULMAX1-RV64-NEXT:    vse64.v v13, (a2)
; LMULMAX1-RV64-NEXT:    ret
  %va = load <16 x i64>, ptr %a
  %head = insertelement <16 x i64> poison, i64 %b, i32 0
  %splat = shufflevector <16 x i64> %head, <16 x i64> poison, <16 x i32> zeroinitializer
  %vc = add <16 x i64> %va, %splat
  store <16 x i64> %vc, ptr %c
  ret void
}
