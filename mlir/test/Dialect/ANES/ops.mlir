// RUN: mlir-opt -allow-unregistered-dialect %s | FileCheck %s
// Verify the printed output can be parsed.
// RUN: mlir-opt -allow-unregistered-dialect -split-input-file %s | mlir-opt -allow-unregistered-dialect -split-input-file | FileCheck %s
// Verify the generic form can be parsed.
// RUN: mlir-opt -allow-unregistered-dialect -mlir-print-op-generic -split-input-file %s | mlir-opt -allow-unregistered-dialect -split-input-file | FileCheck %s

// CHECK-LABEL: @set_bg_palette
// CHECK: anes.set_palette <background> 0, [0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11]
func.func @set_bg_palette() {
    anes.set_palette <background> 0, [0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11]
    return
}

// -----

// CHECK-LABEL: @vram_addr_for_tile_pos_tile
// CHECK: anes.vram_addr_for_tile_pos <a>({{.*}}, {{.*}}) <tile>
func.func @vram_addr_for_tile_pos_tile(%x: i8, %y: i8) {
    anes.vram_addr_for_tile_pos <a>(%x, %y) <tile> 
    return
}

// -----

// CHECK-LABEL: @vram_addr_for_tile_pos_pal
// CHECK: anes.vram_addr_for_tile_pos <a>({{.*}}, {{.*}}) <palette>
func.func @vram_addr_for_tile_pos_pal(%x: i8, %y: i8) {
    anes.vram_addr_for_tile_pos <a> (%x, %y) <palette> 
    return
}

// -----

// CHECK-LABEL: @ppu_off
// CHECK: anes.ppu_off
func.func @ppu_off() {
    anes.ppu_off
    return
}

// -----

func.func @set_pal_pattern_at(%x: i8, %y: i8) {
    anes.set_pal_pattern_at [1, 0, 2, 3] at (%x, %y)
    return
}

// -----

func.func @set_tile_at(%value: i8, %x: i8, %y: i8) {
    anes.set_tile_at %value at (%x, %y)
    return
}

// -----

func.func @set_tiles_at(%value: !llvm.array<12 x i8>, %x: i8, %y: i8) {
    anes.set_all_tiles_at %value at (%x, %y) : !llvm.array<12 x i8>
    return
}

// -----

func.func @fill_tiles_from_compressed_at(%value: !llvm.ptr, %x: i8, %y: i8) {
    anes.fill_tiles_from_rle_at %value at <a> (%x, %y) : !llvm.ptr
    return
}

// -----

func.func @fill_pal_pattern_at(%x: i8, %y: i8, %length: i16) {
    anes.fill_pal_pattern_at [1, 0, 2, 3] x %length at (%x, %y)
    return
}

// -----

#sprite_attribute = #anes.sprite_attribute<{palette_id = 1, flip_hz = true}>

anes.global_meta_sprite @sprite_global(
   #anes.meta_sprite<[
    #anes.sprite_data<{tile = 32, flip_hz = true}>,
   #anes.sprite_data<{tile = 32, palette_id = 2}>]> : !anes.meta_sprite_handle<2, 1>
) : !anes.meta_sprite_handle<2, 1>

func.func @get_global_meta_sprite() -> !anes.meta_sprite_handle<2, 1> {
    %0 = anes.get_global_meta_sprite @sprite_global : !anes.meta_sprite_handle<2, 1>
    return %0 : !anes.meta_sprite_handle<2, 1>
}

func.func @set_meta_sprite(%metasprite: !anes.meta_sprite_handle<2, 1>, %x: i8, %y: i8) {
    anes.set_meta_sprite_at %metasprite at (%x, %y) : !anes.meta_sprite_handle<2, 1>
    return
}
