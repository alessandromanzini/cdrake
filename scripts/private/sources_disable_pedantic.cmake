include_guard( GLOBAL )

function( _cdrk_sources_disable_pedantic )
    #
    set( SOURCES ${ARGN} )
    #
    # MSVC has no pedantic warnings.
    set_source_files_properties( ${SOURCES} PROPERTIES
                                 SKIP_PRECOMPILE_HEADERS ON
                                 COMPILE_OPTIONS "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang>:-Wno-pedantic>" )
    #
endfunction()
