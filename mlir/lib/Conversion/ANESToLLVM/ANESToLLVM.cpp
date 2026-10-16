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
#include "mlir/Conversion/LLVMCommon/TypeConverter.h"
#include "mlir/Dialect/ANES/ANES.h"
#include "mlir/Dialect/LLVMIR/FunctionCallUtils.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Pass/Pass.h"

// From llvm-mos-sdk project
// TODO: ANES Dialect and lowering should really live in that project
// If they did, then we could just include the neslib.h header here to get the
// definitions But for now we will just copy over.
#define NAMETABLE_A 0x2000

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

struct SetBGPalletteOpLowering final
    : public OpConversionPattern<anes::SetBGPalletteOp> {
  using Base::Base;

  LogicalResult
  matchAndRewrite(anes::SetBGPalletteOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const final {
    auto loc = op.getLoc();

    auto moduleOp = op->getParentOfType<ModuleOp>();
    if (!moduleOp)
      return rewriter.notifyMatchFailure(op, "Parent module not found.");

    StringRef paletteName = "palette";
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

    storePaletteVals(op.getPallete0(), 0);
    storePaletteVals(op.getPallete1(), 4);
    storePaletteVals(op.getPallete2(), 8);
    storePaletteVals(op.getPallete3(), 12);

    auto funcOp = LLVM::lookupOrCreateFn(
        rewriter, moduleOp, "pal_bg",
        {LLVM::LLVMPointerType::get(rewriter.getContext())},
        LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(op, "failed to define pal_bg func");
    auto callOp = LLVM::CallOp::create(rewriter, loc, funcOp.value(), addr);
    rewriter.replaceOp(op, callOp);
    return success();
  }
};

// compute address as (NAMETABLE_A | (((y) << 5) | (x))). see neslib.h in
// llvm-mos-sdk project
static Value computeNameTableAddr(ConversionPatternRewriter &rewriter,
                                  Location loc, Value x, Value y) {
  Value nametableAddrConst = LLVM::ConstantOp::create(
      rewriter, loc, rewriter.getI16Type(), NAMETABLE_A);

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
    if (op.getMode() == anes::NameTableEnum::Tile)
      addr = computeNameTableAddr(rewriter, loc, op.getX(), op.getY());
    else if (op.getMode() == anes::NameTableEnum::Palette) {
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
        rewriter, loc, op.getX(), op.getY(),
        anes::NameTableEnumAttr::get(rewriter.getContext(),
                                     anes::NameTableEnum::Tile));

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
        rewriter, loc, op.getX(), op.getY(),
        anes::NameTableEnumAttr::get(rewriter.getContext(),
                                     anes::NameTableEnum::Tile));

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
        rewriter, loc, op.getX(), op.getY(),
        anes::NameTableEnumAttr::get(rewriter.getContext(),
                                     anes::NameTableEnum::Tile));
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
        rewriter, loc, op.getX(), op.getY(),
        anes::NameTableEnumAttr::get(rewriter.getContext(),
                                     anes::NameTableEnum::Palette));

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
        rewriter, loc, op.getX(), op.getY(),
        anes::NameTableEnumAttr::get(rewriter.getContext(),
                                     anes::NameTableEnum::Palette));

    auto funcOp =
        LLVM::lookupOrCreateFn(rewriter, moduleOp, "vram_fill",
                               {rewriter.getI8Type(), rewriter.getI16Type()},
                               LLVM::LLVMVoidType::get(rewriter.getContext()));
    if (failed(funcOp))
      return rewriter.notifyMatchFailure(
          op, "could not find or create vram_put func");
    SmallVector<int8_t> palPattern(op.getPattern());
    auto palPatternConst = packPalPattern(rewriter, loc, palPattern);
    auto callOp =
        LLVM::CallOp::create(rewriter, loc, funcOp.value(),
                             ValueRange{palPatternConst, op.getLength()});
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
    patterns.add<PPUOffOpLowering, PPUOnOpLowering, SetBGPalletteOpLowering,
                 SetVRAMAddrForTilePosOpLowering, SetPalAttrAtOpLowering,
                 FillPalAttrAtOpLowering, SetTileAtOpLowering,
                 SetAllTilesAtOpLowering, FillTilesFromRLEAtOpLowering,
                 VRAMPutOpLowering>(patterns.getContext());
  }
};
} // namespace

void mlir::anes::registerConvertANESToLLVMInterface(DialectRegistry &registry) {
  registry.addExtension(+[](MLIRContext *ctx, anes::ANESDialect *dialect) {
    dialect->addInterfaces<ANESToLLVMDialectInterface>();
  });
}
