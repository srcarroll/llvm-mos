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

// TODO: Yes this file is bloated. We really should have separate attribute, types,
// etc files. But, for now, everything is lumped together out of laziness.
// This makes absolutely no functional difference.  It's more of a matter of organization,
// separation of concerns, and compartmentalizing libraries.

//===----------------------------------------------------------------------===//
// ANES dialect definition
//===----------------------------------------------------------------------===//

def ANES_Dialect : Dialect {
  let name = "anes";
  let cppNamespace = "::mlir::anes";

  let useDefaultTypePrinterParser = 1;
  let useDefaultAttributePrinterParser = 1;
}

//===----------------------------------------------------------------------===//
// ANES dialect Enums 
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// APU Related 
//===----------------------------------------------------------------------===//

def APUChannelEnum : I32EnumAttr<
    "APUChannelEnum",
    "An enum representing one of the 5 NES APU channels",
    [I32EnumAttrCase<"Pulse0", 0, "pulse0">, I32EnumAttrCase<"Pulse1", 1, "pulse1">,
     I32EnumAttrCase<"Triangle", 2, "triangle">, I32EnumAttrCase<"Noise", 3, "noise">,
     I32EnumAttrCase<"DMC", 4, "dmnc">]
> {
    let genSpecializedAttr = 0;
    let cppNamespace = "mlir::anes";
}

//===----------------------------------------------------------------------===//
// PPU Related 
//===----------------------------------------------------------------------===//

def NameTableEnum : I32EnumAttr<
    "NameTableEnum",
    "An enum representing the one of the 4 NES nametables",
    [I32EnumAttrCase<"A", 8192, "a">, I32EnumAttrCase<"B", 9216, "b">,
     I32EnumAttrCase<"C", 10240, "c">, I32EnumAttrCase<"D", 11264, "d">]
> {
    let genSpecializedAttr = 0;
    let cppNamespace = "mlir::anes";
}

def NameTableTypeEnum : I32EnumAttr<
    "NameTableTypeEnum",
    "An enum representing the NES nametable type; either a tile or color palette in nametable",
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

//===----------------------------------------------------------------------===//
// APU Related 
//===----------------------------------------------------------------------===//

def APUChannelAttr : EnumAttr<ANES_Dialect, APUChannelEnum, "apu_channel_attr">;

//===----------------------------------------------------------------------===//
// PPU Related 
//===----------------------------------------------------------------------===//

def NameTableAttr : EnumAttr<ANES_Dialect, NameTableEnum, "nametable_attr">;

def NameTableTypeAttr : EnumAttr<ANES_Dialect, NameTableTypeEnum, "nametable_type_attr">;

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

class ANES_Type<string typeName, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<ANES_Dialect, typeName, traits> {
  let mnemonic = typeMnemonic;
}

//===----------------------------------------------------------------------===//
// APU Related 
//===----------------------------------------------------------------------===//

def ANES_PulseParametersType : ANES_Type<"PulseParameters", "pulse_parameters"> {
  let summary = "Parameters of the NES APU's pulse channel.";

  let parameters = (ins);

  let assemblyFormat = "";
}

def ANES_TriangleParametersType : ANES_Type<"TriangleParameters", "triangle_parameters"> {
  let summary = "Parameters of the NES APU's triangle channel.";

  let parameters = (ins);

  let assemblyFormat = "";
}

//===----------------------------------------------------------------------===//
// PPU Related 
//===----------------------------------------------------------------------===//

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

class ANES_Op<string mnemonic, list<Trait> traits = []> :
  Op<ANES_Dialect, mnemonic, traits> {}

//===----------------------------------------------------------------------===//
// APU Related 
//===----------------------------------------------------------------------===//

def ANES_SetStatusOp :
    ANES_Op<"apu.set_status", []> {
  let summary = "Set the APU status";

  let description = [{
    Enables the specified APU channel(s).  This is not a toggle
    for individual channels. Channels not specified when invoking
    this op will be turned off regardless of their current state.
  }];

  let arguments = (ins
    UnitAttr:$pulse0,
    UnitAttr:$pulse1,
    UnitAttr:$triangle,
    UnitAttr:$noise,
    UnitAttr:$dmc
  );

  let assemblyFormat = [{
    oilist(
      `pulse0` $pulse0 
      | `pulse1` $pulse1 
      | `triangle` $triangle
      | `noise` $noise
      | `dmc` $dmc
    )
    attr-dict
  }];

  let extraClassDeclaration = [{
    static constexpr int16_t kAddress =  0x4015;

    uint8_t packBits() {
      return 
        getPulse0() | 
        (getPulse1() << 1) |
        (getTriangle() << 2) | 
        (getNoise() << 3) |
        (getDmc() << 4);
    }
  }];
}

