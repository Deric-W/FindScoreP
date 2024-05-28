# Copyright 2024 Eric Niklas Wolf
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0

include(FindPackageHandleStandardArgs)

# internal function for calling scorep-config and extracting version and prefix
function(_scorep_determine_config scorepConfigExecutable versionVar prefixVar)
    # Avoid querying the version if we've already done that this run.
    # This is an internal property inspired by the FindGit module and
    # not stored in the cache because it might change between CMake runs.
    get_property(cacheProperty GLOBAL PROPERTY _FindScorepP_Cache)
    if (cacheProperty)
        list(GET cacheProperty 0 cachedConfigExecutable)
        list(GET cacheProperty 1 version)
        list(GET cacheProperty 2 prefix)
        if (cachedConfigExecutable STREQUAL scorepConfigExecutable AND (NOT version STREQUAL "") AND (NOT prefix STREQUAL ""))
            set("${versionVar}" "${version}" PARENT_SCOPE)
            set("${prefixVar}" "${prefix}" PARENT_SCOPE)
            return()
        endif()
    endif()

    foreach(option version prefix)
        execute_process(
            COMMAND "${scorepConfigExecutable}" "--${option}"
            RESULT_VARIABLE result
            OUTPUT_VARIABLE ${option}
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if (NOT result STREQUAL "0")
            if (NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
                message(NOTICE "scorep-config failed with result ${result}")
            endif()
            return()
        endif()
    endforeach()

    set_property(
        GLOBAL
        PROPERTY _FindScorepP_Cache
        "${scorepConfigExecutable};${version};${prefix}"
    )
    set("${versionVar}" "${version}" PARENT_SCOPE)
    set("${prefixVar}" "${prefix}" PARENT_SCOPE)
endfunction()


function(_scorep_version_validator resultVariable scorepConfigPath)
    if (NOT DEFINED ${CMAKE_FIND_PACKAGE_NAME}_FIND_VERSION)
        set(${resultVariable} TRUE PARENT_SCOPE)
    else()
        execute_process(
            COMMAND "${scorepConfigPath}" --version
            RESULT_VARIABLE versionResult
            OUTPUT_VARIABLE version
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if (versionResult STREQUAL "0")
            find_package_check_version("${version}" versionValid HANDLE_VERSION_RANGE)
            set(${resultVariable} ${versionValid} PARENT_SCOPE)
        else()
            if (NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
                message(DEBUG "calling ${scorepConfigPath} failed with result ${versionResult}")
            endif()
            set(${resultVariable} FALSE PARENT_SCOPE)
        endif()
    endif()
endfunction()


if (NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
    message(CHECK_START "finding scorep-config executable")
endif()
find_program(
    SCOREP_CONFIG_EXECUTABLE
    NAMES scorep-config
    VALIDATOR _scorep_version_validator
    DOC "Score-P config exeutable"
)
mark_as_advanced(SCOREP_CONFIG_EXECUTABLE)

if (SCOREP_CONFIG_EXECUTABLE)
    if (NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
        message(CHECK_PASS "found ${SCOREP_CONFIG_EXECUTABLE}")
    endif()
    _scorep_determine_config("${SCOREP_CONFIG_EXECUTABLE}" SCOREP_VERSION_STRING __scorepPrefix)

    if (__scorepPrefix) 
        find_program(
            SCOREP_EXECUTABLE
            NAMES scorep
            PATHS "${__scorepPrefix}/bin"
            DOC "Score-P exeutable"
            NO_DEFAULT_PATH
        )
        mark_as_advanced(SCOREP_EXECUTABLE)
    endif()
    unset(__scorepPrefix)

    get_property(__findScorePRole GLOBAL PROPERTY CMAKE_ROLE)
    if (__findScorePRole STREQUAL "PROJECT")
        if (NOT TARGET ScoreP::Config)
            add_executable(ScoreP::Config IMPORTED)
            set_property(TARGET ScoreP::Config PROPERTY IMPORTED_LOCATION "${SCOREP_CONFIG_EXECUTABLE}")
        endif()
        if (SCOREP_EXECUTABLE AND NOT TARGET ScoreP::ScoreP)
            add_executable(ScoreP::ScoreP IMPORTED)
            set_property(TARGET ScoreP::ScoreP PROPERTY IMPORTED_LOCATION "${SCOREP_EXECUTABLE}")
        endif()
    endif()
    unset(__findScorePRole)
elseif(NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
    message(CHECK_FAIL "not found")
endif()

find_package_handle_standard_args(
    ScoreP
    REQUIRED_VARS SCOREP_EXECUTABLE SCOREP_CONFIG_EXECUTABLE
    VERSION_VAR SCOREP_VERSION_STRING
    HANDLE_VERSION_RANGE
)
