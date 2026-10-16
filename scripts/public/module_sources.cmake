include_guard( GLOBAL )

include( "${CMAKE_CURRENT_LIST_DIR}/../private/module_files.cmake" )
include( "${CMAKE_CURRENT_LIST_DIR}/../private/sources_disable_pedantic.cmake" )

# cdrk_module_sources( <TARGET>
#                      [SOURCES <file|glob>...]
#                      [HEADERS <file|glob>...]
#                      [MODULES <file|glob>...]
#                      [EXCLUDE <file|glob>...]
#                      [NO_PEDANTIC]
#                      [FRAMEWORKS <name>...]
#                      [IF <condition>...] )
#
# Adds files to a target made by cdrk_module, given by name or alias, from any directory.
# Files go to the target compiling the sources, so this works for every module type.
# Entries with wildcards (*, ? or [) are globbed recursively, e.g. "platform/win32/*.cpp".
# SOURCES:      private sources, relative to the module SOURCE_DIRECTORY. Objective-C++
#               sources need the OBJCXX language enabled by the project.
# HEADERS:      public headers, relative to the module INCLUDE_DIRECTORY, as a HEADERS file set.
# MODULES:      C++20 module interface units, relative to the module INCLUDE_DIRECTORY, as a
#               CXX_MODULES file set, skipping precompiled headers.
# EXCLUDE:      files left out of this call, relative to each kind's directory, e.g. "platform/*".
# NO_PEDANTIC:  disables pedantic warnings and precompiled headers on this call's files.
# FRAMEWORKS:   Apple frameworks to link, e.g. Cocoa.
# IF:           only adds anything if the condition holds, e.g. IF APPLE or IF WIN32 AND NOT MINGW.
function( cdrk_module_sources TARGET )
    #
    # 1. Parse and validate arguments.
    cmake_parse_arguments( PARSE_ARGV 1 ARG "NO_PEDANTIC" "" "SOURCES;HEADERS;MODULES;EXCLUDE;FRAMEWORKS;IF" )
    #
    if( ARG_UNPARSED_ARGUMENTS )
        #
        message( FATAL_ERROR "cdrk_module_sources: unexpected arguments '${ARG_UNPARSED_ARGUMENTS}'!" )
        #
    endif()
    #
    # Nested, as an empty condition would not parse.
    if( DEFINED ARG_IF )
        #
        if( NOT ( ${ARG_IF} ) )
            #
            return()
            #
        endif()
        #
    endif()
    #
    # 2. Read the module layout, from the real target since aliases have no custom properties.
    get_target_property( ALIASED_TARGET "${TARGET}" ALIASED_TARGET )
    if( ALIASED_TARGET )
        #
        set( TARGET "${ALIASED_TARGET}" )
        #
    endif()
    #
    foreach( PROPERTY SOURCE_TARGET LINK_TARGETS FILE_SET_SCOPE INCLUDE_DIRECTORY SOURCE_DIRECTORY )
        #
        get_target_property( ${PROPERTY} "${TARGET}" _CDRK_${PROPERTY} )
        #
    endforeach()
    #
    if( NOT SOURCE_TARGET )
        #
        message( FATAL_ERROR "cdrk_module_sources: '${TARGET}' was not created by cdrk_module!" )
        #
    endif()
    #
    # 3. Resolve files and globs.
    _cdrk_resolve_module_files( SOURCE_FILES "${SOURCE_DIRECTORY}" ${ARG_SOURCES} EXCLUDE ${ARG_EXCLUDE} )
    _cdrk_resolve_module_files( HEADER_FILES "${INCLUDE_DIRECTORY}" ${ARG_HEADERS} EXCLUDE ${ARG_EXCLUDE} )
    _cdrk_resolve_module_files( MODULE_FILES "${INCLUDE_DIRECTORY}" ${ARG_MODULES} EXCLUDE ${ARG_EXCLUDE} )
    #
    # Objective-C++ sources are silently not compiled if their language is not enabled.
    get_property( ENABLED_LANGUAGES GLOBAL PROPERTY ENABLED_LANGUAGES )
    if( SOURCE_FILES MATCHES "\\.mm(;|$)" AND NOT "OBJCXX" IN_LIST ENABLED_LANGUAGES )
        #
        message( FATAL_ERROR "${TARGET}: .mm sources need the OBJCXX language, add it to project() or call enable_language( OBJCXX )!" )
        #
    endif()
    #
    # 4. Add the files, each kind the way it needs.
    if( SOURCE_FILES )
        #
        target_sources( "${SOURCE_TARGET}" PRIVATE ${SOURCE_FILES} )
        #
    endif()
    #
    _cdrk_target_add_file_set( "${SOURCE_TARGET}" "${FILE_SET_SCOPE}" HEADERS "${INCLUDE_DIRECTORY}" ${HEADER_FILES} )
    _cdrk_target_add_file_set( "${SOURCE_TARGET}" "${FILE_SET_SCOPE}" CXX_MODULES "${INCLUDE_DIRECTORY}" ${MODULE_FILES} )
    if( MODULE_FILES )
        #
        set_source_files_properties( ${MODULE_FILES} TARGET_DIRECTORY "${SOURCE_TARGET}" PROPERTIES SKIP_PRECOMPILE_HEADERS ON )
        #
    endif()
    #
    # 5. Apply the modifiers. Frameworks go on the linked targets, as an object library has no link step.
    if( ARG_NO_PEDANTIC )
        #
        _cdrk_sources_disable_pedantic( "${SOURCE_TARGET}" ${SOURCE_FILES} ${HEADER_FILES} ${MODULE_FILES} )
        #
    endif()
    #
    foreach( FRAMEWORK ${ARG_FRAMEWORKS} )
        #
        foreach( LINK_TARGET ${LINK_TARGETS} )
            #
            target_link_libraries( "${LINK_TARGET}" PRIVATE "$<LINK_LIBRARY:FRAMEWORK,${FRAMEWORK}>" )
            #
        endforeach()
        #
    endforeach()
    #
endfunction()
