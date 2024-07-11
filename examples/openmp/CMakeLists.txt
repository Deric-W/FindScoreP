cmake_minimum_required(VERSION 3.20)
project(
    "OpenMP example"
    DESCRIPTION "Example for using Score-P with a C++ application using OpenMP"
    LANGUAGES CXX
)

find_package(Boost "1.74" REQUIRED COMPONENTS "program_options")
find_package(OpenMP REQUIRED)

option(ENABLE_SCOREP "Enable Score-P instrumentation" OFF)
if(ENABLE_SCOREP)
    include(ScorePUtilities)
else()
    function(scorep_mark_instrumented)
    endfunction()
endif()

add_executable(fibonacci "fibonacci.cpp")
target_link_libraries(fibonacci PRIVATE Boost::program_options)
target_link_libraries(fibonacci PRIVATE OpenMP::OpenMP_CXX)
scorep_mark_instrumented(TARGETS fibonacci LANGS CXX ARGUMENTS "--compiler" AUTO)

if(ENABLE_SCOREP)
    scorep_required_components(scorepComponents AUTO)
    find_package(ScoreP REQUIRED COMPONENTS ${scorepComponents})
    scorep_enable()
endif()

include(CTest)
if (BUILD_TESTING)
    add_subdirectory(tests)
endif()
