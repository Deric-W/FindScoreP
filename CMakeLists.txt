cmake_minimum_required(VERSION 3.20)
project(
    FindScoreP
    VERSION 0.2.0
    DESCRIPTION "CMake find module for Score-P"
    HOMEPAGE_URL "https://github.com/Deric-W/FindScoreP"
    LANGUAGES NONE
)

include(CTest)
if (BUILD_TESTING)
    add_subdirectory(tests)
endif()