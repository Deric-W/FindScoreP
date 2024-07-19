cmake_minimum_required(VERSION 3.20)
project(
    TestTryCompile
    DESCRIPTION "Test Score-P instrumentation during configure phase"
    LANGUAGES C
)

include(ScorePUtilities)
scorep_discover_targets(allTargets)
scorep_mark(INSTRUMENT "${allTargets}")
scorep_determine_instrumentations("${allTargets}")
find_package(ScoreP REQUIRED)
scorep_enable("${allTargets}")

try_run(
    exitCode
    compileSuccess
    SOURCES "${CMAKE_CURRENT_LIST_DIR}/hello.c"
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    NO_CACHE
)
if (NOT (compileSuccess AND exitCode STREQUAL 0))
    message(FATAL_ERROR "try_run failed, compile success: ${compileSuccess}, exit code: ${exitCode}")
endif()

file(GLOB globResults LIST_DIRECTORIES true "${CMAKE_CURRENT_BINARY_DIR}/scorep-*")
list(LENGTH globResults globEntries)
if (globEntries GREATER 0)
    message(FATAL_ERROR "try_run generated Score-P profiling results: ${globResults}")
endif()