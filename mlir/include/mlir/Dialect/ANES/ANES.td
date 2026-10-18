//===-- ANESOps.td - ANES dialect operation defs -------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the basic operations for the ANES dialect.
// It is intended to be an MLIR abstraction of the neslib defined in
// https://github.com/llvm-mos/llvm-mos-sdk/blob/main/mos-platform/nes/neslib/neslib.h
// with the aim developing a higher level language for NES programming.
// This is purely just for fun and shouldn't be taken that seriously nor expected
// to produce optimized code. Although, figuring out if there are higher level
// optimizations that can be done within the MLIR ecosystem might be part of
// the journey eventually.
// 
// This project, together with llvm-mos-sdk, can be used to compile and MLIR file
// to an NES program.  For example, the following was ported from the nesdoug tutorial
// https://github.com/nesdoug/06_Color/blob/master/color.c
// as a proof of concept:
//
// ```mlir
//  module attributes {
//    // Specifying the 6502 MOS target triple and typical 8-bit data layout
//    llvm.target_triple = "mos-nes-nrom",
//    llvm.data_layout = "e-m:e-p:16:8-p1:8:8-i16:8-i32:8-i64:8-f32:8-f64:8-a:8-Fi8-n8",
//    dlti.dl_spec = #dlti.dl_spec<#dlti.dl_entry<index, 16>>
//  } {
//  
//  llvm.mlir.global internal constant @blocks(
//  dense<[
//    0x01,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,0x31,0x30,
//    0x31,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,0x41,0x40,
//    0x41,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,0x11,0x10,
//    0x11,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,0x21,0x20,
//    0x21,0x00,0x01,0x3e,0x00,0x01,0x00
//  ]> : tensor<967xi8>) : !llvm.array<967 x i8>
//  
//  
//  llvm.func @main() -> i16 attributes {dso_local} {
//    anes.ppu_off 
//    
//    // set all 4 background palettes
//    anes.set_bg_palette
//      // universal background color shared across all palettes
//      15,
//      // grays
//      [0, 16, 48],
//      // blues
//      [1, 33, 49],
//      // reds
//      [6, 38, 54],
//      // greens
//      [9, 41, 57]
//    
//    %c8_i8 = arith.constant 8 : i8
//    %blocks_ptr = llvm.mlir.addressof @blocks : !llvm.ptr
//    anes.fill_tiles_from_rle_at %blocks_ptr at (%c8_i8, %c8_i8) : !llvm.ptr
//  
//    %length = arith.constant 8 : i16
//    %c00_i8 = arith.constant 0 : i8
//    anes.fill_pal_pattern_at [0, 0, 0, 0] x %length at (%c00_i8, %c00_i8)
//    %c32_i8 = arith.constant 32 : i8
//    anes.fill_pal_pattern_at [1, 1, 1, 1] x %length at (%c00_i8, %c32_i8)
//    %c64_i8 = arith.constant 64 : i8
//    anes.fill_pal_pattern_at [2, 2, 2, 2] x %length at (%c00_i8, %c64_i8)
//    %c96_i8 = arith.constant 96 : i8
//    anes.fill_pal_pattern_at [3, 3, 3, 3] x %length at (%c00_i8, %c96_i8)
//  
//    %c160_i8 = arith.constant 160 : i8
//    anes.set_pal_pattern_at [0, 1, 3, 2] at (%c64_i8, %c160_i8)
//  
//    anes.ppu_on
//  
//    %true = arith.constant 1 : i1
//  
//    scf.while : () -> () {
//      scf.condition(%true)
//    } do {
//      scf.yield
//    }
//  
//    %c0_i16 = arith.constant 0 : i16
//    llvm.return %c0_i16 : i16
//  }
//  
//  }
//  ```
//===----------------------------------------------------------------------===//

#ifndef ANES_OPS
#define ANES_OPS

include "mlir/IR/BuiltinAttributeInterfaces.td"
include "mlir/IR/BuiltinTypes.td"
include "mlir/Dialect/LLVMIR/LLVMTypes.td"

include "mlir/IR/CommonAttrConstraints.td"
include "mlir/IR/EnumAttr.td"
include "mlir/IR/SymbolInterfaces.td"

