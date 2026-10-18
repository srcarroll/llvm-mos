// RUN: mlir-opt -convert-to-llvm -split-input-file %s | mlir-opt --canonicalize --cse -split-input-file | FileCheck %s
// TODO: Figure out why -convert-to-llvm -canonicalize crashes on test cases there convert !anes.meta_sprite_handle
// in function arg or returns

// CHECK: llvm.mlir.global internal @bg_palette() {addr_space = 0 : i32} : !llvm.array<16 x i8>
// CHECK-LABEL: @set_bg_palette
func.func @set_bg_palette() {
// CHECK-DAG: %[[C1:.*]] = llvm.mlir.constant(1 : i8) : i8
// CHECK-DAG: %[[C2:.*]] = llvm.mlir.constant(2 : i8) : i8
// CHECK-DAG: %[[C3:.*]] = llvm.mlir.constant(3 : i8) : i8
// CHECK-DAG: %[[C4:.*]] = llvm.mlir.constant(4 : i8) : i8
// CHECK-DAG: %[[C5:.*]] = llvm.mlir.constant(5 : i8) : i8
// CHECK-DAG: %[[C6:.*]] = llvm.mlir.constant(6 : i8) : i8
// CHECK-DAG: %[[C7:.*]] = llvm.mlir.constant(7 : i8) : i8
// CHECK-DAG: %[[C8:.*]] = llvm.mlir.constant(8 : i8) : i8
// CHECK-DAG: %[[C9:.*]] = llvm.mlir.constant(9 : i8) : i8
// CHECK-DAG: %[[C10:.*]] = llvm.mlir.constant(10 : i8) : i8
// CHECK-DAG: %[[C11:.*]] = llvm.mlir.constant(11 : i8) : i8

// CHECK:      %[[PAL_PTR:.*]] = llvm.mlir.addressof @bg_palette : !llvm.ptr

// CHECK:      %[[C0:.*]] = llvm.mlir.constant(0 : i8) : i8
// CHECK-NEXT: llvm.store %[[C0]], %[[PAL_PTR]]
// CHECK-NEXT: %[[PTR_1:.*]] = llvm.getelementptr %[[PAL_PTR]][1]

// CHECK-NEXT: llvm.store %[[C0]], %[[PTR_1]]
// CHECK-NEXT: %[[PTR_2:.*]] = llvm.getelementptr %[[PAL_PTR]][2]
// CHECK-NEXT: llvm.store %[[C1]], %[[PTR_2]]
// CHECK-NEXT: %[[PTR_3:.*]] = llvm.getelementptr %[[PAL_PTR]][3]
// CHECK-NEXT: llvm.store %[[C2]], %[[PTR_3]]

// CHECK-NEXT: %[[PTR_4:.*]] = llvm.getelementptr %[[PAL_PTR]][4]
// CHECK-NEXT: llvm.store %[[C0]], %[[PTR_4]]
// CHECK-NEXT: %[[PTR_5:.*]] = llvm.getelementptr %[[PAL_PTR]][5]
// CHECK-NEXT: llvm.store %[[C3]], %[[PTR_5]]
// CHECK-NEXT: %[[PTR_6:.*]] = llvm.getelementptr %[[PAL_PTR]][6]
// CHECK-NEXT: llvm.store %[[C4]], %[[PTR_6]]
// CHECK-NEXT: %[[PTR_7:.*]] = llvm.getelementptr %[[PAL_PTR]][7]
// CHECK-NEXT: llvm.store %[[C5]], %[[PTR_7]]

// CHECK-NEXT: %[[PTR_8:.*]] = llvm.getelementptr %[[PAL_PTR]][8]
// CHECK-NEXT: llvm.store %[[C0]], %[[PTR_8]]
// CHECK-NEXT: %[[PTR_9:.*]] = llvm.getelementptr %[[PAL_PTR]][9]
// CHECK-NEXT: llvm.store %[[C6]], %[[PTR_9]]
// CHECK-NEXT: %[[PTR_10:.*]] = llvm.getelementptr %[[PAL_PTR]][10]
// CHECK-NEXT: llvm.store %[[C7]], %[[PTR_10]]
// CHECK-NEXT: %[[PTR_11:.*]] = llvm.getelementptr %[[PAL_PTR]][11]
// CHECK-NEXT: llvm.store %[[C8]], %[[PTR_11]]

// CHECK-NEXT: %[[PTR_12:.*]] = llvm.getelementptr %[[PAL_PTR]][12]
// CHECK-NEXT: llvm.store %[[C0]], %[[PTR_12]]
// CHECK-NEXT: %[[PTR_13:.*]] = llvm.getelementptr %[[PAL_PTR]][13]
// CHECK-NEXT: llvm.store %[[C9]], %[[PTR_13]]
// CHECK-NEXT: %[[PTR_14:.*]] = llvm.getelementptr %[[PAL_PTR]][14]
// CHECK-NEXT: llvm.store %[[C10]], %[[PTR_14]]
// CHECK-NEXT: %[[PTR_15:.*]] = llvm.getelementptr %[[PAL_PTR]][15]
// CHECK-NEXT: llvm.store %[[C11]], %[[PTR_15]]

// CHECK-NEXT: llvm.call @pal_bg(%[[PAL_PTR]]) : (!llvm.ptr) -> ()
    anes.set_palette <background> 0, [0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11]

// CHECK-NEXT: return
    return
}

