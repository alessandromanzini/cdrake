include_guard( GLOBAL )

# _cdrk_target_configure_strict( <TARGET_NAME> [ENABLE_EXCEPTIONS] [ENABLE_RTTI] [<option>...] )
#
# Enables warnings as errors on TARGET_NAME and disables exceptions and RTTI unless enabled.
# Any other argument is added as a private compile option.
function( _cdrk_target_configure_strict TARGET_NAME )
    #
    # --- Argument parsing -----------------------------------------------
    # ENABLE_EXCEPTIONS / ENABLE_RTTI: opt-in flags, both OFF unless given.
    # PARSE_ARGV skips TARGET_NAME (index 1).
    #
    cmake_parse_arguments( PARSE_ARGV 1 ARG "ENABLE_EXCEPTIONS;ENABLE_RTTI" "" "" )
    #
    # --- Diagnostics flags --------------------------------------------
    # PRIVATE: these only affect how *this* target is compiled, not its
    # externally visible configuration, therefore they are private.
    #
    target_compile_options(
            "${TARGET_NAME}" PRIVATE
            "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/W4;/WX;/permissive-;/w14062;/w14165;/w14242;/w14254;/w14263;/w14265;/w14287;/w14296;/w14311;/w14545;/w14546;/w14547;/w14549;/w14555;/w14619;/w14640;/w14826;/w14905;/w14906;/w14928;/fp:precise;/Zc:__cplusplus;/Zc:inline;/Zc:preprocessor>"
            "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang>:-Wall;-Wextra;-Wpedantic;-Werror;-Wshadow;-Wnon-virtual-dtor;-Wold-style-cast;-Wcast-align;-Wunused;-Woverloaded-virtual;-Wconversion;-Wsign-conversion;-Wdouble-promotion;-Wformat=2;-Wno-unknown-pragmas>"
            ${ARG_UNPARSED_ARGUMENTS} )
    #
    # --- ABI-affecting flags ------------------------------------------
    # PUBLIC, CXX-only: exception/RTTI configuration is baked into any
    # exported C++20 module BMI. If a consumer target links this one but
    # was compiled with a different setting, clang/MSVC rejects the .pcm
    # with a "configuration mismatch". For this reason these are public.
    #
    if( ARG_ENABLE_EXCEPTIONS )
        #
        set( _msvc_eh_flag "/EHsc" )
        set( _gnu_exception_flag "-fexceptions" )
        set( ARG_ENABLE_EXCEPTIONS ON )
        #
    else()
        #
        set( _msvc_eh_flag "/EHs-c-" )
        set( _gnu_exception_flag "-fno-exceptions" )
        set( ARG_ENABLE_EXCEPTIONS OFF )
        #
    endif()
    #
    if( ARG_ENABLE_RTTI )
        #
        set( _msvc_rtti_flag "/GR" )
        set( _gnu_rtti_flag "-frtti" )
        set( ARG_ENABLE_RTTI ON )
        #
    else()
        #
        set( _msvc_rtti_flag "/GR-" )
        set( _gnu_rtti_flag "-fno-rtti" )
        set( ARG_ENABLE_RTTI OFF )
        #
    endif()
    #
    target_compile_options(
            "${TARGET_NAME}" PUBLIC
            "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:${_msvc_eh_flag};${_msvc_rtti_flag}>"
            "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang>:${_gnu_exception_flag};${_gnu_rtti_flag}>" )
    #
    # _HAS_EXCEPTIONS=0 must only be defined when exceptions are disabled.
    if( NOT ARG_ENABLE_EXCEPTIONS )
        target_compile_definitions( "${TARGET_NAME}" PUBLIC "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:_HAS_EXCEPTIONS=0>" )
    endif()
    #
    message( STATUS "${TARGET_NAME}: strict compilation options applied (EXCEPTIONS=${ARG_ENABLE_EXCEPTIONS}, RTTI=${ARG_ENABLE_RTTI})." )
    #
endfunction()
