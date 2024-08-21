cmake_minimum_required(VERSION 3.20)
project(
    "Benchmark Projekt"
    DESCRIPTION "Projekt which allows benchmarking the time required for instrumentation."
    LANGUAGES C
)

set(BENCHMARK_LOCALSETS 100 CACHE STRING "Number of local sets to generate")
set(BENCHMARK_LOCALSIZE 5 CACHE STRING "Size of the initial local sets")
set(BENCHMARK_CONNECTIONS 2 CACHE STRING "Number of connections to other local sets per local set")

include(ScorePUtilities)

if("${BENCHMARK_LOCALSETS}" GREATER 0)
    foreach(localSet RANGE 1 "${BENCHMARK_LOCALSETS}")
        add_library("LOCALSET_${localSet}" SHARED empty.c)
        if("${BENCHMARK_LOCALSIZE}" GREATER 1)
            foreach(dependency RANGE 2 "${BENCHMARK_LOCALSIZE}")
                add_library("LOCALSET_${localSet}_DEPENDENCY_${dependency}" STATIC empty.c)
                target_link_libraries("LOCALSET_${localSet}" PRIVATE "LOCALSET_${localSet}_DEPENDENCY_${dependency}")
            endforeach()
        endif()
    endforeach()

    foreach(localSet RANGE 1 "${BENCHMARK_LOCALSETS}")
        foreach(dependency RANGE 1 "${BENCHMARK_CONNECTIONS}")
            string(RANDOM LENGTH 10 ALPHABET "0123456789" other)
            math(EXPR other "${other} % (${BENCHMARK_LOCALSETS} * ${BENCHMARK_LOCALSIZE})")
            math(EXPR otherSet "(${other} / ${BENCHMARK_LOCALSIZE}) + 1")
            math(EXPR otherTarget "(${other} % ${BENCHMARK_LOCALSIZE}) + 1")
            if(${otherTarget} EQUAL 1)
                target_link_libraries("LOCALSET_${localSet}" PRIVATE "LOCALSET_${otherSet}")
            else()
                target_link_libraries("LOCALSET_${localSet}" PRIVATE "LOCALSET_${otherSet}_DEPENDENCY_${otherTarget}")
            endif()
        endforeach()
    endforeach()
endif()

string(TIMESTAMP start "%s%f")
scorep_discover_targets(allTargets)
scorep_mark(INSTRUMENT "${allTargets}" LANGS C)
scorep_determine_instrumentations("${allTargets}" COMPONENTS_VAR scorepComponents)
find_package(ScoreP REQUIRED COMPONENTS ${scorepComponents})
scorep_enable("${allTargets}")
string(TIMESTAMP end "%s%f")

math(EXPR duration "${end} - ${start}")
# to prevent target generation
message(FATAL_ERROR "Runtime in microseconds: ${duration}")