// -----

// CHECK-LABEL: @vram_addr_for_tile_pos_tile
// CHECK-SAME:   (%[[X:.*]]: i8, %[[Y:.*]]: i8)
func.func @vram_addr_for_tile_pos_tile(%x: i8, %y: i8) {
// CHECK-DAG:  %[[NAMETABLE_A:.*]] = llvm.mlir.constant(8192 : i16) : i16
// CHECK-DAG:  %[[C5:.*]] = llvm.mlir.constant(5 : i16) : i16
// CHECK:      %[[XEXT:.*]] = llvm.zext %[[X]] : i8 to i16
// CHECK:      %[[YEXT:.*]] = llvm.zext %[[Y]] : i8 to i16
// CHECK-NEXT: %[[SHL:.*]] = llvm.shl %[[YEXT]], %[[C5]]
// CHECK-NEXT: %[[OR:.*]] = llvm.or %[[SHL]], %[[XEXT]]
// CHECK-NEXT: %[[ADDR:.*]] = llvm.or %[[NAMETABLE_A]], %[[OR]]
// CHECK-NEXT: llvm.call @vram_adr(%[[ADDR]])
    anes.vram_addr_for_tile_pos(%x, %y) <tile> 

// CHECK-NEXT: llvm.return
    return
}

// -----

// CHECK-LABEL: @vram_addr_for_tile_pos_pal
// CHECK-SAME:   (%[[X:.*]]: i8, %[[Y:.*]]: i8)
func.func @vram_addr_for_tile_pos_pal(%x: i8, %y: i8) {
// CHECK-DAG:  %[[C0:.*]] = llvm.mlir.constant(0 : i8) : i8
// CHECK:      %[[ADDR:.*]] = llvm.call @get_at_addr(%[[C0]], %[[X]], %[[Y]])
// CHECK-NEXT: llvm.call @vram_adr(%[[ADDR]])
    anes.vram_addr_for_tile_pos(%x, %y) <palette> 

// CHECK-NEXT: llvm.return
    return
}

// -----

// CHECK-LABEL: @ppu_off
func.func @ppu_off() {
// CHECK: llvm.call @ppu_off() 
    anes.ppu_off

// CHECK-NEXT: llvm.return
    return
}

// -----

// CHECK-LABEL: @set_tile_at
// CHECK-SAME:   (%[[VALUE:.*]]: i8, %[[X:.*]]: i8, %[[Y:.*]]: i8)
func.func @set_tile_at(%value: i8, %x: i8, %y: i8) {
// CHECK-DAG:  %[[NAMETABLE_A:.*]] = llvm.mlir.constant(8192 : i16) : i16
// CHECK-DAG:  %[[C5:.*]] = llvm.mlir.constant(5 : i16) : i16
// CHECK:      %[[XEXT:.*]] = llvm.zext %[[X]] : i8 to i16
// CHECK:      %[[YEXT:.*]] = llvm.zext %[[Y]] : i8 to i16
// CHECK-NEXT: %[[SHL:.*]] = llvm.shl %[[YEXT]], %[[C5]]
// CHECK-NEXT: %[[OR:.*]] = llvm.or %[[SHL]], %[[XEXT]]
// CHECK-NEXT: %[[ADDR:.*]] = llvm.or %[[NAMETABLE_A]], %[[OR]]
// CHECK-NEXT: llvm.call @vram_adr(%[[ADDR]])
// CHECK-NEXT: llvm.call @vram_put(%[[VALUE]])
    anes.set_tile_at %value at (%x, %y)

// CHECK-NEXT: llvm.return
    return
}

