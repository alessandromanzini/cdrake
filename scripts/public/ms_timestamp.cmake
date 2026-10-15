include_guard( GLOBAL )

function( cdrk_ms_timestamp OUTPUT_TIMESTAMP )
    #
    # Seconds followed by microseconds, in a single call so they come from the same instant.
    string( TIMESTAMP TIMESTAMP_US "%s%f" UTC )
    math( EXPR TIMESTAMP_MS "${TIMESTAMP_US} / 1000" )
    #
    set( ${OUTPUT_TIMESTAMP} ${TIMESTAMP_MS} PARENT_SCOPE )
    #
endfunction()
