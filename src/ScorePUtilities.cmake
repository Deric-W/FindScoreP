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


function(_scorep_list_find_regex lst regex result)
    set(index 0)
    foreach(element ${lst})
        if(element MATCHES "${regex}")
            set("${result}" ${index} PARENT_SCOPE)
            return()
        endif()
        math(EXPR index "${index} + 1")
    endforeach()
    set("${result}" -1 PARENT_SCOPE)
endfunction()

macro(_scorep_check_argument_target defined target args)
    if(${defined} AND TARGET "${target}")
        list(FIND libraries "${target}" index)
        if(NOT index EQUAL -1)
            _scorep_list_find_regex("${arguments}" "${ARGN}" index)
            if(index EQUAL -1)
                list(APPEND arguments ${args})
            endif()
        endif()
    endif()
endmacro()

function(_scorep_detect_arguments target language arguments result)
    get_target_property(libraries "${target}" LINK_LIBRARIES)
    if(libraries STREQUAL "libraries-NOTFOUND")
        set("${result}" "" PARENT_SCOPE)
        return()
    endif()

    _scorep_check_argument_target(
        "OpenMP_${language}_FOUND"
        "OpenMP::OpenMP_${language}"
        "--thread=omp"
        "^--thread="
    )
    _scorep_check_argument_target(
        "CMAKE_USE_PTHREADS_INIT"
        "Threads::Threads"
        "--thread=pthread"
        "^--thread="
    )
    _scorep_check_argument_target(
        "MPI_${language}_FOUND"
        "MPI::MPI_${language}"
        "--mpp=mpi"
        "^--mpp="
    )
    if(UNIX)
        _scorep_list_find_regex("${arguments}" "^--io=" index)
        if(index EQUAL -1)
            list(APPEND arguments "--io=posix")
        endif()
    endif()
    if(language STREQUAL CUDA)
        list(FIND arguments "--nocuda" index)
        if(index EQUAL -1)
            list(APPEND arguments "--cuda")
        endif()
    endif()
    _scorep_check_argument_target(
        "OpenMP_${language}_FOUND"
        "OpenMP::OpenMP_${language}"
        "--openmp"
        "^--noopenmp$"
    )
    _scorep_check_argument_target(
        "OpenCL_FOUND"
        "OpenCL::OpenCL"
        "--opencl"
        "^--noopencl$"
    )
    _scorep_check_argument_target(
        "OpenACC_${language}_FOUND"
        "OpenACC::OpenACC_${language}"
        "--openacc"
        "^--noopenacc$"
    )
    set("${result}" "${arguments}" PARENT_SCOPE)
endfunction()


function(scorep_instrument target)
    cmake_parse_arguments(
        ARG
        "OVERRIDE;AUTO"
        ""
        "LANGS;ARGUMENTS"
        ${ARGN}
    )

    if(NOT (DEFINED ScoreP_FOUND AND TARGET ScoreP::ScoreP))
        message(FATAL_ERROR "Score-P: called 'scorep_instrument' before finding ScoreP")
        return()
    endif()
    get_target_property(scorep ScoreP::ScoreP IMPORTED_LOCATION)
    foreach(lang ${ARG_LANGS})
        get_target_property(existingLauncher "${target}" ${lang}_COMPILER_LAUNCHER)
        if (NOT (ARG_OVERRIDE OR existingLauncher STREQUAL "existingLauncher-NOTFOUND"))
            message(
                FATAL_ERROR
                "Score-P: target ${target} has ${lang}_COMPILER_LAUNCHER already set to ${existingLauncher}"
                "Please check that the target in not already instrumented by something or unset the property."
            )
        endif()
        get_target_property(existingLauncher "${target}" ${lang}_LINKER_LAUNCHER)
        if (NOT (ARG_OVERRIDE OR existingLauncher STREQUAL "existingLauncher-NOTFOUND"))
            message(
                FATAL_ERROR
                "Score-P: target ${target} has ${lang}_LINKER_LAUNCHER already set to ${existingLauncher}"
                "Please check that the target in not already instrumented by something or unset the property."
            )
        endif()
        if(ARG_AUTO)
            _scorep_detect_arguments("${target}" "${lang}" "${ARG_ARGUMENTS}" targetLauncher)
            list(PREPEND targetLauncher "${scorep}")
        else()
            set(targetLauncher "${scorep}" ${ARG_ARGUMENTS})
        endif()
        set_target_properties("${target}" PROPERTIES ${lang}_COMPILER_LAUNCHER "${targetLauncher}")
        set_target_properties("${target}" PROPERTIES ${lang}_LINKER_LAUNCHER "${targetLauncher}")
    endforeach()
endfunction()


# Internal function listing all targets in a directory
# https://stackoverflow.com/a/62311397/9986220
function(_scorep_get_all_targets directory var)
    set(targets)
    _scorep_get_all_targets_recursive(targets "${directory}")
    set(${var} ${targets} PARENT_SCOPE)
endfunction()

macro(_scorep_get_all_targets_recursive targets dir)
    get_property(subdirectories DIRECTORY "${dir}" PROPERTY SUBDIRECTORIES)
    foreach(subdir ${subdirectories})
        _scorep_get_all_targets_recursive(${targets} "${subdir}")
    endforeach()

    get_property(current_targets DIRECTORY "${dir}" PROPERTY BUILDSYSTEM_TARGETS)
    list(APPEND ${targets} ${current_targets})
endmacro()