//===----------------------------------------------------------------------===//
// ANES dialect definition
//===----------------------------------------------------------------------===//

def ANES_Dialect : Dialect {
  let name = "anes";
  let cppNamespace = "::mlir::anes";

  let useDefaultTypePrinterParser = 1;
  let useDefaultAttributePrinterParser = 1;
}

class ANES_Type<string typeName, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<ANES_Dialect, typeName, traits> {
  let mnemonic = typeMnemonic;
}

class ANES_Op<string mnemonic, list<Trait> traits = []> :
  Op<ANES_Dialect, mnemonic, traits> {}

//===----------------------------------------------------------------------===//
// ANES dialect Enums 
//===----------------------------------------------------------------------===//

def NameTableEnum : I32EnumAttr<
    "NameTableEnum",
    "An enum representing the NES nametable; either a tile or color palette in nametable",
    [I32EnumAttrCase<"Tile", 0, "tile">, I32EnumAttrCase<"Palette", 1, "palette">]
> {
    let genSpecializedAttr = 0;
    let cppNamespace = "mlir::anes";
}

def PaletteTypeEnum : I32EnumAttr<
    "PaletteTypeEnum",
    "An enum representing a palette: either background or sprite",
    [I32EnumAttrCase<"Background", 0, "background">, I32EnumAttrCase<"Sprite", 1, "sprite">]
> {
    let genSpecializedAttr = 0;
    let cppNamespace = "mlir::anes";
}

//===----------------------------------------------------------------------===//
// ANES dialect Attributes 
//===----------------------------------------------------------------------===//

def NameTableAttr : EnumAttr<ANES_Dialect, NameTableEnum, "nametable_attr">;

def PaletteTypeAttr : EnumAttr<ANES_Dialect, PaletteTypeEnum, "palette_type_attr">;

def PaletteAttr : ConfinedAttr<DenseI8ArrayAttr, [
  AttrConstraint<CPred<"cast<DenseI8ArrayAttr>($_self).size() == 3">,
  "palette attribute must have 3 elements">
]>;

def MetaTilePalettePatternAttr : ConfinedAttr<DenseI8ArrayAttr, [
  AttrConstraint<CPred<"cast<DenseI8ArrayAttr>($_self).size() == 4">,
  "palette attribute must have 4 elements">
]>;

class ANESDialect_Attr<string name, string attrMnemonic, list<Trait> traits = []> 
    : AttrDef<ANES_Dialect, name, traits> {
  let mnemonic = attrMnemonic;
}

def SpriteAttributeAttr : ANESDialect_Attr<"SpriteAttribute", "sprite_attribute"> {
  let summary = "An attribute that represents the an NES spite attribute.";
  let description = [{
    The NES sprite attribute is an 8-bit value laid out as follows

      76543210
      ||||||||
      ||||||++- Palette (4 to 7) of sprite
      |||+++--- Unimplemented
      ||+------ Priority (0: in front of background; 1: behind background)
      |+------- Flip sprite horizontally
      +-------- Flip sprite vertically
  }];

  let parameters = (ins
    DefaultValuedParameter<"int", "0">:$palette_id,
    DefaultValuedParameter<"bool", "false">:$behind,
    DefaultValuedParameter<"bool", "false">:$flip_hz,
    DefaultValuedParameter<"bool", "false">:$flip_vr
  );

  let assemblyFormat = "`<``{` struct(params) `}``>`";
}

def SpriteDataAttr : ANESDialect_Attr<"SpriteData", "sprite_data"> {
  let summary = "An attribute that represents a sprite's data.";
  let description = [{
    Sprite is defined by coordinates tile id in CHR file and attribute.
    
    The NES sprite attribute is an 8-bit value laid out as follows

      76543210
      ||||||||
      ||||||++- Palette (4 to 7) of sprite
      |||+++--- Unimplemented
      ||+------ Priority (0: in front of background; 1: behind background)
      |+------- Flip sprite horizontally
      +-------- Flip sprite vertically
  }];

  let parameters = (ins
    OptionalParameter<"std::optional<int>">:$tile,
    DefaultValuedParameter<"int", "0">:$palette_id,
    DefaultValuedParameter<"bool", "false">:$behind,
    DefaultValuedParameter<"bool", "false">:$flip_hz,
    DefaultValuedParameter<"bool", "false">:$flip_vr
  );

  let assemblyFormat = "`<``{` struct(params) `}``>`";

  let extraClassDeclaration = [{
    int8_t packBits() {
      int8_t attribute = 0;
      attribute |= (getPaletteId() & 0x03); // Clamp palette to 0-3
      if (getBehind()) attribute |= (1 << 5);
      if (getFlipHz())    attribute |= (1 << 6);
      if (getFlipVr())    attribute |= (1 << 7);
      return attribute; 
    }
  }];
}

