# Credits to Jakub Fratczak, from whom I got the original code.
# https://github.com/Froncu/Eruptor/blob/master/cmake/scripts/eruptor_module.cmake

include_guard( GLOBAL )

include( "${CMAKE_CURRENT_LIST_DIR}/../private/target_configure_strict.cmake" )
include( "${CMAKE_CURRENT_LIST_DIR}/../private/add_library_target.cmake" )

function( cdrk_module MODULE_NAME MODULE_TYPE )
    #
    # 1. Parse and validate arguments.
    cmake_parse_arguments( PARSE_ARGV 2 ARG "STRICT" "INCLUDE_DIRECTORY;SOURCE_DIRECTORY" "SOURCES;STRICT_ARGS" )
    #
    if( ARG_UNPARSED_ARGUMENTS )
        #
        message( FATAL_ERROR "cdrk_module: unexpected arguments '${ARG_UNPARSED_ARGUMENTS}'!" )
        #
    endif()
    #
    if( ARG_STRICT_ARGS AND NOT ARG_STRICT )
        #
        message( FATAL_ERROR "cdrk_module: STRICT_ARGS given without STRICT!" )
        #
    endif()
    #
    if( NOT DEFINED "${PROJECT_NAME}_NAMESPACE" )
        #
        message( FATAL_ERROR "${PROJECT_NAME}_NAMESPACE is not found!" )
        #
    endif()
    #
    set( MODULE_NAMESPACE "${${PROJECT_NAME}_NAMESPACE}" )
    #
    # Default directories, unless given through args.
    if( NOT DEFINED ARG_INCLUDE_DIRECTORY )
        #
        set( ARG_INCLUDE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include" )
        #
    endif()
    #
    if( NOT DEFINED ARG_SOURCE_DIRECTORY )
        #
        set( ARG_SOURCE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/source" )
        #
    endif()
    #
    # 2. Add the module target.
    set( TARGET_NAME "${MODULE_NAMESPACE}_${MODULE_NAME}" )
    set( ALIAS_NAME "${MODULE_NAMESPACE}::${MODULE_NAME}" )
    #
    if( MODULE_TYPE STREQUAL "EXECUTABLE" )
        #
        add_executable( "${TARGET_NAME}" ${ARG_SOURCES} )
        add_executable( "${ALIAS_NAME}" ALIAS "${TARGET_NAME}" )
        set( SOURCE_TARGET "${TARGET_NAME}" )
        #
        # Windows has no rpath, so copy the runtime DLLs next to the executable ('true' if none).
        if( WIN32 )
            #
            set( RUNTIME_DLLS "$<TARGET_RUNTIME_DLLS:${TARGET_NAME}>" )
            add_custom_command( TARGET "${TARGET_NAME}" POST_BUILD
                                COMMAND "${CMAKE_COMMAND}" -E "$<IF:$<BOOL:${RUNTIME_DLLS}>,copy_if_different,true>" "${RUNTIME_DLLS}" "$<TARGET_FILE_DIR:${TARGET_NAME}>"
                                COMMAND_EXPAND_LISTS VERBATIM )
            #
        endif()
        #
    elseif( MODULE_TYPE STREQUAL "STATIC" OR MODULE_TYPE STREQUAL "SHARED" OR MODULE_TYPE STREQUAL "LIBRARY" )
        #
        _cdrk_add_library_target( ${MODULE_TYPE} "${TARGET_NAME}" "${ALIAS_NAME}" SOURCE_TARGET ${ARG_SOURCES} )
        #
    else()
        #
        message( FATAL_ERROR "Module type '${MODULE_TYPE}' is not recognized!" )
        #
    endif()
    #
    # 3. Export as <namespace>::<MODULE_NAME> instead of <namespace>::<namespace>_<MODULE_NAME>.
    set_target_properties( "${TARGET_NAME}" PROPERTIES EXPORT_NAME "${MODULE_NAME}" )
    if( MODULE_TYPE STREQUAL "LIBRARY" )
        #
        set_target_properties( "${TARGET_NAME}-static" PROPERTIES EXPORT_NAME "${MODULE_NAME}-static" )
        set_target_properties( "${TARGET_NAME}-object" PROPERTIES EXPORT_NAME "${MODULE_NAME}-object" )
        #
    endif()
    #
    # 4. Configure the target that compiles the sources and...
    target_include_directories( "${SOURCE_TARGET}"
                                PUBLIC "$<BUILD_INTERFACE:${ARG_INCLUDE_DIRECTORY}>"
                                PRIVATE "${ARG_SOURCE_DIRECTORY}" )
    #
    # ... if args ask for it, apply strict options.
    if( ARG_STRICT )
        #
        _cdrk_target_configure_strict( "${SOURCE_TARGET}" ${ARG_STRICT_ARGS} )
        #
    endif()
    #
    set( MODULE_TARGET_NAME "${TARGET_NAME}" PARENT_SCOPE )
    #
endfunction()
