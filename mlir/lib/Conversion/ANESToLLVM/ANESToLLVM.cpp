//===- ANESToLLVM.cpp - ANES to LLVM dialect conversion -------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/ANESToLLVM/ANESToLLVM.h"

#include "mlir/Conversion/ConvertToLLVM/ToLLVMInterface.h"
#include "mlir/Conversion/LLVMCommon/ConversionTarget.h"
#include "mlir/Conversion/LLVMCommon/Pattern.h"
#include "mlir/Conversion/LLVMCommon/TypeConverter.h"
#include "mlir/Dialect/ANES/ANES.h"
#include "mlir/Dialect/LLVMIR/FunctionCallUtils.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Pass/Pass.h"


namespace mlir {
#define GEN_PASS_DEF_ANESTOLLVMCONVERSIONPASS
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;

//===----------------------------------------------------------------------===//
// Pattern implementations
//===----------------------------------------------------------------------===//

struct PPUOffOpLowering final : public OpConversionPattern<anes::PPUOffOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::PPUOffOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    auto funcOp =
        LLVM::lookupOrCreateFn(rewriter, moduleOp, "ppu_off", {},
                               LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(
          op, "could not find or create ppu_off func");
    auto callOp = LLVM::CallOp::create(rewriter, loc, funcOp.value(), {});
    rewriter.replaceOp(op, callOp);
    return success();
  }
};

struct PPUOnOpLowering final : public OpConversionPattern<anes::PPUOnOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::PPUOnOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    auto funcOp =
        LLVM::lookupOrCreateFn(rewriter, moduleOp, "ppu_on_all", {},
                               LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(
          op, "could not find or create ppu_on_all func");
    auto callOp = LLVM::CallOp::create(rewriter, loc, funcOp.value(), {});
    rewriter.replaceOp(op, callOp);
    return success();
  }
};

static LLVM::GlobalOp
getOrCreateGlobal(OpBuilder &builder, Location loc, ModuleOp module,
                  StringRef name, Type type, bool isConstant = false,
                  LLVM::Linkage linkage = LLVM::Linkage::Internal) {
  if (auto global = module.lookupSymbol<LLVM::GlobalOp>(name)) {
    return global;
  }

  OpBuilder::InsertionGuard guard(builder);
  builder.setInsertionPointToStart(module.getBody());

  return LLVM::GlobalOp::create(builder, loc, type, isConstant, linkage, name,
                                /*value=*/Attribute());
}

//===----------------------------------------------------------------------===//
// Background Graphics Related Ops
//===----------------------------------------------------------------------===//

struct SetPalletteOpLowering final
    : public OpConversionPattern<anes::SetPalletteOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::SetPalletteOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    StringRef paletteName =
        (op.getPaletteType() == anes::PaletteTypeEnum::Background)
            ? "bg_palette"
            : "spr_palette";
    (void)getOrCreateGlobal(rewriter, loc, moduleOp, paletteName,
                            LLVM::LLVMArrayType::get(rewriter.getI8Type(), 16));

    Value addr = LLVM::AddressOfOp::create(
        rewriter, loc, LLVM::LLVMPointerType::get(rewriter.getContext()),
        paletteName);

    // Set universal background
    auto ubConst = LLVM::ConstantOp::create(rewriter, loc, rewriter.getI8Type(),
                                            op.getUbc());

    LLVM::StoreOp storeOp;
    // Set the 4 background palettes (3 colors each)
    auto storePaletteVals = [&](llvm::ArrayRef<int8_t> array, int pos) {
      auto elementAddr = LLVM::GEPOp::create(
          rewriter, loc, LLVM::LLVMPointerType::get(rewriter.getContext()),
          rewriter.getI8Type(), addr, ArrayRef<LLVM::GEPArg>{pos});
      storeOp = LLVM::StoreOp::create(rewriter, loc, ubConst, elementAddr, 1);
      for (auto [idx, val] : llvm::enumerate(array)) {
        elementAddr = LLVM::GEPOp::create(
            rewriter, loc, LLVM::LLVMPointerType::get(rewriter.getContext()),
            rewriter.getI8Type(), addr, ArrayRef<LLVM::GEPArg>{pos + idx + 1});
        auto valConst =
            LLVM::ConstantOp::create(rewriter, loc, rewriter.getI8Type(), val);
        storeOp =
            LLVM::StoreOp::create(rewriter, loc, valConst, elementAddr, 1);
      }
    };

    storePaletteVals(op.getPalette0(), 0);
    storePaletteVals(op.getPalette1(), 4);
    storePaletteVals(op.getPalette2(), 8);
    storePaletteVals(op.getPalette3(), 12);

    StringRef fnName =
        (op.getPaletteType() == anes::PaletteTypeEnum::Background) ? "pal_bg"
                                                                   : "pal_spr";
    auto funcOp = LLVM::lookupOrCreateFn(
        rewriter, moduleOp, fnName,
        {LLVM::LLVMPointerType::get(rewriter.getContext())},
        LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(op, "failed to define pal_bg func");
    auto callOp = LLVM::CallOp::create(rewriter, loc, funcOp.value(), addr);
    rewriter.replaceOp(op, callOp);
    return success();
  }
};