def ANES_MetaSpriteAttr : AttrDef<ANES_Dialect, "MetaSprite", [TypedAttrInterface]> {
  let summary = "2D matrix of `SpriteDataAttr`";
  let mnemonic = "meta_sprite";

  let parameters = (ins
    AttributeSelfTypeParameter<"The associated MetaSpriteHandleType", "::mlir::anes::MetaSpriteHandleType">:$type,
    
    ArrayRefParameter<"::mlir::anes::SpriteDataAttr", "array of `SpriteDataAttr`">:$elements
  );

  let assemblyFormat = "`<` `[` $elements `]` `>`";
}

//===----------------------------------------------------------------------===//
// ANES dialect Types
//===----------------------------------------------------------------------===//

def ANES_TetType : ANES_Type<"Test", "test">;

def ANES_MetaSpriteHandle : ANES_Type<"MetaSpriteHandle", "meta_sprite_handle"> {
  let parameters = (ins 
    "unsigned":$num_rows,
    "unsigned":$num_cols
  );
  let assemblyFormat = "`<` $num_rows`,` $num_cols `>`";
  
  let extraClassDeclaration = [{
    int64_t getNumElements() {
      return getNumRows() * getNumCols();
    }
  }];
}

//===----------------------------------------------------------------------===//
// ANES dialect Ops 
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// PPU Related 
//===----------------------------------------------------------------------===//

def ANES_PPUOffOp :
    ANES_Op<"ppu_off", []> {
  let summary = "Turn off PPU";

  let assemblyFormat = "attr-dict";
}

def ANES_PPUOnOp :
    ANES_Op<"ppu_on", []> {
  let summary = "Turn on PPU";

  let assemblyFormat = "attr-dict";
}

//===----------------------------------------------------------------------===//
// Background graphics
//===----------------------------------------------------------------------===//


def ANES_SetPalletteOp :
    ANES_Op<"set_palette", []> {
  let summary = "Set the 4 background or sprite palettes to specified color values";

  let description = [{
    The NES background palette is described by a 16 byte array, 1 byte for
    each color.  A single palette is 4 bytes/colors and there can be 4
    palettes loaded at a time. However, for some reason the first color in
    every palette must be the same color, and is used as a universal background
    color.  So here, instead of having 4 colors per palette, we have the universal
    background color as its own entry, and the 4 palettes contain only 3 colors
    each.

    This op creates the 16 byte array from its attribute operands then calls the `pal_bg`
    function from neslib.
  
  }];

  let arguments = (ins
    I8Attr:$ubc,
    PaletteAttr:$palette0,
    PaletteAttr:$palette1,
    PaletteAttr:$palette2,
    PaletteAttr:$palette3,
    PaletteTypeAttr:$palette_type
  );

  let assemblyFormat = "attr-dict $palette_type $ubc`,` $palette0`,` $palette1`,` $palette2`,` $palette3";
}

def ANES_SetSprPalletteOp :
    ANES_Op<"set_spr_palette", []> {
  let summary = "Set the sprite palette to a value in memory";

  let arguments = (ins LLVM_AnyPointer:$source);

  let assemblyFormat = "attr-dict $source `:` type($source)";
}

