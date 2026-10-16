//===- ANESDialect.cpp - MLIR ANES ops implementation -----------------------===//
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

#define GET_ATTRDEF_CLASSES
#include "mlir/Dialect/ANES/ANESAttributes.cpp.inc"

#define GET_OP_CLASSES
#include "mlir/Dialect/ANES/ANES.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/ANES/ANESTypes.cpp.inc"
