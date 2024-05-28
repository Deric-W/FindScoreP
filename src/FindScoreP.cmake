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


# internal macro to handle checking for a component based on regular expressions
macro(_scorep_check_pattern component)
    set(patternFailure FALSE)
    foreach(pattern ${ARGN})
        if (NOT "${configuration}" MATCHES "${pattern}")
            set(patternFailure TRUE)
            break()
        endif()
    endforeach()
    if(NOT patternFailure)
        set("${CMAKE_FIND_PACKAGE_NAME}_${component}_FOUND" TRUE PARENT_SCOPE)
    elseif(${CMAKE_FIND_PACKAGE_NAME}_FIND_REQUIRED_${component})
        set(hasComponents FALSE)
    endif()
endmacro()

# internal function for calling scorep-info and checking whether required components exists
# sets _FOUND variables for found components in the parent scope
function(_scorep_check_components scorepInfoExecutable resultVar)
    execute_process(
        COMMAND "${scorepInfoExecutable}" "config-summary"
        RESULT_VARIABLE result
        OUTPUT_VARIABLE configuration
    )
    if (NOT result STREQUAL "0")
        if (NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
            message(NOTICE "scorep-info failed with result ${result}")
        endif()
        set("${resultVar}" FALSE PARENT_SCOPE)
        return()
    endif()
    set(hasComponents TRUE)
    foreach(component ${${CMAKE_FIND_PACKAGE_NAME}_FIND_COMPONENTS})
        if(component STREQUAL "THREAD_omp")
            _scorep_check_pattern(
                THREAD_omp
                "\n[ \t]*opari2 support:[ \t]*yes"
                "\n[ \t]*OpenMP ancestry:[ \t]*yes"
            )
        elseif(component STREQUAL "THREAD_pthread")
            _scorep_check_pattern(THREAD_pthread "\n[ \t]*Pthread support:[ \t]*yes")
        elseif(component STREQUAL "MPP_mpi")
            _scorep_check_pattern(MPP_mpi "\n[ \t]*Score-P \\(MPI backend\\):")
        elseif(component STREQUAL "MPP_shmem")
            _scorep_check_pattern(MPP_shmem "\n[ \t]*Score-P \\(SHMEM backend\\):")
        elseif(component STREQUAL "IO_posix")
            _scorep_check_pattern(IO_posix "\n[ \t]*POSIX I/O support:[ \t]*yes")
        elseif(component STREQUAL "COMPILER")
            _scorep_check_pattern(COMPILER "\n[ \t]*Compiler instrumentation:[ \t]*yes")
        elseif(component STREQUAL "CUDA")
            _scorep_check_pattern(CUDA "\n[ \t]*CUDA support:[ \t]*yes")
        elseif(component STREQUAL "POMP")
            # TODO
        elseif(component MATCHES "^OMP_(C|CXX|Fortran)$")
            set(component "OMP_${CMAKE_MATCH_1}")
            if (CMAKE_MATCH_1 STREQUAL "CXX")
                set(language "C\\+\\+")
            else()
                set(language ${CMAKE_MATCH_1})
            endif()
            if (configuration MATCHES "\n([ \t]*)OpenMP support:[ \t]*yes")
                set(indent "${CMAKE_MATCH_1}")
                if (configuration MATCHES "\n${indent}OpenMP support:[ \t]*yes(\n${indent}[ \t]+[^\n]*)*\n${indent}[ \t]+${language} support:[ \t]*yes")
                    set("${CMAKE_FIND_PACKAGE_NAME}_${component}_FOUND" TRUE PARENT_SCOPE)
                    continue()
                endif()
            endif()
            if (${CMAKE_FIND_PACKAGE_NAME}_FIND_REQUIRED_${component})
                set(hasComponents FALSE)
            endif()
        elseif(component STREQUAL "PDT")
            _scorep_check_pattern(PDT "\n[ \t]*PDT support:[ \t]*yes")
        elseif(component STREQUAL "OPENCL")
            _scorep_check_pattern(OPENCL "\n[ \t]*OpenCL support:[ \t]*yes")
        elseif(component STREQUAL "OPENACC")
            _scorep_check_pattern(OPENACC "\n[ \t]*OpenACC support:[ \t]*yes")
        elseif(component STREQUAL "MEMORY")
            _scorep_check_pattern(MEMORY "\n[ \t]*Memory tracking support:[ \t]*yes")
        elseif(component STREQUAL "LIBWRAP")
            _scorep_check_pattern(LIBWRAP "\n[ \t]*Library wrapper support:[ \t]*yes")
        elseif(${CMAKE_FIND_PACKAGE_NAME}_FIND_REQUIRED_${component})
            # handle unknown components
            set(hasComponents FALSE)
        endif()
    endforeach()
    set("${resultVar}" ${hasComponents} PARENT_SCOPE)
endfunction()


function(_scorep_version_validator resultVariable scorepConfigPath)
    if (NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
        message(DEBUG "considering scorep-config in ${scorepConfigPath}...")
    endif()
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
            if (versionValid)
                _scorep_determine_config("${scorepConfigPath}" version prefix)
                if(prefix)
                    unset(scorepInfoExecutable)
                    find_program(
                        scorepInfoExecutable
                        NAMES scorep-info
                        PATHS "${prefix}/bin"
                        NO_DEFAULT_PATH
                        NO_CACHE
                    )
                    if(scorepInfoExecutable)
                        _scorep_check_components("${scorepInfoExecutable}" hasComponents)
                        if(hasComponents)
                            set(${resultVariable} TRUE PARENT_SCOPE)
                            return()
                        endif()
                    endif()
                endif()
            endif()
            set(${resultVariable} FALSE PARENT_SCOPE)
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
            DOC "Score-P executable"
            NO_DEFAULT_PATH
        )
        mark_as_advanced(SCOREP_EXECUTABLE)
        find_program(
            SCOREP_INFO_EXECUTABLE
            NAMES scorep-info
            PATHS "${__scorepPrefix}/bin"
            DOC "Score-P info executable"
        )
        mark_as_advanced(SCOREP_INFO_EXECUTABLE)
    endif()
    unset(__scorepPrefix)
elseif(NOT ${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
    message(CHECK_FAIL "not found")
endif()

if (SCOREP_INFO_EXECUTABLE)
    # set components for find_package_handle_standard_args
    _scorep_check_components("${SCOREP_INFO_EXECUTABLE}" __hasComponents)
    unset(__hasComponents)
endif()

get_property(__findScorePRole GLOBAL PROPERTY CMAKE_ROLE)
if (__findScorePRole STREQUAL "PROJECT")
    if (SCOREP_CONFIG_EXECUTABLE AND NOT TARGET ScoreP::Config)
        add_executable(ScoreP::Config IMPORTED)
        set_property(TARGET ScoreP::Config PROPERTY IMPORTED_LOCATION "${SCOREP_CONFIG_EXECUTABLE}")
    endif()
    if (SCOREP_EXECUTABLE AND NOT TARGET ScoreP::ScoreP)
        add_executable(ScoreP::ScoreP IMPORTED)
        set_property(TARGET ScoreP::ScoreP PROPERTY IMPORTED_LOCATION "${SCOREP_EXECUTABLE}")
    endif()
    if (SCOREP_INFO_EXECUTABLE AND NOT TARGET Scorep::Info)
        add_executable(ScoreP::Info IMPORTED)
        set_property(TARGET ScoreP::Info PROPERTY IMPORTED_LOCATION "${SCOREP_INFO_EXECUTABLE}")
    endif()
endif()
unset(__findScorePRole)

find_package_handle_standard_args(
    ScoreP
    REQUIRED_VARS SCOREP_EXECUTABLE SCOREP_CONFIG_EXECUTABLE SCOREP_INFO_EXECUTABLE
    VERSION_VAR SCOREP_VERSION_STRING
    HANDLE_VERSION_RANGE
    HANDLE_COMPONENTS
)