//===----------------------------------------------------------------------===//
// APU Channel Interface
//===----------------------------------------------------------------------===//

def APUChannelOpInterface : OpInterface<"APUChannelOpInterface"> {
  let description = [{
    Interface for ops that implement an APU channel.

    An APU channel consists of (up to) 4 8-bit registers.
  }];

  let cppNamespace = "::mlir::anes";

  let methods = [
    StaticInterfaceMethod<
      /*desc=*/"Returns address of register 0.",
      /*returnType=*/"unsigned",
      /*methodName=*/"getReg0Address", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns address of register 1.",
      /*returnType=*/"unsigned",
      /*methodName=*/"getReg1Address", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns address of register 2.",
      /*returnType=*/"unsigned",
      /*methodName=*/"getReg2Address", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns address of register 3.",
      /*returnType=*/"unsigned",
      /*methodName=*/"getReg3Address", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns the ordered bit positions of each field in reg 0.",
      /*returnType=*/"llvm::SmallVector<unsigned>",
      /*methodName=*/"getReg0FieldPositions", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns the ordered bit positions of each field in reg 1.",
      /*returnType=*/"llvm::SmallVector<unsigned>",
      /*methodName=*/"getReg1FieldPositions", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns the ordered bit positions of each field in reg 2.",
      /*returnType=*/"llvm::SmallVector<unsigned>",
      /*methodName=*/"getReg2FieldPositions", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns the ordered bit positions of each field in reg 3.",
      /*returnType=*/"llvm::SmallVector<unsigned>",
      /*methodName=*/"getReg3FieldPositions", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns the ordered bit-widths of each field.",
      /*returnType=*/"llvm::SmallVector<unsigned>",
      /*methodName=*/"getReg0FieldWidths", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns the ordered bit-widths of each field.",
      /*returnType=*/"llvm::SmallVector<unsigned>",
      /*methodName=*/"getReg1FieldWidths", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns the ordered bit-widths of each field.",
      /*returnType=*/"llvm::SmallVector<unsigned>",
      /*methodName=*/"getReg2FieldWidths", (ins)
    >,
    StaticInterfaceMethod<
      /*desc=*/"Returns the ordered bit-widths of each field.",
      /*returnType=*/"llvm::SmallVector<unsigned>",
      /*methodName=*/"getReg3FieldWidths", (ins)
    >,
    InterfaceMethod<
      /*desc=*/"Returns operands associated with register 0.",
      /*returnType=*/"::llvm::SmallVector<Value>",
      /*methodName=*/"getReg0Fields",
      /*args=*/(ins)
    >,
    InterfaceMethod<
      /*desc=*/"Returns operands associated with register 1.",
      /*returnType=*/"::llvm::SmallVector<Value>",
      /*methodName=*/"getReg1Fields",
      /*args=*/(ins)
    >,
    InterfaceMethod<
      /*desc=*/"Returns operands associated with register 2.",
      /*returnType=*/"::llvm::SmallVector<Value>",
      /*methodName=*/"getReg2Fields",
      /*args=*/(ins)
    >,
    InterfaceMethod<
      /*desc=*/"Returns operands associated with register 3.",
      /*returnType=*/"::llvm::SmallVector<Value>",
      /*methodName=*/"getReg3Fields",
      /*args=*/(ins)
    >,
    InterfaceMethod<
      /*desc=*/"Returns true if any reg 0 fields are present.",
      /*returnType=*/"bool",
      /*methodName=*/"hasReg0",
      /*args=*/(ins),
      /*methodBody=*/[{
        return ::llvm::any_of($_op.getReg0Fields(), [](Value val) { return val != nullptr; });
      }]
    >,
    InterfaceMethod<
      /*desc=*/"Returns true if any reg 1 fields are present.",
      /*returnType=*/"bool",
      /*methodName=*/"hasReg1",
      /*args=*/(ins),
      /*methodBody=*/[{
        return ::llvm::any_of($_op.getReg1Fields(), [](Value val) { return val != nullptr; });
      }]
    >,
    InterfaceMethod<
      /*desc=*/"Returns true if any reg 2 fields are present.",
      /*returnType=*/"bool",
      /*methodName=*/"hasReg2",
      /*args=*/(ins),
      /*methodBody=*/[{
        return ::llvm::any_of($_op.getReg2Fields(), [](Value val) { return val != nullptr; });
      }]
    >,
    InterfaceMethod<
      /*desc=*/"Returns true if any reg 3 fields are present.",
      /*returnType=*/"bool",
      /*methodName=*/"hasReg3",
      /*args=*/(ins),
      /*methodBody=*/[{
        return ::llvm::any_of($_op.getReg3Fields(), [](Value val) { return val != nullptr; });
      }]
    >
  ];

  // let verify = [{
  //   unsigned total = 0;
  //   for (unsigned w : ::mlir::cast<RegisterEncodingOpInterface>($_op).getFieldWidths())
  //     total += w;
  //   unsigned regWidth = $_op->getResult(0).getType().getIntOrFloatBitWidth();
  //   if (total != regWidth)
  //     return $_op->emitOpError("field widths sum to ") << total 
  //            << ", expected " << regWidth;
  //   return success();
  // }];
}

