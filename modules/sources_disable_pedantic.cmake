function( cdrk_sources_disable_pedantic SOURCES )
    #
    set_source_files_properties( ${SOURCES} PROPERTIES
                                 SKIP_PRECOMPILE_HEADERS ON
                                 COMPILE_FLAGS "-Wno-pedantic" )
    #
endfunction()