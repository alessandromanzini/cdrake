include_guard( GLOBAL )

# _cdrk_check_for_updates()
#
# Warns if the latest CDrake on GitHub is newer than the loaded one. The remote version is
# fetched at most once a day and cached. Disabled by setting CDRK_CHECK_FOR_UPDATES to OFF.
function( _cdrk_check_for_updates )
    #
    if( NOT CDRK_CHECK_FOR_UPDATES )
        #
        return()
        #
    endif()
    #
    # 1. Fetch the latest version from GitHub, at most once a day.
    string( TIMESTAMP NOW "%s" UTC )
    if( DEFINED CACHE{_CDRK_LAST_UPDATE_CHECK} )
        #
        math( EXPR ELAPSED "${NOW} - $CACHE{_CDRK_LAST_UPDATE_CHECK}" )
        #
    endif()
    #
    if( NOT DEFINED ELAPSED OR ELAPSED GREATER_EQUAL 86400 )
        #
        # Store the time first, so being offline does not slow down every configure.
        set( _CDRK_LAST_UPDATE_CHECK "${NOW}" CACHE INTERNAL "" )
        #
        set( REMOTE_CONFIG_FILE "${CMAKE_BINARY_DIR}/_cdrk/CDrakeConfig.cmake" )
        file( DOWNLOAD "https://raw.githubusercontent.com/${CDRK_REPOSITORY}/main/CDrakeConfig.cmake" "${REMOTE_CONFIG_FILE}"
              TIMEOUT 5
              TLS_VERIFY ON
              STATUS DOWNLOAD_STATUS )
        #
        list( GET DOWNLOAD_STATUS 0 DOWNLOAD_CODE )
        if( NOT DOWNLOAD_CODE EQUAL 0 )
            #
            message( STATUS "CDrake update check failed, skipping." )
            return()
            #
        endif()
        #
        # Parse the version from the remote config file and...
        file( READ "${REMOTE_CONFIG_FILE}" REMOTE_CONFIG )
        set( LATEST_VERSION "" )
        foreach( PART MAJOR MINOR PATCH )
            #
            if( NOT REMOTE_CONFIG MATCHES "set\\( CDRK_VERSION_${PART} ([0-9]+) \\)" )
                #
                message( STATUS "CDrake update check could not read the remote version, skipping." )
                return()
                #
            endif()
            list( APPEND LATEST_VERSION "${CMAKE_MATCH_1}" )
            #
        endforeach()
        #
        # ... cache it, so it is reported until updated.
        list( JOIN LATEST_VERSION "." LATEST_VERSION )
        set( _CDRK_LATEST_VERSION "${LATEST_VERSION}" CACHE INTERNAL "" )
        #
    endif()
    #
    # 2. Compare with the loaded version.
    if( DEFINED CACHE{_CDRK_LATEST_VERSION} AND CDRK_VERSION VERSION_LESS "$CACHE{_CDRK_LATEST_VERSION}" )
        #
        if( CDRK_SINGLE_FILE )
            #
            set( UPDATE_HINT "download https://raw.githubusercontent.com/${CDRK_REPOSITORY}/main/single_file/cdrake.cmake" )
            #
        else()
            #
            set( UPDATE_HINT "pull the latest https://github.com/${CDRK_REPOSITORY}" )
            #
        endif()
        #
        message( WARNING "CDrake v$CACHE{_CDRK_LATEST_VERSION} is available (loaded v${CDRK_VERSION}), ${UPDATE_HINT}. Set CDRK_CHECK_FOR_UPDATES to OFF to disable this check." )
        #
    endif()
    #
endfunction()
