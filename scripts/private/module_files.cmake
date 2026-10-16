include_guard( GLOBAL )

# _cdrk_resolve_module_files( <OUT_FILES> <BASE_DIRECTORY> [<file|glob>...] [EXCLUDE <file|glob>...] )
#
# Resolves files relative to BASE_DIRECTORY into absolute paths in OUT_FILES. Entries with
# wildcards (*, ? or [) are globbed recursively and re-globbed on build if files are added.
# Generator expressions are passed through untouched. EXCLUDE entries are removed from the result.
function( _cdrk_resolve_module_files OUT_FILES BASE_DIRECTORY )
    #
    cmake_parse_arguments( PARSE_ARGV 2 ARG "" "" "EXCLUDE" )
    #
    set( FILES "" )
    foreach( ENTRY ${ARG_UNPARSED_ARGUMENTS} )
        #
        if( ENTRY MATCHES "^\\$<" )
            #
            list( APPEND FILES "${ENTRY}" )
            continue()
            #
        endif()
        #
        cmake_path( ABSOLUTE_PATH ENTRY BASE_DIRECTORY "${BASE_DIRECTORY}" NORMALIZE )
        if( ENTRY MATCHES "[*?[]" )
            #
            file( GLOB_RECURSE GLOBBED_FILES CONFIGURE_DEPENDS "${ENTRY}" )
            if( NOT GLOBBED_FILES )
                #
                message( AUTHOR_WARNING "'${ENTRY}' matches no file." )
                #
            endif()
            list( APPEND FILES ${GLOBBED_FILES} )
            #
        else()
            #
            list( APPEND FILES "${ENTRY}" )
            #
        endif()
        #
    endforeach()
    #
    if( FILES AND ARG_EXCLUDE )
        #
        _cdrk_resolve_module_files( EXCLUDED_FILES "${BASE_DIRECTORY}" ${ARG_EXCLUDE} )
        list( REMOVE_ITEM FILES ${EXCLUDED_FILES} )
        #
    endif()
    #
    set( ${OUT_FILES} ${FILES} PARENT_SCOPE )
    #
endfunction()

# _cdrk_target_add_file_set( <TARGET_NAME> <PRIVATE|PUBLIC> <HEADERS|CXX_MODULES> <BASE_DIRECTORY> [<file>...] )
#
# Adds files to the default file set of that type, skipping the ones already in it, since
# file sets warn on duplicates and overlapping globs across calls easily produce them.
function( _cdrk_target_add_file_set TARGET_NAME SCOPE TYPE BASE_DIRECTORY )
    #
    set( FILES ${ARGN} )
    #
    if( TYPE STREQUAL "HEADERS" )
        #
        get_target_property( EXISTING_FILES "${TARGET_NAME}" HEADER_SET )
        #
    else()
        #
        get_target_property( EXISTING_FILES "${TARGET_NAME}" CXX_MODULE_SET )
        #
    endif()
    #
    if( FILES AND EXISTING_FILES )
        #
        list( REMOVE_ITEM FILES ${EXISTING_FILES} )
        #
    endif()
    #
    if( FILES )
        #
        target_sources( "${TARGET_NAME}" ${SCOPE} FILE_SET ${TYPE} BASE_DIRS "${BASE_DIRECTORY}" FILES ${FILES} )
        #
    endif()
    #
endfunction()