def ANES_SetPulseParametersOp :
    ANES_Op<"apu.set_pulse_parameters", [AttrSizedOperandSegments]> {
  let summary = "Sets the parameters of the APU's pulse channel";

  // TODO: Add argument for choosing which square channel (0 or 1)
  let arguments = (ins
    Optional<I<2>>:$duty,
    Optional<I1>:$env_loop,
    Optional<I1>:$const_volume,
    Optional<I8>:$env_divider,
    Optional<I1>:$sweep_enable,
    Optional<I8>:$sweep_period,
    Optional<I1>:$negate_shift,
    Optional<I8>:$shift,
    Optional<I16>:$period,
    Optional<I8>:$length_counter
  );

  let assemblyFormat = [{
    oilist<`,`>(
      `duty` $duty 
      | `env_loop` $env_loop 
      | `const_volume` $const_volume
      | `env_divider` $env_divider
      | `sweep_enable` $sweep_enable
      | `sweep_period` $sweep_period
      | `negate_shift` $negate_shift
      | `shift` $shift
      | `period` $period
      | `length_counter` $length_counter
    )
    attr-dict
  }];

  let extraClassDeclaration = [{
    static constexpr int16_t kControlAddress = 0x4000;
    static constexpr int16_t kRampAddress = 0x4001;
    static constexpr int16_t kPeriodLowAddress = 0x4002;
    static constexpr int16_t kPeriodHighAddress = 0x4003;

    // control register bits
    static constexpr int kEnvDivBitsPos = 0;
    static constexpr int kEnvDivBitsWidth = 4;
    static constexpr int kConstVolBitsPos = 4;
    static constexpr int kConstVolBitsWidth = 1;
    static constexpr int kEnvLoopBitsPos = 5;
    static constexpr int kEnvLoopBitsWidth = 1;
    static constexpr int kDutyBitsPos = 6;
    static constexpr int kDutyBitsWidth = 2;

    // ramp bits
    static constexpr int kShiftBitsPos = 0;
    static constexpr int kShiftBitsWidth = 3;
    static constexpr int kNegateShiftBitsPos = 3;
    static constexpr int kNegateShiftBitsWidth = 1;
    static constexpr int kSweepPeriodBitsPos = 4;
    static constexpr int kSweepPeriodBitsWidth = 3;
    static constexpr int kSweepEnableBitsPos = 7;
    static constexpr int kSweepEnableBitsWidth = 1;

    // period low
    static constexpr int kLowPeriodBitsPos = 0;
    static constexpr int kLowPeriodBitsWidth = 8;

    // period high
    static constexpr int kHighPeriodBitsPos = 0;
    static constexpr int kHighPeriodBitsWidth = 3;
    static constexpr int kLengthCounterBitsPos = 3;
    static constexpr int kLengthCounterBitsWidth = 5;

    static constexpr int kTotalPeriodBits = 11;

    bool hasControlBits() {
      return
        (getDuty() != nullptr) ||
        (getEnvLoop() != nullptr) ||
        (getConstVolume() != nullptr) ||
        (getEnvDivider() != nullptr);
    }

    bool hasRampBits() {
      return
        (getShift() != nullptr) ||
        (getNegateShift() != nullptr) ||
        (getSweepPeriod() != nullptr) ||
        (getSweepEnable() != nullptr);
    }

    bool hasLowPeriodBits() {
      return
        (getPeriod() != nullptr);
    }

    bool hasHighPeriodBits() {
      return
        (getPeriod() != nullptr) ||
        (getLengthCounter() != nullptr);
    }
  }];
}

