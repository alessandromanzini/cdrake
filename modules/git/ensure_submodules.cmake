include( "${CDRAKE_MODULES_DIR}/shell/ms_timestamp.cmake" )

function( cdrk_ensure_submodules )
    #
    # 0. Set a lock for parallel executions.
    file( LOCK "${CMAKE_SOURCE_DIR}/.git/cmake_submodule.lock" GUARD FUNCTION )
    #
    find_package( Git REQUIRED )
    set( CMD_WORK_DIR ${CMAKE_CURRENT_SOURCE_DIR} )
    #
    # 1. Fetch submodules status.
    execute_process(
            COMMAND ${GIT_EXECUTABLE} submodule status
            WORKING_DIRECTORY ${CMD_WORK_DIR}
            OUTPUT_VARIABLE SUBMODULE_STATUS
            OUTPUT_STRIP_TRAILING_WHITESPACE )
    #
    # 2. Check if any submodule are not initialized.
    if( SUBMODULE_STATUS MATCHES "^-" )
        #
        # If not, initialize them recursively on the current source dir and...
        message( STATUS "Uninitialized submodules detected, initializing..." )
        #
        cdrk_ms_timestamp( T_START_MS )
        #
        execute_process(
                COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive --jobs 1
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                RESULT_VARIABLE GIT_RESULT )
        #
        # ... if error result, halt cmake generation.
        if( NOT GIT_RESULT EQUAL 0 )
            #
            message( FATAL_ERROR "Failed to initialize submodules." )
            #
        else()
            #
            cdrk_ms_timestamp( T_END_MS )
            math( EXPR T_ELAPSED_MS "(${T_END_MS} - ${T_START_MS})" )
            message( STATUS "Initializing submodules done (${T_ELAPSED_MS}ms)" )
            #
        endif()
        #
    endif()
    #
    # 3. Check if any submodules are out of date and alert the user.
    if( SUBMODULE_STATUS MATCHES "^\\+" )
        #
        message( WARNING "Some submodules are out of sync. Consider running: git submodule update --recursive ..." )
        #
    endif()
    #
endfunction()
