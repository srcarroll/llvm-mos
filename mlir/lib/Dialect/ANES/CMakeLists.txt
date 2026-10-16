add_mlir_dialect_library(MLIRANESDialect
  ANESDialect.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/ANES

  DEPENDS
  MLIRANESIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  )