// Dumb that this doesn't already exist.
class SnakeToCamel<string str, bit capitalizeFirst = 0> {
  // Split into single characters
  list<string> chars = !foreach(i, !range(0, !size(str)), !substr(str, i, 1));

  // Capitalize any character preceded by "_" (and index 0 if capitalizeFirst)
  list<string> mapped = !foreach(i, !range(0, !size(chars)),
    !if(!eq(chars[i], "_"), "",
      !if(!or(!and(!eq(i, 0), capitalizeFirst),
              !and(!gt(i, 0), !eq(chars[!sub(i, 1)], "_"))),
        !toupper(chars[i]),
        chars[i]
      )
    )
  );

  string ret = !interleave(mapped, "");
}

class APURegisterField<string k, int v, int p> {
  string name = k;
  int width = v;
  int position = p;
}

class APURegister<list<APURegisterField> f, int a> {
  list<APURegisterField> fields = f; 
  int address = a;
}

class APUChannelOp<
  string channel_name,
  APURegister reg0,
  APURegister reg1,
  APURegister reg2,
  APURegister reg3,
  list<Trait> traits = []>
    : ANES_Op<"apu.set_" # channel_name # "_parameters", !listconcat(traits, [
        Pure,
        DeclareOpInterfaceMethods<APUChannelOpInterface>
      ])> {

  let summary = "Sets the parameters of the APU's " # channel_name # " channel";

  list<string> reg0FieldNames = !foreach(p, reg0.fields, p.name);
  list<string> reg1FieldNames = !foreach(p, reg1.fields, p.name);
  list<string> reg2FieldNames = !foreach(p, reg2.fields, p.name);
  list<string> reg3FieldNames = !foreach(p, reg3.fields, p.name);

  list<int> reg0FieldWidths = !foreach(p, reg0.fields, p.width);
  list<int> reg1FieldWidths = !foreach(p, reg1.fields, p.width);
  list<int> reg2FieldWidths = !foreach(p, reg2.fields, p.width);
  list<int> reg3FieldWidths = !foreach(p, reg3.fields, p.width);

  list<int> reg0FieldPositions = !foreach(p, reg0.fields, p.position);
  list<int> reg1FieldPositions = !foreach(p, reg1.fields, p.position);
  list<int> reg2FieldPositions = !foreach(p, reg2.fields, p.position);
  list<int> reg3FieldPositions = !foreach(p, reg3.fields, p.position);

  list<TypeConstraint> reg0FieldTypes = !foreach(p, reg0.fields, Optional<I<p.width>>); 
  list<TypeConstraint> reg1FieldTypes = !foreach(p, reg1.fields, Optional<I<p.width>>); 
  list<TypeConstraint> reg2FieldTypes = !foreach(p, reg2.fields, Optional<I<p.width>>); 
  list<TypeConstraint> reg3FieldTypes = !foreach(p, reg3.fields, Optional<I<p.width>>); 

  let arguments = !dag(ins, reg0FieldTypes, reg0FieldNames);
  let append arguments = !dag(ins, reg1FieldTypes, reg1FieldNames);
  let append arguments = !dag(ins, reg2FieldTypes, reg2FieldNames);
  let append arguments = !dag(ins, reg3FieldTypes, reg3FieldNames);

  let assemblyFormat = "oilist<`,`>(" # !interleave(
    !foreach(n, !listconcat(reg0FieldNames, reg1FieldNames, reg2FieldNames, reg3FieldNames), "`" # n # "` $" # n),
    " | "
  ) # ") attr-dict";

  let extraClassDefinition = [{
    unsigned $cppClass::getReg0Address() {
      return }] # reg0.address # [{;
    }

    unsigned $cppClass::getReg1Address() {
      return }] # reg1.address # [{;
    }

    unsigned $cppClass::getReg2Address() {
      return }] # reg2.address # [{;
    }

    unsigned $cppClass::getReg3Address() {
      return }] # reg3.address # [{;
    }

    llvm::SmallVector<unsigned> $cppClass::getReg0FieldWidths() {
      return { }] # !interleave(reg0FieldWidths, ", ") # [{ };
    }

    llvm::SmallVector<unsigned> $cppClass::getReg1FieldWidths() {
      return { }] # !interleave(reg1FieldWidths, ", ") # [{ };
    }

    llvm::SmallVector<unsigned> $cppClass::getReg2FieldWidths() {
      return { }] # !interleave(reg2FieldWidths, ", ") # [{ };
    }

    llvm::SmallVector<unsigned> $cppClass::getReg3FieldWidths() {
      return { }] # !interleave(reg3FieldWidths, ", ") # [{ };
    }

    llvm::SmallVector<unsigned> $cppClass::getReg0FieldPositions() {
      return { }] # !interleave(reg0FieldPositions, ", ") # [{ };
    }

    llvm::SmallVector<unsigned> $cppClass::getReg1FieldPositions() {
      return { }] # !interleave(reg1FieldPositions, ", ") # [{ };
    }

    llvm::SmallVector<unsigned> $cppClass::getReg2FieldPositions() {
      return { }] # !interleave(reg2FieldPositions, ", ") # [{ };
    }

    llvm::SmallVector<unsigned> $cppClass::getReg3FieldPositions() {
      return { }] # !interleave(reg3FieldPositions, ", ") # [{ };
    }

    llvm::SmallVector<Value> $cppClass::getReg0Fields() {
      return { }] # !interleave(!foreach(n, reg0FieldNames, "get" # SnakeToCamel<n, 1>.ret # "()"), ", ") # [{ };
    }

    llvm::SmallVector<Value> $cppClass::getReg1Fields() {
      return { }] # !interleave(!foreach(n, reg1FieldNames, "get" # SnakeToCamel<n, 1>.ret # "()"), ", ") # [{ };
    }

    llvm::SmallVector<Value> $cppClass::getReg2Fields() {
      return { }] # !interleave(!foreach(n, reg2FieldNames, "get" # SnakeToCamel<n, 1>.ret # "()"), ", ") # [{ };
    }

    llvm::SmallVector<Value> $cppClass::getReg3Fields() {
      return { }] # !interleave(!foreach(n, reg3FieldNames, "get" # SnakeToCamel<n, 1>.ret # "()"), ", ") # [{ };
    }
  }];

}

