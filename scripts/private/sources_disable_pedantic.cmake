include_guard( GLOBAL )

# _cdrk_sources_disable_pedantic( <TARGET_NAME> [<source>...] )
#
# Disables pedantic warnings and precompiled headers on the given sources of TARGET_NAME,
# visible from the target's directory even if called from another one.
function( _cdrk_sources_disable_pedantic TARGET_NAME )
    #
    set( SOURCES ${ARGN} )
    #
    # MSVC has no pedantic warnings.
    set_source_files_properties( ${SOURCES} TARGET_DIRECTORY "${TARGET_NAME}" PROPERTIES
                                 SKIP_PRECOMPILE_HEADERS ON
                                 COMPILE_OPTIONS "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang>:-Wno-pedantic>;$<$<COMPILE_LANG_AND_ID:OBJCXX,Clang,AppleClang>:-Wno-pedantic>" )
    #
endfunction()
