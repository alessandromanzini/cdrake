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
set( CDRAKE_VERSION_PATCH 0 )
set( CDRAKE_VERSION "${CDRAKE_VERSION_MAJOR}.${CDRAKE_VERSION_MINOR}.${CDRAKE_VERSION_PATCH}" )
#
set( CDRAKE_MODULES_DIR "${CMAKE_CURRENT_LIST_DIR}/modules" )
list( APPEND CMAKE_MODULE_PATH "${CDRAKE_MODULES_DIR}" )
#
#
# ========================================
# MODULES
# ========================================
#
include( add_library_dist_targets )
include( generate_umbrella_header )
include( ms_timestamp )
include( sources_disable_pedantic )
include( target_compile_options_strict )
#
message( STATUS "CDrake v${CDRAKE_VERSION} toolkit loaded." )