// -----

// CHECK-LABEL: @set_tiles_at
// CHECK-SAME:   (%[[VALUE:.*]]: !llvm.array<3 x i8>, %[[X:.*]]: i8, %[[Y:.*]]: i8)
func.func @set_tiles_at(%value: !llvm.array<3 x i8>, %x: i8, %y: i8) {
// CHECK-DAG:  %[[NAMETABLE_A:.*]] = llvm.mlir.constant(8192 : i16) : i16
// CHECK-DAG:  %[[C5:.*]] = llvm.mlir.constant(5 : i16) : i16
// CHECK:      %[[XEXT:.*]] = llvm.zext %[[X]] : i8 to i16
// CHECK:      %[[YEXT:.*]] = llvm.zext %[[Y]] : i8 to i16
// CHECK-NEXT: %[[SHL:.*]] = llvm.shl %[[YEXT]], %[[C5]]
// CHECK-NEXT: %[[OR:.*]] = llvm.or %[[SHL]], %[[XEXT]]
// CHECK-NEXT: %[[ADDR:.*]] = llvm.or %[[NAMETABLE_A]], %[[OR]]
// CHECK-NEXT: llvm.call @vram_adr(%[[ADDR]])
// CHECK-NEXT: %[[TILE_0:.*]] = llvm.extractvalue %[[VALUE]][0]
// CHECK-NEXT: llvm.call @vram_put(%[[TILE_0]])
// CHECK-NEXT: %[[TILE_1:.*]] = llvm.extractvalue %[[VALUE]][1]
// CHECK-NEXT: llvm.call @vram_put(%[[TILE_1]])
// CHECK-NEXT: %[[TILE_2:.*]] = llvm.extractvalue %[[VALUE]][2]
// CHECK-NEXT: llvm.call @vram_put(%[[TILE_2]])
    anes.set_all_tiles_at %value at (%x, %y) : !llvm.array<3 x i8>

// CHECK-NEXT: llvm.return
    return
}

// -----

// CHECK-LABEL: @fill_tiles_from_compressed_at
// CHECK-SAME:   (%[[RLE_PTR:.*]]: !llvm.ptr, %[[X:.*]]: i8, %[[Y:.*]]: i8)
func.func @fill_tiles_from_compressed_at(%value: !llvm.ptr, %x: i8, %y: i8) {
// CHECK-DAG:  %[[NAMETABLE_A:.*]] = llvm.mlir.constant(8192 : i16) : i16
// CHECK-DAG:  %[[C5:.*]] = llvm.mlir.constant(5 : i16) : i16
// CHECK:      %[[XEXT:.*]] = llvm.zext %[[X]] : i8 to i16
// CHECK:      %[[YEXT:.*]] = llvm.zext %[[Y]] : i8 to i16
// CHECK-NEXT: %[[SHL:.*]] = llvm.shl %[[YEXT]], %[[C5]]
// CHECK-NEXT: %[[OR:.*]] = llvm.or %[[SHL]], %[[XEXT]]
// CHECK-NEXT: %[[ADDR:.*]] = llvm.or %[[NAMETABLE_A]], %[[OR]]
// CHECK-NEXT: llvm.call @vram_adr(%[[ADDR]])
// CHECK-NEXT: llvm.call @vram_unrle(%[[RLE_PTR]])
    anes.fill_tiles_from_rle_at %value at (%x, %y) : !llvm.ptr
    return
}

// -----

// CHECK-LABEL: @set_pal_pattern_at
// CHECK-SAME:   (%[[X:.*]]: i8, %[[Y:.*]]: i8)
func.func @set_pal_pattern_at(%x: i8, %y: i8) {
// bit pattern of 1, 0, 2, 3 in reverse: 11 10 00 01
// which evaluates to -32 for i8
// CHECK-DAG:  %[[PAL_PAT_VAL:.*]] = llvm.mlir.constant(-31 : i8) : i8
// CHECK-DAG:  %[[C0:.*]] = llvm.mlir.constant(0 : i8) : i8
// CHECK:      %[[ADDR:.*]] = llvm.call @get_at_addr(%[[C0]], %[[X]], %[[Y]]) : (i8, i8, i8) -> i16
// CHECK-NEXT: llvm.call @vram_adr(%[[ADDR]]) : (i16) -> ()
// CHECK-NEXT: llvm.call @vram_put(%[[PAL_PAT_VAL]]) : (i8) -> ()
    anes.set_pal_pattern_at [1, 0, 2, 3] at (%x, %y)

// CHECK-NEXT: llvm.return
    return
}

