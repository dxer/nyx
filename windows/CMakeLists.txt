cmake_minimum_required(VERSION 3.14)
project(nyx LANGUAGES CXX)

set(BINARY_NAME "nyx")

cmake_policy(SET CMP0079 NEW)

add_definitions(-DUNICODE -D_UNICODE)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}")

add_subdirectory(runner)
