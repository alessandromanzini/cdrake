include_guard( GLOBAL )

# cdrk_ms_timestamp( <OUTPUT_TIMESTAMP> )
#
# Stores the current time in milliseconds since epoch in OUTPUT_TIMESTAMP.
# Useful to time configure steps: take two timestamps and subtract them.
function( cdrk_ms_timestamp OUTPUT_TIMESTAMP )
    #
    # Seconds followed by microseconds, in a single call so they come from the same instant.
    string( TIMESTAMP TIMESTAMP_US "%s%f" UTC )
    math( EXPR TIMESTAMP_MS "${TIMESTAMP_US} / 1000" )
    #
    set( ${OUTPUT_TIMESTAMP} "${TIMESTAMP_MS}" PARENT_SCOPE )
    #
endfunction()
