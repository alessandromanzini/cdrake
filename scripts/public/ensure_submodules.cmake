include_guard( GLOBAL )

include( "${CMAKE_CURRENT_LIST_DIR}/ms_timestamp.cmake" )

function( cdrk_ensure_submodules )
    #
    find_package( Git REQUIRED )
    set( CMD_WORK_DIR ${CMAKE_CURRENT_SOURCE_DIR} )
    #
    # 0. Set a lock for parallel executions (.git may be a file, so ask git where it is).
    execute_process(
            COMMAND ${GIT_EXECUTABLE} rev-parse --path-format=absolute --git-common-dir
            WORKING_DIRECTORY ${CMD_WORK_DIR}
            OUTPUT_VARIABLE GIT_COMMON_DIR
            OUTPUT_STRIP_TRAILING_WHITESPACE
            COMMAND_ERROR_IS_FATAL ANY )
    file( LOCK "${GIT_COMMON_DIR}/cmake_submodule.lock" GUARD FUNCTION )
    #
    # 1. Fetch submodules status.
    execute_process(
            COMMAND ${GIT_EXECUTABLE} submodule status
            WORKING_DIRECTORY ${CMD_WORK_DIR}
            OUTPUT_VARIABLE SUBMODULE_STATUS
            OUTPUT_STRIP_TRAILING_WHITESPACE )
    #
    # 2. Check if any submodule are not initialized (one per line).
    if( SUBMODULE_STATUS MATCHES "(^|\n)-" )
        #
        # If not, initialize them recursively on the current source dir and...
        message( STATUS "Uninitialized submodules detected, initializing..." )
        #
        cdrk_ms_timestamp( T_START_MS )
        #
        execute_process(
                COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
                WORKING_DIRECTORY ${CMD_WORK_DIR}
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
    if( SUBMODULE_STATUS MATCHES "(^|\n)\\+" )
        #
        message( WARNING "Some submodules are out of sync. Consider running: git submodule update --recursive ..." )
        #
    endif()
    #
endfunction()
