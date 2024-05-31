# has to run in project mode to register targets
cmake_minimum_required(VERSION 3.20)
project(
    TestResultVariables
    DESCRIPTION "Test Score-P find-module result variables"
    LANGUAGES NONE
)

find_package(ScoreP REQUIRED)

foreach(variable SCOREP_FOUND SCOREP_EXECUTABLE SCOREP_CONFIG_EXECUTABLE SCOREP_INFO_EXECUTABLE SCOREP_VERSION_STRING)
    if (NOT DEFINED ${variable})
        message(FATAL_ERROR "variable ${variable} is not defined")
    endif()
endforeach()

foreach(target ScoreP::ScoreP ScoreP::Config ScoreP::Info)
    if (NOT TARGET ${target})
        message(FATAL_ERROR "target ${target} is not defined")
    endif()
endforeach()