def ANES_SetPulse0ParametersOp :
    APUChannelOp<
      "pulse0",
      APURegister<[APURegisterField<"duty", 2, 6>, APURegisterField<"envelope_loop", 1, 5>,
                   APURegisterField<"constant_volume", 1, 4>, APURegisterField<"volume", 4, 0>], 0x4000>,
      APURegister<[APURegisterField<"sweep_enable", 1, 7>, APURegisterField<"sweep_period", 3, 4>,
                   APURegisterField<"sweep_negate", 1, 3>, APURegisterField<"sweep_shift", 3, 0>], 0x4001>,
      APURegister<[APURegisterField<"period_low", 8, 0>], 0x4002>,
      APURegister<[APURegisterField<"length_counter", 5, 3>, APURegisterField<"period_high", 3, 0>], 0x4003>,
      [AttrSizedOperandSegments, APUChannelOpInterface]> {
}

def ANES_SetPulse1ParametersOp :
    APUChannelOp<
      "pulse1",
      APURegister<[APURegisterField<"duty", 2, 6>, APURegisterField<"envelope_loop", 1, 5>,
                   APURegisterField<"constant_volume", 1, 4>, APURegisterField<"volume", 4, 0>], 0x4004>,
      APURegister<[APURegisterField<"sweep_enable", 1, 7>, APURegisterField<"sweep_period", 3, 4>,
                   APURegisterField<"sweep_negate", 1, 3>, APURegisterField<"sweep_shift", 3, 0>], 0x4005>,
      APURegister<[APURegisterField<"period_low", 8, 0>], 0x4006>,
      APURegister<[APURegisterField<"length_counter", 5, 3>, APURegisterField<"period_high", 3, 0>], 0x4007>,
      [AttrSizedOperandSegments, APUChannelOpInterface]> {
}

