//===- ANESDialect.h - MLIR Dialect for ANES ----------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares the Target dialect for ANES in MLIR.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_ANES_ANES_H_
#define MLIR_DIALECT_ANES_ANES_H_

#include "mlir/Dialect/LLVMIR/LLVMTypes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/OpDefinition.h"

#include "mlir/Dialect/ANES/ANESDialect.h.inc"
#include "mlir/Dialect/ANES/ANESEnums.h.inc"

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/ANES/ANESTypes.h.inc"

#define GET_ATTRDEF_CLASSES
#include "mlir/Dialect/ANES/ANESAttributes.h.inc"

#define GET_OP_CLASSES
#include "mlir/Dialect/ANES/ANES.h.inc"

#endif // MLIR_DIALECT_ANES_ANES_H_
