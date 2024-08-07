# has to run in project mode to register targets
cmake_minimum_required(VERSION 3.20)
project(
    TestListTargets
    DESCRIPTION "Test dependency detection"
    LANGUAGES C
)

add_library(A STATIC empty.c)
add_library(B SHARED empty.c)
add_library(C STATIC empty.c)
add_library(D STATIC empty.c)
add_library(E STATIC empty.c)
add_executable(main empty.c)

target_link_libraries(main PUBLIC A)
target_link_libraries(main PRIVATE B)
target_link_libraries(main INTERFACE C)
target_link_libraries(B PRIVATE D)
target_link_libraries(B INTERFACE E B)

include("${CMAKE_CURRENT_LIST_DIR}/../utils.cmake")
include(ScorePUtilities)

function(_test_visitor dependency variable)
    if(dependency STREQUAL "B")
        set("${variable}" FALSE PARENT_SCOPE)
    endif()
endfunction()

_scorep_determine_link_dependencies(main _scorep_all_visitor dependencies)
_check_lists_equal("${dependencies}" "A;B;E")

_scorep_determine_link_dependencies(B _scorep_all_visitor dependencies)
_check_lists_equal("${dependencies}" "D")

_scorep_determine_link_closure(main _scorep_all_visitor _scorep_all_visitor closure)
_check_lists_equal("${closure}" "A;B;D;E")

_scorep_determine_link_closure(main _test_visitor _test_visitor closure)
_check_lists_equal("${closure}" "A")

_scorep_determine_link_closure(main _scorep_not_standalone_visitor _scorep_all_visitor closure)
_check_lists_equal("${closure}" "A;E")
