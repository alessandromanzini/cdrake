include_guard( GLOBAL )

# _cdrk_target_export_api( <TARGET_NAME> <EXPORT_MACRO> <STATIC|BUILD|IMPORT> )
#
# Defines EXPORT_MACRO on TARGET_NAME: empty for STATIC, symbol export while compiling
# the target for BUILD, symbol import for its consumers for IMPORT.
function( _cdrk_target_export_api TARGET_NAME EXPORT_MACRO MODE )
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
        message( FATAL_ERROR "${TARGET_NAME}: cannot define ${EXPORT_MACRO}, unsupported compiler '${CMAKE_CXX_COMPILER_ID}'!" )
        #
    endif()
    #
    # 2. Define the macro: empty for static, export while building, import for consumers.
    if( MODE STREQUAL "STATIC" )
        #
        target_compile_definitions( ${TARGET_NAME} PUBLIC "${EXPORT_MACRO}=" )
        #
    elseif( MODE STREQUAL "BUILD" )
        #
        target_compile_definitions( ${TARGET_NAME} PRIVATE "${EXPORT_MACRO}=${EXPORT_ATTRIBUTE}" )
        set_target_properties( ${TARGET_NAME} PROPERTIES
                               CXX_VISIBILITY_PRESET hidden
                               VISIBILITY_INLINES_HIDDEN ON )
        #
    elseif( MODE STREQUAL "IMPORT" )
        #
        target_compile_definitions( ${TARGET_NAME} INTERFACE "${EXPORT_MACRO}=${IMPORT_ATTRIBUTE}" )
        #
    else()
        #
        message( FATAL_ERROR "_cdrk_target_export_api: unknown mode '${MODE}'!" )
        #
    endif()
    #
endfunction()

# _cdrk_add_library_target( <STATIC|SHARED|LIBRARY> <TARGET_NAME> <ALIAS_NAME> <OUT_SOURCE_TARGET> [<source>...] )
#
# Adds the library targets and aliases, see cdrk_module. OUT_SOURCE_TARGET receives the target
# compiling the sources (the object library for LIBRARY), where compile settings belong.
function( _cdrk_add_library_target LIB_TYPE TARGET_NAME ALIAS_NAME OUT_SOURCE_TARGET )
    #
    set( SOURCE_FILES ${ARGN} )
    #
    string( TOUPPER "${TARGET_NAME}_EXPORT" EXPORT_MACRO )
    string( MAKE_C_IDENTIFIER "${EXPORT_MACRO}" EXPORT_MACRO )
    #
    if( LIB_TYPE STREQUAL "STATIC" )
        #
        # Add static library only.
        add_library( ${TARGET_NAME} STATIC ${SOURCE_FILES} )
        add_library( ${ALIAS_NAME} ALIAS ${TARGET_NAME} )
        _cdrk_target_export_api( ${TARGET_NAME} ${EXPORT_MACRO} STATIC )
        #
        set( SOURCE_TARGET ${TARGET_NAME} )
        #
    elseif( LIB_TYPE STREQUAL "SHARED" )
        #
        # Add shared library only.
        add_library( ${TARGET_NAME} SHARED ${SOURCE_FILES} )
        add_library( ${ALIAS_NAME} ALIAS ${TARGET_NAME} )
        _cdrk_target_export_api( ${TARGET_NAME} ${EXPORT_MACRO} BUILD )
        _cdrk_target_export_api( ${TARGET_NAME} ${EXPORT_MACRO} IMPORT )
        #
        set( SOURCE_TARGET ${TARGET_NAME} )
        #
    elseif( LIB_TYPE STREQUAL "LIBRARY" )
        #
        set( OBJECT_TARGET "${TARGET_NAME}-object" )
        set( STATIC_TARGET "${TARGET_NAME}-static" )
        #
        # Add the object library with the sources, PIC since it is linked into the shared one.
        add_library( ${OBJECT_TARGET} OBJECT ${SOURCE_FILES} )
        set_target_properties( ${OBJECT_TARGET} PROPERTIES POSITION_INDEPENDENT_CODE ON )
        _cdrk_target_export_api( ${OBJECT_TARGET} ${EXPORT_MACRO} BUILD )
        #
        # Add static/shared library targets and link them against object.
        add_library( ${STATIC_TARGET} STATIC )
        add_library( "${ALIAS_NAME}-static" ALIAS ${STATIC_TARGET} )
        target_link_libraries( ${STATIC_TARGET} PUBLIC ${OBJECT_TARGET} )
        set_target_properties( ${STATIC_TARGET} PROPERTIES OUTPUT_NAME ${TARGET_NAME} )
        _cdrk_target_export_api( ${STATIC_TARGET} ${EXPORT_MACRO} STATIC )
        #
        add_library( ${TARGET_NAME} SHARED )
        add_library( ${ALIAS_NAME} ALIAS ${TARGET_NAME} )
        target_link_libraries( ${TARGET_NAME} PUBLIC ${OBJECT_TARGET} )
        _cdrk_target_export_api( ${TARGET_NAME} ${EXPORT_MACRO} IMPORT )
        #
        # On Windows the static and import libraries would both be named <name>.lib.
        if( WIN32 )
            #
            set_target_properties( ${STATIC_TARGET} PROPERTIES OUTPUT_NAME "${TARGET_NAME}-static" )
            #
        endif()
        #
        set( SOURCE_TARGET ${OBJECT_TARGET} )
        #
    else()
        #
        message( FATAL_ERROR "_cdrk_add_library_target: library type '${LIB_TYPE}' is not recognized!" )
        #
    endif()
    #
    set( ${OUT_SOURCE_TARGET} ${SOURCE_TARGET} PARENT_SCOPE )
    #
endfunction()
