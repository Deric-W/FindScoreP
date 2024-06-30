cmake_minimum_required(VERSION 3.20)
project(
    "Kokkos example"
    DESCRIPTION "Example for using Score-P with a C++ application using Kokkos"
    LANGUAGES CXX
)

include(ScorePUtilities)
find_package(Boost "1.74" REQUIRED COMPONENTS "program_options")
find_package(Kokkos REQUIRED)

add_executable(fibonacci "fibonacci.cpp")
target_link_libraries(fibonacci PRIVATE Boost::program_options)
target_link_libraries(fibonacci PRIVATE Kokkos::kokkos)
scorep_mark_instrumented(TARGETS fibonacci LANGS CXX ARGUMENTS "--compiler" AUTO)

option(ENABLE_SCOREP "Enable Score-P instrumentation" OFF)
if(ENABLE_SCOREP)
    scorep_required_components(scorepComponents)
    find_package(ScoreP REQUIRED COMPONENTS ${scorepComponents})
    scorep_enable()
endif()

include(CTest)
if (BUILD_TESTING)
    add_subdirectory(tests)
endif()