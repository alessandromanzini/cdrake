# CDrakeConfig.cmake
#
# ========================================
# INCLUDE GUARD
# ========================================
#
if( _CDRAKE_LOADED )
    return()
endif()
set( _CDRAKE_LOADED TRUE )
#
#
# ========================================
# PROJECT CONFIGURATION
# ========================================
#
cmake_minimum_required( VERSION 3.29 )
#
set( CDRAKE_VERSION_MAJOR 1 )
set( CDRAKE_VERSION_MINOR 0 )
set( CDRAKE_VERSION_PATCH 1 )
set( CDRAKE_VERSION "${CDRAKE_VERSION_MAJOR}.${CDRAKE_VERSION_MINOR}.${CDRAKE_VERSION_PATCH}" )
#
set( CDRAKE_MODULES_DIR "${CMAKE_CURRENT_LIST_DIR}/modules" )
#
#
# ========================================
# MODULES
# ========================================
#
# build
include( "${CDRAKE_MODULES_DIR}/build/add_library_dist_targets.cmake" )
include( "${CDRAKE_MODULES_DIR}/build/sources_disable_pedantic.cmake" )
include( "${CDRAKE_MODULES_DIR}/build/target_compile_options_strict.cmake" )
#
# filegen
include( "${CDRAKE_MODULES_DIR}/filegen/generate_umbrella_header.cmake" )
#
# git
include( "${CDRAKE_MODULES_DIR}/git/ensure_submodules.cmake" )
#
# shell
include( "${CDRAKE_MODULES_DIR}/shell/ms_timestamp.cmake" )
#
message( STATUS "CDrake v${CDRAKE_VERSION} toolkit loaded." )