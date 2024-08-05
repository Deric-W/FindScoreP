# has to run in project mode to register targets
cmake_minimum_required(VERSION 3.20)
project(
    TestListTargets
    DESCRIPTION "Test ScorePUtilities detecting all targets"
    LANGUAGES NONE
)

add_custom_target("Test1")
add_subdirectory(subdir)
add_custom_target("Test2")

include(ScorePUtilities)
find_package(ScoreP REQUIRED)   # check what happens with imported targets
_scorep_get_all_targets("${CMAKE_CURRENT_SOURCE_DIR}" allTargets)
_scorep_get_all_targets("${CMAKE_CURRENT_SOURCE_DIR}/subdir" subdirTargets)

function(_check_targets targets expected)
    list(LENGTH targets targetsLength)
    list(LENGTH expected expectedLength)
    if(NOT (targetsLength EQUAL expectedLength))
        message(FATAL_ERROR "lists ${targets} and ${expected} have different lengths")
    endif()
    foreach(target ${expected})
        list(FIND targets "${target}" found)
        if(found EQUAL -1)
            message(FATAL_ERROR "Expected target ${target} was not found in ${targets}")
        endif()
        if(NOT TARGET "${target}")
            message(FATAL_ERROR "target ${target} does not exist")
        endif()
    endforeach()
endfunction()

_check_targets("${allTargets}" "Test1;Test2;Test3;Test4")
_check_targets("${subdirTargets}" "Test3;Test4")