def ANES_SetVRAMAddrForTilePosOp :
    ANES_Op<"vram_addr_for_tile_pos", []> {
  let summary = "Set the VRAM address to the specified tile position";

  let description = [{
    This op computes the single 16-bit address in the NES nametable
    from the specified coordinate `(x, y)` for either a tile or an attribute.
    The tile address corresponds to where the actual tile will be placed
    on the screen, whereas the attribute corresponds to where a color palette
    will be applied.

    The units for tile coordinates are in tile indices

      `0 <= x < 32`
      `0 <= y < 30`
    
    An NES screen is 256x240 pixels, but graphics are processed in 8x8 tiles.
    so there is 32x30 grid of 8x8 tiles.

    The units for attribute coordinates are in pixels.  Although, it is currently
    unclear to me why, since apparently a color palette is used for 32x32
    meta-tiles but the neslib uses units of pixels anyway.
    TODO: Resolve this confusion and consider making the units the indices of meta-tile
    indices instead, or even tile indices.

    The `mode` attribute (either `tile` or `palette`) determines whether this op
    computes the address for a tile or a color palette.

    This op creates the 16-bit address from `(x, y)` and then passes the value to
    `vram_addr` from neslib. 
  }];

  let arguments = (ins I8:$x, I8:$y, NameTableAttr:$mode);

  let assemblyFormat = "attr-dict `(`$x`,` $y`)` $mode";
}

def ANES_VRAMPutOp :
    ANES_Op<"vram_put", []> {
  let summary = "Put a byte at current VRAM address";

  let arguments = (ins I8:$value);

  let assemblyFormat = "attr-dict $value";
}

def ANES_SetTileAtOp :
    ANES_Op<"set_tile_at", []> {
  let summary = "Set a tile at specified coordinate.";

  let description = [{
    The `value` is the position of the tile in the CHR file,
    The coordinate is in units of tile indices:
    
      `0 <= x < 32`
      `0 <= y < 30`

    This op creates the 16-bit address from `(x, y)`, passes the result to
    `vram_addr`, then passes `value` to `vram_put` from neslib.
  }];

  let arguments = (ins I8:$value, I8:$x, I8:$y);

  let assemblyFormat = "attr-dict $value `at` `(`$x`,` $y`)`";
}

def ANES_SetAllTilesAtOp :
    ANES_Op<"set_all_tiles_at", []> {
  let summary = "Set array of tiles contiguously starting at specified coordinate.";

  let description = [{
    The `array` is the positions of the tiles in the CHR file,
    The coordinate is in units of tile indices:
    
      `0 <= x < 32`
      `0 <= y < 30`
  }];

  let arguments = (ins LLVMArrayType:$array, I8:$x, I8:$y);

  let assemblyFormat = "attr-dict $array `at` `(`$x`,` $y`)` `:` type($array)";
}

def ANES_FillTilesFromRLEAtOp :
    ANES_Op<"fill_tiles_from_rle_at", []> {
  let summary = "Fill background with tiles specified by RLE compressed format starting at specified coordinate.";

  let description = [{
    I don't really know how RLE works yet, so I'll get back to this when I do.
    All I know is that it's an array that describes where tiles go in some compressed format.

    This op takes the array's pointer as well as the starting coordinates which, as usual,
    are in units of tile indices.

    This op creates the 16-bit address from `(x, y)`, passes the result to
    `vram_addr`, then passes `value` to `vram_put` from neslib.
  }];

  let arguments = (ins LLVM_AnyPointer:$array, I8:$x, I8:$y);

  let assemblyFormat = "attr-dict $array `at` `(`$x`,` $y`)` `:` type($array)";
}


