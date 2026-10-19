# Credits to Jakub Fratczak, from whom I got the original code.
# https://github.com/Froncu/Eruptor/blob/master/cmake/scripts/eruptor_module.cmake

include_guard( GLOBAL )

include( "${CMAKE_CURRENT_LIST_DIR}/../private/target_configure_strict.cmake" )
include( "${CMAKE_CURRENT_LIST_DIR}/../private/add_library_target.cmake" )

# cdrk_module( <MODULE_NAME> <EXECUTABLE|STATIC|SHARED|LIBRARY>
#              [INCLUDE_DIRECTORY <dir>]
#              [SOURCE_DIRECTORY <dir>]
#              [STRICT | STRICT_ARGS <arg>...] )
#
# Adds the target <namespace>_<MODULE_NAME> with alias <namespace>::<MODULE_NAME>, where
# <namespace> is read from ${PROJECT_NAME}_NAMESPACE. If no namespace is defined, the
# target is defined as <MODULE_NAME> with no alias.
# The complete target name is returned in <MODULE_TARGET> on the parent scope. Same goes
# for directory paths to <MODULE_INC_DIR> and <MODULE_SRC_DIR>.
# Sources can be added with cdrk_module_sources.
#
# EXECUTABLE:         an executable, runtime DLLs are copied next to it on Windows.
# STATIC/SHARED:      a single library of that type.
# LIBRARY:            both, sources compiled once; the static one is <namespace>::<MODULE_NAME>-static.
#                     Libraries define <NAMESPACE>_<MODULE_NAME>_EXPORT (upper case) to mark exported symbols.
# INCLUDE_DIRECTORY:  add directory to module target. if <MODULE_TYPE> is a library type, this is set
#                     as public directory.
# SOURCE_DIRECTORY:   add directory to module target, strictly private.
# STRICT:             applies strict compilation options with their defaults.
# STRICT_ARGS:        applies strict compilation options with these arguments
#                     (ENABLE_EXCEPTIONS, ENABLE_RTTI, extra compile options).
function( cdrk_module MODULE_NAME MODULE_TYPE )
    #
    # 1. Parse and validate arguments.
    cmake_parse_arguments( PARSE_ARGV 2 ARG "STRICT" "INCLUDE_DIRECTORY;SOURCE_DIRECTORY" "STRICT_ARGS" )
    #
    if( ARG_UNPARSED_ARGUMENTS )
        #
        message( FATAL_ERROR "cdrk_module: unexpected arguments '${ARG_UNPARSED_ARGUMENTS}'!" )
        #
    endif()
    #
    # STRICT_ARGS implies STRICT, even if left empty.
    if( DEFINED ARG_STRICT_ARGS OR "STRICT_ARGS" IN_LIST ARG_KEYWORDS_MISSING_VALUES )
        #
        set( ARG_STRICT ON )
        #
    endif()
    #
    # 2. Name the target, namespaced only if the project defines a namespace.
    if( DEFINED "${PROJECT_NAME}_NAMESPACE" )
        #
        set( TARGET_NAME "${${PROJECT_NAME}_NAMESPACE}_${MODULE_NAME}" )
        set( ALIAS_NAME "${${PROJECT_NAME}_NAMESPACE}::${MODULE_NAME}" )
        #
    else()
        #
        set( TARGET_NAME "${MODULE_NAME}" )
        set( ALIAS_NAME "" )
        #
    endif()
    #
    # 3. Add the module targets.
    if( MODULE_TYPE STREQUAL "EXECUTABLE" )
        #
        add_executable( "${TARGET_NAME}" )
        set( SOURCE_TARGET "${TARGET_NAME}" )
        set( LINK_TARGETS "${TARGET_NAME}" )
        #
        # Windows has no rpath, so copy the runtime DLLs next to the executable ('true' if none).
        if( WIN32 )
            #
            set( RUNTIME_DLLS "$<TARGET_RUNTIME_DLLS:${TARGET_NAME}>" )
            add_custom_command( TARGET "${TARGET_NAME}" POST_BUILD
                                COMMAND "${CMAKE_COMMAND}" -E "$<IF:$<BOOL:${RUNTIME_DLLS}>,copy_if_different,true>" "${RUNTIME_DLLS}" "$<TARGET_FILE_DIR:${TARGET_NAME}>"
                                COMMAND_EXPAND_LISTS VERBATIM )
            #
        endif()
        #
    elseif( MODULE_TYPE MATCHES "^(STATIC|SHARED|LIBRARY)$" )
        #
        _cdrk_add_library_target( "${MODULE_TYPE}" "${TARGET_NAME}" SOURCE_TARGET LINK_TARGETS )
        #
    else()
        #
        message( FATAL_ERROR "Module type '${MODULE_TYPE}' is not recognized!" )
        #
    endif()
    #
    # 4. Name the targets <namespace>::<MODULE_NAME>[-static|-object] for consumers, when
    #    exported (EXPORT_NAME) and, for the linkable ones, in this build (alias).
    string( LENGTH "${TARGET_NAME}" TARGET_NAME_LENGTH )
    foreach( MODULE_TARGET IN LISTS LINK_TARGETS SOURCE_TARGET )
        #
        string( SUBSTRING "${MODULE_TARGET}" "${TARGET_NAME_LENGTH}" -1 SUFFIX )
        set_target_properties( "${MODULE_TARGET}" PROPERTIES EXPORT_NAME "${MODULE_NAME}${SUFFIX}" )
        #
        if( ALIAS_NAME AND MODULE_TARGET IN_LIST LINK_TARGETS AND NOT TARGET "${ALIAS_NAME}${SUFFIX}" )
            #
            if( MODULE_TYPE STREQUAL "EXECUTABLE" )
                #
                add_executable( "${ALIAS_NAME}${SUFFIX}" ALIAS "${MODULE_TARGET}" )
                #
            else()
                #
                add_library( "${ALIAS_NAME}${SUFFIX}" ALIAS "${MODULE_TARGET}" )
                #
            endif()
            #
        endif()
        #
    endforeach()
    #
    # 5. Remember the module layout for cdrk_module_sources. Executables have no consumers,
    #    so their file sets stay private.
    if( MODULE_TYPE STREQUAL "EXECUTABLE" )
        #
        set( FILE_SET_SCOPE PRIVATE )
        #
    else()
        #
        set( FILE_SET_SCOPE PUBLIC )
        #
    endif()
    #
    # 6. Configure the target that compiles the sources and...
    target_include_directories( "${SOURCE_TARGET}"
                                "${FILE_SET_SCOPE}" "$<BUILD_INTERFACE:${ARG_INCLUDE_DIRECTORY}>"
                                PRIVATE "${ARG_SOURCE_DIRECTORY}" )
    #
    # ... if args ask for it, apply strict options.
    if( ARG_STRICT )
        #
        _cdrk_target_configure_strict( "${SOURCE_TARGET}" ${ARG_STRICT_ARGS} )
        #
    endif()
    #
    set_target_properties( "${TARGET_NAME}" PROPERTIES
                           _CDRK_SOURCE_TARGET "${SOURCE_TARGET}"
                           _CDRK_LINK_TARGETS "${LINK_TARGETS}"
                           _CDRK_FILE_SET_SCOPE "${FILE_SET_SCOPE}"
                           _CDRK_INCLUDE_DIRECTORY "${ARG_INCLUDE_DIRECTORY}"
                           _CDRK_SOURCE_DIRECTORY "${ARG_SOURCE_DIRECTORY}" )
    #
    set( MODULE_TARGET "${TARGET_NAME}" PARENT_SCOPE )
    set( MODULE_INC_DIR "${ARG_INCLUDE_DIRECTORY}" PARENT_SCOPE )
    set( MODULE_SRC_DIR "${ARG_SOURCE_DIRECTORY}" PARENT_SCOPE )
    #
endfunction()
