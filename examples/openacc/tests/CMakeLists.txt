function(_check_lists_equal actual expected)
    list(LENGTH actual actualLength)
    list(LENGTH expected expectedLength)
    if(NOT (actualLength EQUAL expectedLength))
        message(FATAL_ERROR "lists ${actual} and ${expected} have different lengths")
    endif()
    foreach(element ${expected})
        list(FIND actual "${element}" found)
        if(found EQUAL -1)
            message(FATAL_ERROR "Expected element ${element} was not found in ${actual}")
        endif()
    endforeach()
endfunction()

get_target_property(compilerLauncherArgs fibonacci CXX_COMPILER_LAUNCHER)
list(POP_FRONT compilerLauncherArgs compilerLauncher)
get_target_property(linkerLauncherArgs fibonacci CXX_LINKER_LAUNCHER)
list(POP_FRONT linkerLauncherArgs linkerLauncher)

if(ENABLE_SCOREP)
    get_target_property(scorep ScoreP::ScoreP IMPORTED_LOCATION)

    if(NOT compilerLauncher STREQUAL scorep OR NOT linkerLauncher STREQUAL scorep)
        message(FATAL_ERROR "fibonacci target has not been configured with ${scorep} as compiler and linker launcher")
    endif()

    set(expectedComponents IO_posix COMPILER OPENACC)
    if(CMAKE_CXX_COMPILER)
        list(APPEND expectedComponents "COMPILER_CXX11_${CMAKE_CXX_COMPILER}")
    endif()
    _check_lists_equal("${compilerLauncherArgs}" "--io=posix;--compiler;--openacc")
    _check_lists_equal("${linkerLauncherArgs}" "--io=posix;--compiler;--openacc")
    _check_lists_equal("${scorepComponents}" "${expectedComponents}")

    cmake_path(GET SCOREP_EXECUTABLE PARENT_PATH scorepExecutableDir)
    find_library(
        scorepAdapter
        NAMES "libscorep_adapter_openacc_event.so"
        HINTS "${scorepExecutableDir}/../lib"
        DOC "Score-P OpenACC adapter library"
        REQUIRED
    )

    add_test(
        NAME "Check that Score-P results are generated"
        COMMAND "${CMAKE_COMMAND}"
        "-DFIBONACCI_EXECUTABLE=$<TARGET_FILE:fibonacci>"
        -P "${CMAKE_CURRENT_LIST_DIR}/check_results.cmake"
    )
    set_property(TEST "Check that Score-P results are generated" PROPERTY ENVIRONMENT "ACC_PROFLIB=${scorepAdapter}" "SCOREP_OPENACC_ENABLE=yes")
else()
    if(NOT compilerLauncher STREQUAL "compilerLauncherArgs-NOTFOUND" OR NOT linkerLauncher STREQUAL "linkerLauncherArgs-NOTFOUND")
        message(FATAL_ERROR "fibonacci target has been configured with ${compilerLauncher} as compiler and ${linkerLauncher} as linker launcher")
    endif()

    add_test(
        NAME "Check that Score-P results are not generated"
        COMMAND "${CMAKE_COMMAND}"
        "-DFIBONACCI_EXECUTABLE=$<TARGET_FILE:fibonacci>"
        -P "${CMAKE_CURRENT_LIST_DIR}/check_no_results.cmake"
    )
endif()
