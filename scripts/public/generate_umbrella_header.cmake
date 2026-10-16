include_guard( GLOBAL )

include( "${CMAKE_CURRENT_LIST_DIR}/ms_timestamp.cmake" )

# cdrk_generate_umbrella_header( UMBRELLA_HEADER_NAME <name>
#                                INCLUDE_DIRECTORY <dir>
#                                OUTPUT_DIRECTORY <dir>
#                                [EXCEPTION_REGEX <regex>...] )
#
# Writes <OUTPUT_DIRECTORY>/<name>.hpp including every .hpp under INCLUDE_DIRECTORY, sorted,
# with paths relative to it. A pch.hpp, if found, is included first.
# UMBRELLA_HEADER_NAME:  header name without extension, also used for the include guard.
# INCLUDE_DIRECTORY:     absolute path of the headers to glob.
# OUTPUT_DIRECTORY:      where the umbrella header is written.
# EXCEPTION_REGEX:       headers matching any of these are left out.
function( cdrk_generate_umbrella_header )
    #
    cdrk_ms_timestamp( T_START_MS )
    #
    #
    # ========================================
    # ARGUMENT VALIDATION
    # ========================================
    #
    cmake_parse_arguments( ARG "" "UMBRELLA_HEADER_NAME;INCLUDE_DIRECTORY;OUTPUT_DIRECTORY" "EXCEPTION_REGEX" ${ARGN} )
    #
    foreach( REQUIRED_ARG UMBRELLA_HEADER_NAME INCLUDE_DIRECTORY OUTPUT_DIRECTORY )
        #
        if( NOT ARG_${REQUIRED_ARG} )
            message( FATAL_ERROR "generate_umbrella_header: ${REQUIRED_ARG} is required!" )
        endif()
        #
    endforeach()
    #
    get_filename_component( EXTENSION "${ARG_UMBRELLA_HEADER_NAME}" EXT )
    if( NOT EXTENSION STREQUAL "" )
        #
        message( FATAL_ERROR "generate_umbrella_header: UMBRELLA_HEADER_NAME must not contain an extension (${ARG_UMBRELLA_HEADER_NAME})!" )
        #
    endif()
    #
    if( NOT IS_ABSOLUTE "${ARG_INCLUDE_DIRECTORY}" )
        #
        message( FATAL_ERROR "generate_umbrella_header: INCLUDE_DIRECTORY must be an absolute path (${ARG_INCLUDE_DIRECTORY})!" )
        #
    endif()
    #
    #
    # ========================================
    # HEADER GENERATION
    # ========================================
    #
    string( TOUPPER "${ARG_UMBRELLA_HEADER_NAME}" HEADER_GUARD )
    string( APPEND HEADER_GUARD _HPP )
    set( UMBRELLA_HEADER_FILE "${ARG_UMBRELLA_HEADER_NAME}.hpp" )
    #
    # Include guards.
    set( CONTENT "// UMBRELLA HEADER: auto-generated in cmake from globbed headers...\n\n" )
    string( APPEND CONTENT "#ifndef ${HEADER_GUARD}\n" )
    string( APPEND CONTENT "#define ${HEADER_GUARD}\n\n\n" )
    #
    # Glob, exclude umbrella, sort.
    file( GLOB_RECURSE INCLUDE_FILE_PATHS "${ARG_INCLUDE_DIRECTORY}/*.hpp" )
    list( FILTER INCLUDE_FILE_PATHS EXCLUDE REGEX "/${UMBRELLA_HEADER_FILE}$" )
    foreach( REGEX ${ARG_EXCEPTION_REGEX} )
        #
        list( FILTER INCLUDE_FILE_PATHS EXCLUDE REGEX "${REGEX}" )
        #
    endforeach()
    list( SORT INCLUDE_FILE_PATHS COMPARE NATURAL ORDER ASCENDING )
    #
    # Extract pch and ...
    set( PCH_FILE_PATHS ${INCLUDE_FILE_PATHS} )
    list( FILTER PCH_FILE_PATHS INCLUDE REGEX ".*/pch\\.hpp$" )
    #
    # ... if any was found, exclude from list and append in front.
    list( LENGTH PCH_FILE_PATHS PCH_COUNT )
    if( PCH_COUNT GREATER 0 )
        #
        list( FILTER INCLUDE_FILE_PATHS EXCLUDE REGEX ".*/pch\\.hpp$" )
        list( GET PCH_FILE_PATHS 0 PCH_FILE_PATH )
        file( RELATIVE_PATH REL_PATH "${ARG_INCLUDE_DIRECTORY}" "${PCH_FILE_PATH}" )
        string( APPEND CONTENT "#include \"${REL_PATH}\"\n\n" )
        #
    endif()
    #
    # Append remaining headers.
    foreach( INCLUDE_FILE_PATH ${INCLUDE_FILE_PATHS} )
        #
        file( RELATIVE_PATH REL_PATH "${ARG_INCLUDE_DIRECTORY}" "${INCLUDE_FILE_PATH}" )
        string( APPEND CONTENT "#include \"${REL_PATH}\"\n" )
        #
    endforeach()
    #
    string( APPEND CONTENT "\n\n#endif //!${HEADER_GUARD}\n" )
    #
    cmake_path( APPEND ARG_OUTPUT_DIRECTORY "${UMBRELLA_HEADER_FILE}" OUTPUT_VARIABLE OUTPUT_FILE_PATH )
    # Write only if changed, to avoid rebuilds on reconfigure.
    file( CONFIGURE OUTPUT "${OUTPUT_FILE_PATH}" CONTENT "${CONTENT}" @ONLY )
    #
    #
    # ========================================
    # LOG STATUS
    # ========================================
    #
    cdrk_ms_timestamp( T_END_MS )
    math( EXPR T_ELAPSED_MS "(${T_END_MS} - ${T_START_MS})" )
    message( STATUS "Generating ${UMBRELLA_HEADER_FILE} umbrella header done (${T_ELAPSED_MS}ms)" )
    message( STATUS "Umbrella header has been written to: ${OUTPUT_FILE_PATH}" )
    #
endfunction()