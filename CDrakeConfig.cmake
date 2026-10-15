# CDrakeConfig.cmake
#
# ========================================
# INCLUDE GUARD
# ========================================
#
include_guard( GLOBAL )
#
#
# ========================================
# PROJECT CONFIGURATION
# ========================================
#
cmake_minimum_required( VERSION 3.29 )
#
set( CDRK_VERSION_MAJOR 1 )
set( CDRK_VERSION_MINOR 2 )
set( CDRK_VERSION_PATCH 0 )
set( CDRK_VERSION "${CDRK_VERSION_MAJOR}.${CDRK_VERSION_MINOR}.${CDRK_VERSION_PATCH}" )
#
set( CDRK_SCRIPTS_DIR "${CMAKE_CURRENT_LIST_DIR}/scripts/public" )
#
#
# ========================================
# SCRIPTS
# ========================================
#
include( "${CDRK_SCRIPTS_DIR}/ensure_submodules.cmake" )
include( "${CDRK_SCRIPTS_DIR}/generate_umbrella_header.cmake" )
include( "${CDRK_SCRIPTS_DIR}/module.cmake" )
include( "${CDRK_SCRIPTS_DIR}/ms_timestamp.cmake" )
#
message( STATUS "CDrake v${CDRK_VERSION} toolkit loaded." )