def ANES_SetTriangleParametersOp :
    APUChannelOp<
      "triangle",
      APURegister<[APURegisterField<"counter_control", 1, 7>, APURegisterField<"linear_counter", 7, 0>], 0x4008>,
      APURegister<[], 0x4009>,
      APURegister<[APURegisterField<"period_low", 8, 0>], 0x400A>,
      APURegister<[APURegisterField<"length_counter", 5, 3>, APURegisterField<"period_high", 3, 0>], 0x400B>,
      [AttrSizedOperandSegments, APUChannelOpInterface]> {
}

def ANES_SetNoiseParametersOp :
    APUChannelOp<
      "noise",
      APURegister<[APURegisterField<"counter_control", 1, 5>, APURegisterField<"constant_volume", 1, 4>,
                   APURegisterField<"volume", 4, 0>], 0x400C>,
      APURegister<[], 0x400D>, // unused
      APURegister<[APURegisterField<"periodic_noise_mode", 1, 7>, APURegisterField<"noise_period", 4, 0>], 0x400E>,
      APURegister<[APURegisterField<"length_counter", 5, 3>], 0x400F>,
      [AttrSizedOperandSegments, APUChannelOpInterface]> {
}

def ANES_SetDMCParametersOp :
    APUChannelOp<
      "dmc",
      APURegister<[APURegisterField<"irq_enable", 1, 7>, APURegisterField<"loop", 1, 6>,
                   APURegisterField<"sample_rate", 4, 0>], 0x4010>,
      APURegister<[APURegisterField<"load_counter", 7, 0>], 0x4011>,
      APURegister<[APURegisterField<"sample_address", 8, 0>], 0x4012>,
      APURegister<[APURegisterField<"sample_length", 8, 0>], 0x4013>,
      [AttrSizedOperandSegments, APUChannelOpInterface]> {
}

def ANES_SetChannelParametersOp :
    ANES_Op<"apu.set_channel_parameters", []> {
  let summary = "Sets the channel parameters in APU registers.";

  let arguments = (ins
    AnyTypeOf<[
      ANES_PulseParametersType,
      ANES_TriangleParametersType]>:$params
  );

  let assemblyFormat = "$params attr-dict `:` qualified(type($params))";
}

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

def ANES_BankSprOp: 
 ANES_Op<"ppu.bank_spr", []> {
  let summary = "Set sprite bank";

  let arguments = (ins
    I8:$bank
  );

  let assemblyFormat = "$bank attr-dict";
}

def ANES_OAMClearOp: 
 ANES_Op<"ppu.oam_clear", []> {
  let summary = "Clear object attribute memory";

  let assemblyFormat = "attr-dict ";
}

def ANES_PPUWAitNMIOp: 
 ANES_Op<"ppu.wait_nmi", []> {
  let summary = "Wait NMI";

  let assemblyFormat = "attr-dict ";
}

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

  let arguments = (ins I8:$x, I8:$y, NameTableTypeAttr:$mode, NameTableAttr:$nametable);

  let assemblyFormat = "attr-dict $nametable`(`$x`,` $y`)` $mode";
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

  let assemblyFormat = "attr-dict $array `at` `(`$x`,` $y`)` `:` qualified(type($array))";
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

  let arguments = (ins LLVM_AnyPointer:$array, I8:$x, I8:$y, NameTableAttr:$nametable);

  let assemblyFormat = "$array `at`  $nametable`(`$x`,` $y`)` attr-dict `:` type($array)";
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

def ANES_ScrollScreenOp :
    ANES_Op<"scroll_screen", []> {
  let summary = "Sets the background scroll values.";

  let arguments = (ins Index:$x, Index:$y);

  let assemblyFormat = "attr-dict `(`$x`,` $y`)`";
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
  let assemblyFormat = " attr-dict $name `:` qualified(type($result))";
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

  let assemblyFormat = "$meta_sprite `at` `(`$x`,` $y`)` attr-dict `:` qualified(type($meta_sprite))";
}

#endif // ANES_OPS
