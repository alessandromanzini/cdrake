function( cdrk_target_compile_options_strict TARGET_NAME )
    #
    # --- Diagnostics flags --------------------------------------------
    # PRIVATE: these only affect how *this* target is compiled, not its
    # externally visible configuration, so they must not propagate to
    # consumers. Both toolchain branches live in one call, gated per-flag
    # by COMPILE_LANG_AND_ID so mixed-language targets (e.g. ObjC++ sources
    # in the same TARGET_NAME) are never touched by C++-only warnings.
    #
    target_compile_options(
            ${TARGET_NAME} PRIVATE
            "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/W4;/WX;/permissive-;/w14062;/w14165;/w14242;/w14254;/w14263;/w14265;/w14287;/w14296;/w14311;/w14545;/w14546;/w14547;/w14549;/w14555;/w14619;/w14640;/w14826;/w14905;/w14906;/w14928;/fp:precise;/Zc:__cplusplus;/Zc:inline;/Zc:preprocessor>"
            "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang>:-Wall;-Wextra;-Wpedantic;-Werror;-Wshadow;-Wnon-virtual-dtor;-Wold-style-cast;-Wcast-align;-Wunused;-Woverloaded-virtual;-Wconversion;-Wsign-conversion;-Wdouble-promotion;-Wformat=2;-Wno-unknown-pragmas>"
            ${ARGN} )
    #
    # --- ABI-affecting flags ------------------------------------------
    # PUBLIC, CXX-only: exception/RTTI configuration is baked into any
    # exported C++20 module BMI. If a consumer target links this one but
    # was compiled with a different setting, clang/MSVC rejects the .pcm
    # with a "configuration mismatch" — so this must be a usage requirement,
    # not a private detail. Scoping to CXX keeps it off ObjC++/other
    # languages compiled into the same target.
    #
    target_compile_options(
            ${TARGET_NAME} PUBLIC
            "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/EHs-c-;/GR->"
            "$<$<COMPILE_LANG_AND_ID:CXX,GNU,Clang,AppleClang>:-fno-exceptions;-fno-rtti>" )
    target_compile_definitions( ${TARGET_NAME} PUBLIC "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:_HAS_EXCEPTIONS=0>" )
    #
    message( STATUS "${TARGET_NAME}: strict compilation options applied." )
    #
endfunction()