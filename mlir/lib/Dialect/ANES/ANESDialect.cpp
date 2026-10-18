//===- ANESDialect.cpp - MLIR ANES ops implementation----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the ANES dialect and its operations.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/ANES/ANES.h"

using namespace mlir;
using namespace mlir::anes;

#include "mlir/Dialect/ANES/ANESDialect.cpp.inc"
#include "mlir/Dialect/ANES/ANESEnums.cpp.inc"

void anes::ANESDialect::initialize() {
  addAttributes<
#define GET_ATTRDEF_LIST
#include "mlir/Dialect/ANES/ANESAttributes.cpp.inc"
      >();
  addTypes<
#define GET_TYPEDEF_LIST
#include "mlir/Dialect/ANES/ANESTypes.cpp.inc"
      >();
  addOperations<
#define GET_OP_LIST
#include "mlir/Dialect/ANES/ANES.cpp.inc"
      >();
}

//===----------------------------------------------------------------------===//
//
// Custom Tablegen Directives
//
//===----------------------------------------------------------------------===//

void printQuadrupleList(OpAsmPrinter &p, Operation *op,
                        OperandRangeRange coordAndTiles, ArrayAttr attributes) {
  p << " [";
  p.printNewline();
  auto attrRange = attributes.getValue();
  unsigned dynamicValIdx = 0;
  llvm::interleave(
      coordAndTiles,
      [&](OperandRange coordAndTile) {
        p << "(" << coordAndTile[0] << ", " << coordAndTile[1] << ", "
          << coordAndTile[2] << ", " << attrRange[dynamicValIdx++] << ")";
      },
      [&]() {
        p << ",";
        p.printNewline();
      });
  p << "]";
}

ParseResult parseQuadrupleList(
    OpAsmParser &parser,
    SmallVectorImpl<SmallVector<OpAsmParser::UnresolvedOperand>> &coordAndTiles,
    ArrayAttr &attributes) {

  Builder &builder = parser.getBuilder();
  SmallVector<Attribute> attrStorage;

  // Parse the opening list bracket '['
  if (parser.parseLSquare())
    return failure();

  // Handle empty list case '[]'
  if (succeeded(parser.parseOptionalRSquare())) {
    attributes = builder.getArrayAttr(attrStorage);
    return success();
  }

  do {
    // Parse a single quadruple segment: '(' ssa1, ssa2, ssa3, attr ')'
    if (parser.parseLParen())
      return failure();

    SmallVector<OpAsmParser::UnresolvedOperand> currentGroup;
    OpAsmParser::UnresolvedOperand op1, op2, op3;
    Attribute elementAttr;

    if (parser.parseOperand(op1) || parser.parseComma() ||
        parser.parseOperand(op2) || parser.parseComma() ||
        parser.parseOperand(op3) || parser.parseComma() ||
        parser.parseAttribute(elementAttr) || parser.parseRParen()) {
      return failure();
    }

    currentGroup.push_back(op1);
    currentGroup.push_back(op2);
    currentGroup.push_back(op3);
    coordAndTiles.push_back(currentGroup);

    attrStorage.push_back(elementAttr);

  } while (succeeded(parser.parseOptionalComma()));

  if (parser.parseRSquare())
    return failure();

  attributes = builder.getArrayAttr(attrStorage);

  return success();
}

//===----------------------------------------------------------------------===//
//
// Operations
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// GetGlobalMetaSpriteOp
//===----------------------------------------------------------------------===//

LogicalResult
GetGlobalMetaSpriteOp::verifySymbolUses(SymbolTableCollection &symbolTable) {
  auto global = symbolTable.lookupNearestSymbolFrom<GlobalMetaSpriteOp>(
      *this, getNameAttr());
  if (!global)
    return emitOpError("'")
           << getName() << "' does not reference a valid global memref";

  Type resultType = getResult().getType();
  if (global.getResultType() != resultType)
    return emitOpError("result type ")
           << resultType << " does not match type " << global.getResultType()
           << " of the global meta-tile @" << getName();
  return success();
}

#define GET_ATTRDEF_CLASSES
#include "mlir/Dialect/ANES/ANESAttributes.cpp.inc"

#define GET_OP_CLASSES
#include "mlir/Dialect/ANES/ANES.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/ANES/ANESTypes.cpp.inc"