// compute address as (nametable | (((y) << 5) | (x))). see neslib.h in
// llvm-mos-sdk project
static Value computeNameTableAddr(ConversionPatternRewriter &rewriter,
                                  Location loc, Value x, Value y,
                                  int nametable) {
  Value nametableAddrConst =
      LLVM::ConstantOp::create(rewriter, loc, rewriter.getI16Type(), nametable);

  auto fiveConst =
      LLVM::ConstantOp::create(rewriter, loc, rewriter.getI16Type(), 5);

  x = LLVM::ZExtOp::create(rewriter, loc, rewriter.getI16Type(), x);
  y = LLVM::ZExtOp::create(rewriter, loc, rewriter.getI16Type(), y);

  auto leftShiftY = LLVM::ShlOp::create(rewriter, loc, y, fiveConst);

  auto orOp = LLVM::OrOp::create(rewriter, loc, leftShiftY, x);

  nametableAddrConst =
      LLVM::OrOp::create(rewriter, loc, nametableAddrConst, orOp);

  return nametableAddrConst;
}

static FailureOr<Value>
computeNameTableAttributeAddr(ModuleOp &moduleOp,
                              ConversionPatternRewriter &rewriter, Location loc,
                              Value x, Value y) {

  auto funcOp = LLVM::lookupOrCreateFn(
      rewriter, moduleOp, "get_at_addr",
      {rewriter.getI8Type(), rewriter.getI8Type(), rewriter.getI8Type()},
      rewriter.getI16Type());
  if (failed(funcOp))
    return failure();
  auto zeroConst =
      LLVM::ConstantOp::create(rewriter, loc, rewriter.getI8Type(), 0);
  auto callOp = LLVM::CallOp::create(rewriter, loc, funcOp.value(),
                                     ValueRange{zeroConst, x, y});
  return callOp.getResult();
}

struct SetVRAMAddrForTilePosOpLowering final
    : public OpConversionPattern<anes::SetVRAMAddrForTilePosOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::SetVRAMAddrForTilePosOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    Value addr;
    if (op.getMode() == anes::NameTableTypeEnum::Tile)
      addr = computeNameTableAddr(rewriter, loc, op.getX(), op.getY(),
                                  static_cast<int>(op.getNametable()));
    else if (op.getMode() == anes::NameTableTypeEnum::Palette) {
      auto maybeAddr = computeNameTableAttributeAddr(moduleOp, rewriter, loc,
                                                     op.getX(), op.getY());
      if (failed(maybeAddr))
        return rewriter.notifyMatchFailure(
            op, "could not find or create get_at_addr func.");
      addr = maybeAddr.value();
    }

    auto funcOp = LLVM::lookupOrCreateFn(
        rewriter, moduleOp, "vram_adr", {rewriter.getI16Type()},
        LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(
          op, "could not find or create vram_adr func");
    auto callOp = LLVM::CallOp::create(rewriter, loc, funcOp.value(), addr);
    rewriter.replaceOp(op, callOp);
    return success();
  }
};

struct VRAMPutOpLowering final : public OpConversionPattern<anes::VRAMPutOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::VRAMPutOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    auto funcOp = LLVM::lookupOrCreateFn(
        rewriter, moduleOp, "vram_put", {rewriter.getI8Type()},
        LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(
          op, "could not find or create vram_put func");
    auto callOp =
        LLVM::CallOp::create(rewriter, loc, funcOp.value(), op.getValue());
    rewriter.replaceOp(op, callOp);
    return success();
  }
};

struct SetTileAtOpLowering final
    : public OpConversionPattern<anes::SetTileAtOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::SetTileAtOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    (void)anes::SetVRAMAddrForTilePosOp::create(
        rewriter, loc, op.getX(), op.getY(), anes::NameTableTypeEnum::Tile,
        anes::NameTableEnum::A);

    auto vramPutOp = anes::VRAMPutOp::create(rewriter, loc, op.getValue());
    rewriter.replaceOp(op, vramPutOp);
    return success();
  }
};

