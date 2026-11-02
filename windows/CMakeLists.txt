cmake_minimum_required(VERSION 3.14)
project(nyx LANGUAGES CXX)

set(BINARY_NAME "nyx")

cmake_policy(SET CMP0079 NEW)
cmake_policy(SET CMP0091 NEW)

# Compilation settings that should be applied to most targets.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_UNICODE" "UNICODE")
endfunction()

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

add_subdirectory(runner)