def ANES_SetPalAttrAtOp :
    ANES_Op<"set_pal_pattern_at", []> {
  let summary = "Set the palette pattern for a meta-tile at specified coordinate.";

  let description = [{
    The palette pattern is defined as a 4x4 array of palette indices (0, 1, 2, or 3).
    It is used to color a 32x32 (pixel) meta-tile where each of the 4 palettes color
    one of the 16x16 tiles in the meta-tile (that's just how NES PPU works).
    In this op, it is represented as a 1D 4 element array. If $pattern = [p0, p1, p2, p3]
    then the meta-tile palettes look as follows
     _______
    |p0 | p1|
    |___|___|
    |p2 | p3|
    |___|___|

    where each quadrant contains a 2x2 array of 8x8 tiles.

    The coordinate is in units of pixels, however the NES will align to multiples of 32 pixels.
    TODO: Consider expressing coordinates in units of meta-tile positions
    (or regular tile positions to match `SetTileAtOp` convention) instead of pixels.
  }];

  let arguments = (ins MetaTilePalettePatternAttr:$pattern, I8:$x, I8:$y);

  let assemblyFormat = "attr-dict $pattern `at` `(`$x`,` $y`)`";
}

def ANES_FillPalAttrAtOp :
    ANES_Op<"fill_pal_pattern_at", []> {
  let summary = "Fill a contiguous sequence of meta-tiles with a palette pattern starting at specified coordinate.";

  let description = [{
    Similar to `SetPalAttrAtOp`, except that it fills `length` number of consecutive meta-tiles.
  }];

  let arguments = (ins MetaTilePalettePatternAttr:$pattern, I16:$length, I8:$x, I8:$y);

  let assemblyFormat = "attr-dict $pattern `x` $length `at` `(`$x`,` $y`)`";
}

//===----------------------------------------------------------------------===//
// Sprite graphics
//===----------------------------------------------------------------------===//

def ANES_CreateMetaSpriteOp :
ANES_Op<"create_meta_sprite", []> {
  let summary = "Creates a meta-sprite from coordinate, attribute, and tile values.";

  let description = [{
    This op takes a variadic list of tuples (x, y, tile, attribute), where x and y
    are the positional coordinates of the meta-sprite, tile is the index of the tile
    in the CHR file, and attribute is the 8-bit sprite attribute (see `SpriteAttributeAttr`).

    ```mlir
      anes.create_meta_sprite [
          (%x, %y, %tile, #anes.sprite_attribute<{palette_id = 0, flip_hz = true}>),
          (%x2, %y2, %tile, #anes.sprite_attribute<{palette_id = 3, behind = true}>)
      ]
    ```
  }];

  let arguments = (ins
      ANES_MetaSpriteAttr:$meta_tile
  );

    let assemblyFormat = "attr-dict $meta_tile";
}


def ANES_GlobalMetaSpriteOp : ANES_Op<"global_meta_sprite",
    [IsolatedFromAbove, SymbolName,
     SymbolVisibility, Symbol]> {
  let arguments = (ins
    SymbolNameAttr:$sym_name,
    TypeAttr:$result_type,
    OptionalAttr<ANES_MetaSpriteAttr>:$value,
    OptionalAttr<UnitAttr>:$constant,
    OptionalAttr<StrAttr>:$sym_visibility
  );
  let summary = "Global for meta-sprite.";
  let description = [{

  }];

  let assemblyFormat = [{attr-dict
    ($sym_visibility^)? (`constant` $constant^)? $sym_name`(`(qualified($value)^)?`)` `:` $result_type
  }];
}

//===----------------------------------------------------------------------===//
// GetGlobalMetaSpriteOp
//===----------------------------------------------------------------------===//

def ANES_GetGlobalMetaSpriteOp : ANES_Op<"get_global_meta_sprite",
    [Pure, DeclareOpInterfaceMethods<SymbolUserOpInterface>]> {
  let summary = "Get the value from a `global_meta_sprite` op";

  let arguments = (ins FlatSymbolRefAttr:$name);
  let results = (outs ANES_MetaSpriteHandle:$result);
  let assemblyFormat = " attr-dict $name `:` type($result)";
}

//===----------------------------------------------------------------------===//
// SetMetaSpriteAtOp
//===----------------------------------------------------------------------===//

def ANES_SetMetaSpriteAtOp :
    ANES_Op<"set_meta_sprite_at", []> {
  let summary = "Set a meta sprite at specified coordinate.";

  let description = [{
    The `meta_sprite` is an i8 array corresponding to meta sprite data. 

    This op creates a pointer to the meta sprite data, and passes it
    and coordinates to `oam_meta_sprite` from neslib.
  }];

  let arguments = (ins ANES_MetaSpriteHandle:$meta_sprite, I8:$x, I8:$y);

  let assemblyFormat = "attr-dict $meta_sprite `at` `(`$x`,` $y`)` `:` type($meta_sprite)";
}

#endif // ANES_OPS