struct SetAllTilesAtOpLowering final
    : public OpConversionPattern<anes::SetAllTilesAtOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::SetAllTilesAtOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    (void)anes::SetVRAMAddrForTilePosOp::create(
        rewriter, loc, op.getX(), op.getY(), anes::NameTableTypeEnum::Tile,
        anes::NameTableEnum::A);

    auto array = op.getArray();
    auto arrayTy = cast<LLVM::LLVMArrayType>(array.getType());
    auto numTiles = arrayTy.getNumElements();

    for (auto i = 0; i < (int)numTiles; i++) {
      auto value =
          LLVM::ExtractValueOp::create(rewriter, op.getLoc(), array, i);
      (void)anes::VRAMPutOp::create(rewriter, loc, value);
    }

    rewriter.eraseOp(op);
    return success();
  }
};

struct FillTilesFromRLEAtOpLowering final
    : public OpConversionPattern<anes::FillTilesFromRLEAtOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::FillTilesFromRLEAtOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    (void)anes::SetVRAMAddrForTilePosOp::create(
        rewriter, loc, op.getX(), op.getY(), anes::NameTableTypeEnum::Tile,
        op.getNametable());
    auto funcOp = LLVM::lookupOrCreateFn(
        rewriter, moduleOp, "vram_unrle",
        LLVM::LLVMPointerType::get(rewriter.getContext()),
        LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(
          op, "could not find or create vram_unrle func");
    auto callOp =
        LLVM::CallOp::create(rewriter, loc, funcOp.value(), op.getArray());
    rewriter.replaceOp(op, callOp);
    return success();
  }
};

static Value packPalPattern(ConversionPatternRewriter &rewriter, Location loc,
                            SmallVectorImpl<int8_t> &palPattern) {
  uint8_t bitField = 0;

  for (auto [idx, val] : llvm::enumerate(palPattern))
    bitField |= (static_cast<uint8_t>(val) & 0x03) << (2 * idx);

  auto bitFieldConst =
      LLVM::ConstantOp::create(rewriter, loc, rewriter.getI8Type(), bitField);

  return bitFieldConst;
}

struct SetPalAttrAtOpLowering final
    : public OpConversionPattern<anes::SetPalAttrAtOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::SetPalAttrAtOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    (void)anes::SetVRAMAddrForTilePosOp::create(
        rewriter, loc, op.getX(), op.getY(), anes::NameTableTypeEnum::Palette,
        anes::NameTableEnum::A);

    SmallVector<int8_t> palPattern(op.getPattern());
    auto vramPutOp = anes::VRAMPutOp::create(
        rewriter, loc, packPalPattern(rewriter, loc, palPattern));
    rewriter.replaceOp(op, vramPutOp);
    return success();
  }
};

struct FillPalAttrAtOpLowering final
    : public OpConversionPattern<anes::FillPalAttrAtOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::FillPalAttrAtOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    (void)anes::SetVRAMAddrForTilePosOp::create(
        rewriter, loc, op.getX(), op.getY(), anes::NameTableTypeEnum::Palette,
        anes::NameTableEnum::A);

    auto funcOp =
        LLVM::lookupOrCreateFn(rewriter, moduleOp, "vram_fill",
                               {rewriter.getI8Type(), rewriter.getI16Type()},
                               LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(
          op, "could not find or create vram_fill func");
    SmallVector<int8_t> palPattern(op.getPattern());
    auto palPatternConst = packPalPattern(rewriter, loc, palPattern);
    auto callOp =
        LLVM::CallOp::create(rewriter, loc, funcOp.value(),
                             ValueRange{palPatternConst, op.getLength()});
    rewriter.replaceOp(op, callOp);
    return success();
  }
};