// -----


// CHECK-LABEL: @fill_pal_pattern_at
// CHECK-SAME:   (%[[X:.*]]: i8, %[[Y:.*]]: i8, %[[LENGTH:.*]]: i16)
func.func @fill_pal_pattern_at(%x: i8, %y: i8, %length: i16) {
// bit pattern of 1, 0, 2, 3 in reverse: 11 10 00 01
// which evaluates to -32 for i8
// CHECK-DAG:  %[[PAL_PAT_VAL:.*]] = llvm.mlir.constant(-31 : i8) : i8
// CHECK-DAG:  %[[C0:.*]] = llvm.mlir.constant(0 : i8) : i8
// CHECK:      %[[ADDR:.*]] = llvm.call @get_at_addr(%[[C0]], %[[X]], %[[Y]])
// CHECK-NEXT: llvm.call @vram_adr(%[[ADDR]])
// CHECK-NEXT: llvm.call @vram_fill(%[[PAL_PAT_VAL]], %[[LENGTH]])
    anes.fill_pal_pattern_at [1, 0, 2, 3] x %length at (%x, %y)
    return
}

// -----

// CHECK: llvm.mlir.global internal @metasprite(dense<[0, 0, 1, 0, 8, 0, 1, 64, 0, 8, 17, 0, 8, 8, 4, 64, -128]> : tensor<17xi8>) {addr_space = 0 : i32} : !llvm.array<17 x i8>
anes.global_meta_sprite @metasprite(#anes.meta_sprite<[ 
    #anes.sprite_data<{tile = 1}>, #anes.sprite_data<{tile = 1, flip_hz = true}>,
    #anes.sprite_data<{tile = 17}>, #anes.sprite_data<{tile = 4, flip_hz = true}>
    
]> : !anes.meta_sprite_handle<2, 2>) : !anes.meta_sprite_handle<2, 2>

// CHECK-LABEL: @get_global_meta_sprite
func.func @get_global_meta_sprite() -> !anes.meta_sprite_handle<2, 2> {
// CHECK: %[[ADDR:.*]] = llvm.mlir.addressof @metasprite : !llvm.ptr
    %0 = anes.get_global_meta_sprite @metasprite : !anes.meta_sprite_handle<2, 2>
// CHECK-NEXT: llvm.return %[[ADDR]] : !llvm.ptr
    return %0 : !anes.meta_sprite_handle<2, 2>
}

// -----

// CHECK-LABEL: @set_meta_sprite_at
// CHECK-SAME:   (%[[PTR:.*]]: !llvm.ptr, %[[X:.*]]: i8, %[[Y:.*]]: i8)
func.func @set_meta_sprite_at(%metasprite: !anes.meta_sprite_handle<2, 2>, %x: i8, %y: i8) {
// CHECK-NEXT: llvm.call @oam_meta_spr(%[[X]], %[[Y]], %[[PTR]]) : (i8, i8, !llvm.ptr) -> ()
    anes.set_meta_sprite_at %metasprite at (%x, %y) : !anes.meta_sprite_handle<2, 2>

// // CHECK-NEXT: llvm.return
    return
}

// -----

// CHECK: llvm.mlir.global internal @metasprite(dense<[8, 0, 1, 64, 0, 8, 17, 0, 8, 8, 4, 64, -128]> : tensor<13xi8>) {addr_space = 0 : i32} : !llvm.array<13 x i8>
anes.global_meta_sprite @metasprite(#anes.meta_sprite<[ 
    #anes.sprite_data<{}>, #anes.sprite_data<{tile = 1, flip_hz = true}>,
    #anes.sprite_data<{tile = 17}>, #anes.sprite_data<{tile = 4, flip_hz = true}>
    
]> : !anes.meta_sprite_handle<2, 2>) : !anes.meta_sprite_handle<2, 2>