function(scorep_mark_instrumented)
    cmake_parse_arguments(
        ARG
        "AUTO"
        ""
        "DIRECTORIES;TARGETS;LANGS;ARGUMENTS"
        ${ARGN}
    )
    if(NOT (DEFINED ARG_DIRECTORIES OR DEFINED ARG_TARGETS))
        set(ARG_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()
    foreach(directory ${ARG_DIRECTORIES})
        _scorep_get_all_targets("${directory}" directoryTargets)
        list(APPEND ARG_TARGETS ${directoryTargets})
    endforeach()
    list(REMOVE_DUPLICATES ARG_TARGETS)

    foreach(target ${ARG_TARGETS})
        get_target_property(imported "${target}" IMPORTED)
        get_target_property(aliased "${target}" ALIASED_TARGET)
        if(imported)
            message(WARNING "imported target ${target} can not be instrumented by Score-P")
        elseif(aliased)
            message(WARNING "alias target ${target} can not be instrumented by Score-P")
        else()
            foreach(lang ${ARG_LANGS})
                if(ARG_AUTO)
                    _scorep_detect_arguments("${target}" "${lang}" "${ARG_ARGUMENTS}" arguments)
                else()
                    set(arguments "${ARG_ARGUMENTS}")
                endif()
                set_target_properties("${target}" PROPERTIES SCOREP_${lang}_ARGUMENTS "${arguments}")
            endforeach()
            set_property(TARGET "${target}" APPEND PROPERTY SCOREP_LANGUAGES ${ARG_LANGS})
        endif()
    endforeach()
endfunction()


function(_scorep_arguments2components arguments result)
    set(components "")
    foreach(argument ${arguments})
        if(argument STREQUAL "--thread=omp")
            list(APPEND components THREAD_omp)
        elseif(argument STREQUAL "--thread=pthread")
            list(APPEND components THREAD_pthread)
        elseif(argument STREQUAL "--mpp=mpi")
            list(APPEND components MPP_mpi)
        elseif(argument STREQUAL "--mmp=shmem")
            list(APPEND components MPP_shmem)
        elseif(argument STREQUAL "--io=posix")
            list(APPEND components IO_posix)
        elseif(argument STREQUAL "--compiler")
            list(APPEND components COMPILER)
        elseif(argument STREQUAL "--cuda")
            list(APPEND components CUDA)
        elseif(argument STREQUAL "--openmp")
            list(APPEND components OMP_${lang})
        elseif(argument STREQUAL "--pdt")
            list(APPEND components PDT)
        elseif(argument STREQUAL "--opencl")
            list(APPEND components OPENCL)
        elseif(argument STREQUAL "--openacc")
            list(APPEND arguments OPENACC)
        elseif(argument STREQUAL "--memory")
            list(APPEND components MEMORY)
        endif()
    endforeach()
    set("${result}" "${components}" PARENT_SCOPE)
endfunction()


function(scorep_required_components outVar)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "DIRECTORIES;TARGETS"
        ${ARGN}
    )
    if(NOT (DEFINED ARG_DIRECTORIES OR DEFINED ARG_TARGETS))
        set(ARG_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()
    foreach(directory ${ARG_DIRECTORIES})
        _scorep_get_all_targets("${directory}" directoryTargets)
        list(APPEND ARG_TARGETS ${directoryTargets})
    endforeach()
    list(REMOVE_DUPLICATES ARG_TARGETS)

    set(components "")
    foreach(target ${ARG_TARGETS})
        get_target_property(languages "${target}" SCOREP_LANGUAGES)
        if(languages STREQUAL "languages-NOTFOUND")
            continue()
        endif()
        foreach(lang ${languages})
            get_target_property(arguments "${target}" SCOREP_${lang}_ARGUMENTS)
            _scorep_arguments2components("${arguments}" languageComponents)
            list(APPEND components ${languageComponents})
        endforeach()
    endforeach()
    list(REMOVE_DUPLICATES components)
    set("${outVar}" "${components}" PARENT_SCOPE)
endfunction()


function(scorep_enable)
    cmake_parse_arguments(
        ARG
        "OVERRIDE"
        ""
        "DIRECTORIES;TARGETS"
        ${ARGN}
    )
    if(NOT (DEFINED ARG_DIRECTORIES OR DEFINED ARG_TARGETS))
        set(ARG_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}")
    endif()
    foreach(directory ${ARG_DIRECTORIES})
        _scorep_get_all_targets("${directory}" directoryTargets)
        list(APPEND ARG_TARGETS ${directoryTargets})
    endforeach()
    list(REMOVE_DUPLICATES ARG_TARGETS)

    foreach(target ${ARG_TARGETS})
        if(DEFINED "SCOREP_LANGUAGES_${target}")
            set(languages "${SCOREP_LANGUAGES_${target}}")
        else()
            get_target_property(languages "${target}" SCOREP_LANGUAGES)
            if(languages STREQUAL "languages-NOTFOUND")
                continue()
            endif()
        endif()
        foreach(lang ${languages})
            if(DEFINED "SCOREP_${lang}_ARGUMENTS_${target}")
                set(arguments "${SCOREP_${lang}_ARGUMENTS_${target}}")
            else()
                get_target_property(arguments "${target}" SCOREP_${lang}_ARGUMENTS)
            endif()
            if(ARG_OVERRIDE)
                scorep_instrument("${target}" LANGS ${lang} ARGUMENTS ${arguments} OVERRIDE)
            else()
                scorep_instrument("${target}" LANGS ${lang} ARGUMENTS ${arguments})
            endif()
        endforeach()
    endforeach()
endfunction()