struct ScrollScreenOpLowering final
    : public ConvertOpToLLVMPattern<anes::ScrollScreenOp> {
  using ConvertOpToLLVMPattern::ConvertOpToLLVMPattern;

  LogicalResult
  matchAndRewrite(anes::ScrollScreenOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    auto funcOp = LLVM::lookupOrCreateFn(
        rewriter, moduleOp, "scroll", {getIndexType(), getIndexType()},
        LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(
          op, "could not find or create scroll func");
    auto yScreenSize =
        LLVM::ConstantOp::create(rewriter, loc, adaptor.getY().getType(), 240);
    auto yMod = LLVM::URemOp::create(rewriter, loc, adaptor.getY().getType(),
                                     adaptor.getY(), yScreenSize);
    auto callOp = LLVM::CallOp::create(rewriter, loc, funcOp.value(),
                                       ValueRange{adaptor.getX(), yMod});
    rewriter.replaceOp(op, callOp);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Sprite Graphics Related Ops
//===----------------------------------------------------------------------===//

struct GlobalMetaSpriteOpLowering final
    : public OpConversionPattern<anes::GlobalMetaSpriteOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::GlobalMetaSpriteOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto isConstant = (op.getConstant()) ? op.getConstant().value() : false;

    auto metaSpriteTy = cast<anes::MetaSpriteHandleType>(op.getResultType());
    auto numCols = metaSpriteTy.getNumCols();

    Attribute value;

    int64_t arraySize = 0;
    auto maybeValue = op.getValue();
    if (maybeValue) {
      auto elements = maybeValue.value().getElements();
      SmallVector<int8_t, 4> values;
      for (auto [idx, spriteData] : llvm::enumerate(elements)) {
        auto spriteDataAttr = cast<anes::SpriteDataAttr>(spriteData);
        if (!spriteDataAttr.getTile())
          continue;
        size_t i = idx % numCols;
        size_t j = idx / numCols;
        values.push_back(i * 8);
        values.push_back(j * 8);
        values.push_back(spriteDataAttr.getTile().value());
        values.push_back(spriteDataAttr.packBits());
      }

      // add end of metasprite token
      values.push_back(-128);

      arraySize = values.size();
      // value = rewriter.getDenseI8ArrayAttr(values);
      value = DenseElementsAttr::get(
          RankedTensorType::get({arraySize}, rewriter.getI8Type()),
          llvm::ArrayRef<int8_t>(values));
    }

    // TODO: Not sure about linkage here.
    auto arrayTy = LLVM::LLVMArrayType::get(rewriter.getI8Type(), arraySize);
    auto globalOp =
        LLVM::GlobalOp::create(rewriter, loc, arrayTy, isConstant,
                               LLVM::Linkage::Internal, op.getSymName(),
                               /*value=*/value);

    rewriter.replaceOp(op, globalOp);
    return success();
  }
};

struct GetGlobalMetaSpriteOpLowering final
    : public OpConversionPattern<anes::GetGlobalMetaSpriteOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::GetGlobalMetaSpriteOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto addrOfOp = LLVM::AddressOfOp::create(
        rewriter, loc, LLVM::LLVMPointerType::get(rewriter.getContext()),
        op.getName());

    rewriter.replaceOp(op, addrOfOp);
    return success();
  }
};

struct SetMetaSpriteAtOpLowering final
    : public OpConversionPattern<anes::SetMetaSpriteAtOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::SetMetaSpriteAtOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    auto funcOp =
        LLVM::lookupOrCreateFn(rewriter, moduleOp, "oam_meta_spr",
                               {rewriter.getI8Type(), rewriter.getI8Type(),
                                LLVM::LLVMPointerType::get(getContext())},
                               LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(
          op, "could not find or create oam_meta_spr func");

    auto callOp = LLVM::CallOp::create(
        rewriter, loc, funcOp.value(),
        ValueRange{op.getX(), op.getY(), adaptor.getMetaSprite()});

    rewriter.replaceOp(op, callOp);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// ConvertToLLVMPatternInterface implementation
//===----------------------------------------------------------------------===//

namespace {
/// Implement the interface to convert MemRef to LLVM.
struct ANESToLLVMDialectInterface : public ConvertToLLVMPatternInterface {
  ANESToLLVMDialectInterface(Dialect *dialect)
      : ConvertToLLVMPatternInterface(dialect) {}

  void loadDependentDialects(MLIRContext *context) const final {
    context->loadDialect<LLVM::LLVMDialect>();
  }

  /// Hook for derived dialect interface to provide conversion patterns
  /// and mark dialect legal for the conversion target.
  void populateConvertToLLVMConversionPatterns(
      ConversionTarget &target, LLVMTypeConverter &typeConverter,
      RewritePatternSet &patterns) const final {
    typeConverter.addConversion([&](anes::MetaSpriteHandleType type) -> Type {
      return LLVM::LLVMPointerType::get(patterns.getContext());
    });
    patterns.add<PPUOffOpLowering, PPUOnOpLowering, SetPalletteOpLowering,
                 SetVRAMAddrForTilePosOpLowering, SetPalAttrAtOpLowering,
                 FillPalAttrAtOpLowering, SetTileAtOpLowering,
                 SetAllTilesAtOpLowering, FillTilesFromRLEAtOpLowering,
                 VRAMPutOpLowering, ScrollScreenOpLowering,
                 GlobalMetaSpriteOpLowering, GetGlobalMetaSpriteOpLowering,
                 SetMetaSpriteAtOpLowering>(patterns.getContext());
    patterns.add<ScrollScreenOpLowering>(typeConverter);
  }
};
} // namespace

void mlir::anes::registerConvertANESToLLVMInterface(DialectRegistry &registry) {
  registry.addExtension(+[](MLIRContext *ctx, anes::ANESDialect *dialect) {
    dialect->addInterfaces<ANESToLLVMDialectInterface>();
  });
}
