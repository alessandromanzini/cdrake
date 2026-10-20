include_guard( GLOBAL )

# _cdrk_inject_target_api( <TARGET_NAME> <API_MACRO> <STATIC|BUILD|IMPORT> )
#
# Defines API_MACRO on TARGET_NAME: empty for STATIC, symbol export while compiling
# the target for BUILD, symbol import for its consumers for IMPORT.
#
# This also sets hidden symbol visibility by default for cross-platform uniformity.
function( _cdrk_inject_target_api TARGET_NAME API_MACRO MODE )
    #
    # 1. Pick the export/import attributes for the current platform.
    if( WIN32 OR CYGWIN )
        #
        set( EXPORT_ATTRIBUTE "__declspec(dllexport)" )
        set( IMPORT_ATTRIBUTE "__declspec(dllimport)" )
        #
    elseif( CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang|AppleClang|IntelLLVM)$" )
        #
        set( EXPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))" )
        set( IMPORT_ATTRIBUTE "${EXPORT_ATTRIBUTE}" )
        #
    else()
        #
        message( FATAL_ERROR "${TARGET_NAME}: cannot define ${API_MACRO}, unsupported compiler '${CMAKE_CXX_COMPILER_ID}'!" )
        #
    endif()
    #
    # 2. Define the macro: empty for static, export while building, import for consumers.
    if( MODE STREQUAL "STATIC" )
        #
        target_compile_definitions( "${TARGET_NAME}" PUBLIC "${API_MACRO}=" )
        #
    elseif( MODE STREQUAL "BUILD" )
        #
        target_compile_definitions( "${TARGET_NAME}" PRIVATE "${API_MACRO}=${EXPORT_ATTRIBUTE}" )
        set_target_properties( "${TARGET_NAME}" PROPERTIES
                               CXX_VISIBILITY_PRESET hidden
                               VISIBILITY_INLINES_HIDDEN ON )
        #
    elseif( MODE STREQUAL "IMPORT" )
        #
        target_compile_definitions( "${TARGET_NAME}" INTERFACE "${API_MACRO}=${IMPORT_ATTRIBUTE}" )
        #
    else()
        #
        message( FATAL_ERROR "_cdrk_inject_target_api: unknown mode '${MODE}'!" )
        #
    endif()
    #
endfunction()

# _cdrk_add_library_target( <STATIC|SHARED|LIBRARY> <TARGET_NAME> <MACRO_TAG> <OUT_SOURCE_TARGET> <OUT_LINK_TARGETS> )
#
# Adds the library targets, see cdrk_module. OUT_SOURCE_TARGET receives the target compiling
# the sources (the object library for LIBRARY), OUT_LINK_TARGETS the targets to link against.
#
# The export macro is injected in the target with the following format: <MACRO_TAG>_API
function( _cdrk_add_library_target LIB_TYPE MACRO_TAG TARGET_NAME OUT_SOURCE_TARGET OUT_LINK_TARGETS )
    #
    string( TOUPPER "${MACRO_TAG}_API" API_MACRO )
    string( MAKE_C_IDENTIFIER "${API_MACRO}" API_MACRO )
    #
    if( LIB_TYPE STREQUAL "STATIC" )
        #
        add_library( "${TARGET_NAME}" STATIC )
        _cdrk_inject_target_api( "${TARGET_NAME}" "${API_MACRO}" STATIC )
        #
        set( SOURCE_TARGET "${TARGET_NAME}" )
        set( LINK_TARGETS "${TARGET_NAME}" )
        #
    elseif( LIB_TYPE STREQUAL "SHARED" )
        #
        add_library( "${TARGET_NAME}" SHARED )
        _cdrk_inject_target_api( "${TARGET_NAME}" "${API_MACRO}" BUILD )
        _cdrk_inject_target_api( "${TARGET_NAME}" "${API_MACRO}" IMPORT )
        #
        set( SOURCE_TARGET "${TARGET_NAME}" )
        set( LINK_TARGETS "${TARGET_NAME}" )
        #
    elseif( LIB_TYPE STREQUAL "LIBRARY" )
        #
        set( OBJECT_TARGET "${TARGET_NAME}-object" )
        set( STATIC_TARGET "${TARGET_NAME}-static" )
        #
        # The object library compiles the sources once for both the static and shared libraries,
        # so users can link to either without building twice. PIC is needed by the shared one.
        add_library( "${OBJECT_TARGET}" OBJECT )
        set_target_properties( "${OBJECT_TARGET}" PROPERTIES POSITION_INDEPENDENT_CODE ON )
        _cdrk_inject_target_api( "${OBJECT_TARGET}" "${API_MACRO}" BUILD )
        #
        # Add static/shared library targets and link them against object.
        add_library( "${STATIC_TARGET}" STATIC )
        target_link_libraries( "${STATIC_TARGET}" PUBLIC "${OBJECT_TARGET}" )
        _cdrk_inject_target_api( "${STATIC_TARGET}" "${API_MACRO}" STATIC )
        #
        add_library( "${TARGET_NAME}" SHARED )
        target_link_libraries( "${TARGET_NAME}" PUBLIC "${OBJECT_TARGET}" )
        _cdrk_inject_target_api( "${TARGET_NAME}" "${API_MACRO}" IMPORT )
        #
        # Both share the output name, except on Windows where the static and import libraries would clash as <name>.lib.
        if( NOT WIN32 )
            #
            set_target_properties( "${STATIC_TARGET}" PROPERTIES OUTPUT_NAME "${TARGET_NAME}" )
            #
        endif()
        #
        set( SOURCE_TARGET "${OBJECT_TARGET}" )
        set( LINK_TARGETS "${TARGET_NAME}" "${STATIC_TARGET}" )
        #
    else()
        #
        message( FATAL_ERROR "_cdrk_add_library_target: library type '${LIB_TYPE}' is not recognized!" )
        #
    endif()
    #
    set( ${OUT_SOURCE_TARGET} "${SOURCE_TARGET}" PARENT_SCOPE )
    set( ${OUT_LINK_TARGETS} ${LINK_TARGETS} PARENT_SCOPE )
    #
endfunction()
