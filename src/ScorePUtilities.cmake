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

set(_SCOREP_FLAG_SETTINGS compiler cuda online-access pomp openmp pdt preprocess user opencl openacc memory kokkos)
set(_SCOREP_CHOICE_SETTINGS thread mpp mutex)
set(_SCOREP_UNION_SETTINGS io other)


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

# Internal function which determines the link dependencies of a target.
# The visitor function is called for each dependency and passed a dependency and variable name.
# By setting this variable to FALSE in the parent scope the current target will be ignored.
function(_scorep_determine_link_dependencies target visitor result)
    get_target_property(directLibraries "${target}" LINK_LIBRARIES)
    if(directLibraries STREQUAL "directLibraries-NOTFOUND")
        set(directLibraries "")
    endif()
    set(pendingLibraries "")
    set(scannedLibraries "")
    foreach(library ${directLibraries})
        set(expand TRUE)
        cmake_language(CALL "${visitor}" "${library}" expand)
        if(expand)
            list(APPEND pendingLibraries "${library}")
        endif()
    endforeach()
    while(NOT pendingLibraries STREQUAL "")
        list(POP_BACK pendingLibraries library)
        list(APPEND scannedLibraries "${library}")
        if(TARGET "${library}")
            get_target_property(indirectLibraries "${library}" INTERFACE_LINK_LIBRARIES)
            if(indirectLibraries STREQUAL "indirectLibraries-NOTFOUND")
                continue()
            endif()
            foreach(indirectLibrary ${indirectLibraries})
                set(expand TRUE)
                cmake_language(CALL "${visitor}" "${indirectLibrary}" expand)
                if(NOT expand)
                    continue()
                endif()
                list(FIND scannedLibraries "${indirectLibrary}" index)
                if(NOT index EQUAL -1)
                    continue()
                endif()
                list(FIND pendingLibraries "${indirectLibrary}" index)
                if(index EQUAL -1)
                    list(APPEND pendingLibraries "${indirectLibrary}")
                endif()
            endforeach()
        endif()
    endwhile()
    set("${result}" "${scannedLibraries}" PARENT_SCOPE)
endfunction()

# Internal function which determines all transitive link dependencies of a target.
# The visitor functions are called for each dependency and passed a dependency and variable name.
# By setting this variable to FALSE in the parent scope the current target will be ignored.
function(_scorep_determine_link_closure target indirectVisitor directVisitor result)
    _scorep_determine_link_dependencies("${target}" "${directVisitor}" directDependencies)
    set(pendingDependencies "")
    set(scannedDependencies "")
    foreach(dependency ${directDependencies})
        set(expand TRUE)
        cmake_language(CALL "${indirectVisitor}" "${dependency}" expand)
        if(expand)
            list(APPEND pendingDependencies "${dependency}")
        endif()
    endforeach()
    while(NOT pendingDependencies STREQUAL "")
        list(POP_BACK pendingDependencies dependency)
        list(APPEND scannedDependencies "${dependency}")
        if(TARGET "${dependency}")
            _scorep_determine_link_dependencies("${dependency}" "${directVisitor}" directDependencies)
            foreach(directDependency ${directDependencies})
                set(expand TRUE)
                cmake_language(CALL "${indirectVisitor}" "${directDependency}" expand)
                if(NOT expand)
                    continue()
                endif()
                list(FIND scannedDependencies "${directDependency}" index)
                if(NOT index EQUAL -1)
                    continue()
                endif()
                list(FIND pendingDependencies "${directDependency}" index)
                if(index EQUAL -1)
                    list(APPEND pendingDependencies "${directDependency}")
                endif()
            endforeach()
        endif()
    endwhile()
    set("${result}" "${scannedDependencies}" PARENT_SCOPE)
endfunction()

function(_scorep_all_visitor dependency variable)
endfunction()

function(_scorep_not_standalone_visitor dependency variable)
    if(TARGET "${dependency}")
        get_target_property(type "${dependency}" TYPE)
        if(type STREQUAL "EXECUTABLE" OR type STREQUAL "SHARED_LIBRARY" OR type STREQUAL "MODULE_LIBRARY")
            set("${variable}" FALSE PARENT_SCOPE)
        endif()
    endif()
endfunction()

# Internal function which converts a language and set CMake Variables into Score-P setting variables with a prefix.
function(_scorep_environment2settings language priority prefix)
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        set("SETTING_${setting}" "")
    endforeach()
    if(UNIX)
        set("SETTING_io" "${priority};posix")
    endif()
    if(language STREQUAL "CUDA")
        set("SETTING_cuda" "${priority};TRUE")
    elseif(language STREQUAL "HIP")
        set("SETTING_hip" "${priority};TRUE")
    endif()
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        set("${prefix}_${setting}" "${SETTING_${setting}}" PARENT_SCOPE)
    endforeach()
endfunction()

# Internal function which converts a dependency into Score-P setting variables with a prefix.
function(_scorep_link_dependency2settings dependency language priority prefix)
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        set("SETTING_${setting}" "")
    endforeach()
    if(DEFINED "OpenMP_${language}_FOUND" AND dependency STREQUAL "OpenMP::OpenMP_${language}")
        set("SETTING_thread" "${priority};omp")
    elseif(DEFINED "CMAKE_USE_PTHREADS_INIT" AND dependency STREQUAL "Threads::Threads")
        set("SETTING_thread" "${priority};pthread")
    elseif(DEFINED "MPI_${language}_FOUND" AND dependency STREQUAL "MPI::MPI_${language}")
        set("SETTING_mpp" "${priority};mpi")
    elseif(DEFINED "OpenCL_FOUND" AND dependency STREQUAL "OpenCL::OpenCL")
        set("SETTING_opencl" "${priority};TRUE")
    elseif(DEFINED "OpenACC_${language}_FOUND" AND dependency STREQUAL "OpenACC::OpenACC_${language}")
        set("SETTING_openacc" "${priority};TRUE")
    elseif(dependency STREQUAL "Kokkos::kokkos")
        set("SETTING_kokkos" "${priority};TRUE")
        if(DEFINED "Kokkos_ENABLE_OPENMP")
            set("SETTING_thread" "${priority};omp;ompt")
            set("SETTING_openmp" "${priority};FALSE")
        endif()
        if(DEFINED "Kokkos_ENABLE_CUDA")
            set("SETTING_cuda" "${priority};TRUE")
        endif()
        if(DEFINED "Kokkos_ENABLE_HIP")
            set("SETTING_hip" "${priority};TRUE")
        endif()
    endif()
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        set("${prefix}_${setting}" "${SETTING_${setting}}" PARENT_SCOPE)
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

# Internal function used to determine wether the second argument value SUPERSEDES, is SUPERSEDED or is a CONFLICT.
function(_scorep_compare_argument_values priority1 value1 variant1 priority2 value2 variant2 result)
    if(priority2 STREQUAL "" OR priority2 GREATER priority1)
        set("${result}" SUPERSEDED PARENT_SCOPE)
    elseif(priority1 STREQUAL "" OR priority1 GREATER priority2)
        set("${result}" SUPERSEDES PARENT_SCOPE)
    else()
        if(value2 STREQUAL "")
            set("${result}" SUPERSEDED PARENT_SCOPE)
        elseif(value1 STREQUAL "")
            set("${result}" SUPERSEDES PARENT_SCOPE)
        elseif(value1 STREQUAL value2)
            if(variant2 STREQUAL "")
                set("${result}" SUPERSEDED PARENT_SCOPE)
            elseif(variant1 STREQUAL "")
                set("${result}" SUPERSEDES PARENT_SCOPE)
            elseif(variant1 STREQUAL variant2)
                set("${result}" SUPERSEDED PARENT_SCOPE)
            else()
                set("${result}" CONFLICT PARENT_SCOPE)
            endif()
        else()
            set("${result}" CONFLICT PARENT_SCOPE)
        endif()
    endif()
endfunction()

# Internal function used to determine wether the second argument value SUPERSEDES, is SUPERSEDED or is a CONFLICT in cause of an existing conflict.
function(_scorep_compare_conflict_values priority1 priority2 result)
    if(priority2 STREQUAL "" OR priority2 GREATER priority1)
        set("${result}" SUPERSEDED PARENT_SCOPE)
    elseif(priority1 STREQUAL "" OR priority1 GREATER priority2)
        set("${result}" SUPERSEDES PARENT_SCOPE)
    else()
        set("${result}" CONFLICT PARENT_SCOPE)
    endif()
endfunction()

# Internal function which transforms Score-P arguments into setting variables with a prefix.
function(_scorep_arguments2settings arguments priority prefix)
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        set("SETTING_${setting}" "")
    endforeach()
    foreach(argument ${arguments})
        set(handled FALSE)
        foreach(enablearg ${_SCOREP_FLAG_SETTINGS})
            if(argument MATCHES "^--${enablearg}((:|=)(.*))?$")
                if(CMAKE_MATCH_COUNT EQUAL 0)
                    set("SETTING_${enablearg}" "${priority};TRUE")
                else()
                    set("SETTING_${enablearg}" "${priority};TRUE;${CMAKE_MATCH_2};${CMAKE_MATCH_3}")
                endif()
            elseif(argument STREQUAL "--no${enablearg}")
                set("SETTING_${enablearg}" "${priority};FALSE")
            else()
                continue()
            endif()
            set(handled TRUE)
            break()
        endforeach()
        foreach(paradigmarg ${_SCOREP_CHOICE_SETTINGS})
            if(argument MATCHES "^--${paradigmarg}=([^:]+)(:(.*))?$")
                if(CMAKE_MATCH_COUNT EQUAL 1)
                    set("SETTING_${paradigmarg}" "${priority};${CMAKE_MATCH_1}")
                else()
                    set("SETTING_${paradigmarg}" "${priority};${CMAKE_MATCH_1};${CMAKE_MATCH_3}")
                endif()
                set(handled TRUE)
                break()
            endif()
        endforeach()
        if(argument MATCHES "^--io=(.*)$")
            string(REPLACE "," ";" value "${CMAKE_MATCH_1}")
            set("SETTING_io" "${priority};${value}")
            set(handled TRUE)
        endif()
        if(NOT handled)
            if(SETTING_other STREQUAL "")
                set("SETTING_other" "${priority}")
            endif()
            list(APPEND SETTING_other "${argument}")
        endif()
    endforeach()
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        set("${prefix}_${setting}" "${SETTING_${setting}}" PARENT_SCOPE)
    endforeach()
endfunction()

# Internal function which merges the setting variables with prefix1 or prefix2 into setting variables with prefix.
function(_scorep_merge_settings prefix1 prefix2 prefix)
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        set("SETTING_${setting}" "")
    endforeach()
    foreach(enablearg ${_SCOREP_FLAG_SETTINGS})
        foreach(i 1 2)
            set(priority${i} "")
            set(value${i} "")
            set(variant${i} "")
            set(isconflict${i} FALSE)
            if(${prefix${i}}_${enablearg} MATCHES "^([0-9]+);([^;]+)(;[^;]*;(.*))?$")
                set(priority${i} "${CMAKE_MATCH_1}")
                if(CMAKE_MATCH_2)
                    set(value${i} TRUE)
                    if(CMAKE_MATCH_COUNT EQUAL 4)
                        set(variant${i} "${CMAKE_MATCH_4}")
                    endif()
                else()
                    set(value${i} FALSE)
                endif()
            elseif(${prefix${i}}_${enablearg} MATCHES "^CONFLICT;([0-9]+);")
                set(priority${i} "${CMAKE_MATCH_1}")
                set(isconflict${i} TRUE)
            endif()
        endforeach()
        if(priority1 STREQUAL "" AND priority2 STREQUAL "")
            continue()
        elseif(isconflict1 OR isconflict2)
            _scorep_compare_conflict_values("${priority1}" "${priority2}" status)
        else()
            _scorep_compare_argument_values("${priority1}" "${value1}" "${variant1}" "${priority2}" "${value2}" "${variant2}" status)
        endif()
        if(status STREQUAL "SUPERSEDES")
            set("SETTING_${enablearg}" "${${prefix2}_${enablearg}}")
        elseif(status STREQUAL "SUPERSEDED")
            set("SETTING_${enablearg}" "${${prefix1}_${enablearg}}")
        else()
            set(
                "SETTING_${enablearg}"
                "CONFLICT;${priority1};Score-P: failed to merge settings '${${prefix1}_${enablearg}}' and '${${prefix2}_${enablearg}}'"
            )
        endif()
    endforeach()
    foreach(paradigmarg ${_SCOREP_CHOICE_SETTINGS})
        foreach(i 1 2)
            set(priority${i} "")
            set(value${i} "")
            set(variant${i} "")
            set(isconflict${i} FALSE)
            if(${prefix${i}}_${paradigmarg} MATCHES "^([0-9]+);([^;]*)(;(.*))?$")
                set(priority${i} "${CMAKE_MATCH_1}")
                set(value${i} "${CMAKE_MATCH_2}")
                if(CMAKE_MATCH_COUNT EQUAL 4)
                    set(variant${i} "${CMAKE_MATCH_4}")
                endif()
            elseif(${prefix${i}}_${paradigmarg} MATCHES "^CONFLICT;([0-9]+);")
                set(priority${i} "${CMAKE_MATCH_1}")
                set(isconflict${i} TRUE)
            endif()
        endforeach()
        if(priority1 STREQUAL "" AND priority2 STREQUAL "")
            continue()
        elseif(isconflict1 OR isconflict2)
            _scorep_compare_conflict_values("${priority1}" "${priority2}" status)
        else()
            _scorep_compare_argument_values("${priority1}" "${value1}" "${variant1}" "${priority2}" "${value2}" "${variant2}" status)
        endif()
        if(status STREQUAL "SUPERSEDES")
            set("SETTING_${paradigmarg}" "${${prefix2}_${paradigmarg}}")
        elseif(status STREQUAL "SUPERSEDED")
            set("SETTING_${paradigmarg}" "${${prefix1}_${paradigmarg}}")
        else()
            set(
                "SETTING_${paradigmarg}"
                "CONFLICT;${priority1};Score-P: failed to merge settings '${${prefix1}_${paradigmarg}}' and '${${prefix2}_${paradigmarg}}'"
            )
        endif()
    endforeach()
    foreach(unionarg ${_SCOREP_UNION_SETTINGS})
        foreach(i 1 2)
            set(priority${i} "")
            set(values${i} "")
            if(${prefix${i}}_${unionarg} MATCHES "^([0-9]+);(.*)$")
                set(priority${i} "${CMAKE_MATCH_1}")
                set(values${i} "${CMAKE_MATCH_2}")
            endif()
        endforeach()
        if(priority1 STREQUAL "" AND priority2 STREQUAL "")
            continue()
        endif()
        _scorep_compare_argument_values("${priority1}" "${values1}" "" "${priority2}" "${values2}" "" status)
        if(status STREQUAL "SUPERSEDES")
            set("SETTING_${unionarg}" "${${prefix2}_${unionarg}}")
        elseif(status STREQUAL "SUPERSEDED")
            set("SETTING_${unionarg}" "${${prefix1}_${unionarg}}")
        else()
            list(APPEND values1 ${values2})
            set("SETTING_${unionarg}" "${priority1};${values1}")
        endif()
    endforeach()
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        set("${prefix}_${setting}" "${SETTING_${setting}}" PARENT_SCOPE)
    endforeach()
endfunction()

# Internal function which transforms setting variables with a prefix into Score-P arguments.
function(_scorep_settings2arguments prefix result)
    set(arguments "")
    foreach(enablearg ${_SCOREP_FLAG_SETTINGS})
        if(${prefix}_${enablearg} MATCHES "^[0-9]+;([^;]+)(;([^;]*);(.*))?$")
            if(CMAKE_MATCH_1)
                if(CMAKE_MATCH_COUNT EQUAL 1)
                    list(APPEND arguments "--${enablearg}")
                else()
                    list(APPEND arguments "--${enablearg}${CMAKE_MATCH_3}${CMAKE_MATCH_4}")
                endif()
            else()
                list(APPEND arguments "--no${enablearg}")
            endif()
        elseif(${prefix}_${enablearg} MATCHES "^CONFLICT;[0-9]+;(.*)$")
            message(FATAL_ERROR "${CMAKE_MATCH_1}")
        endif()
    endforeach()
    foreach(paradigmarg ${_SCOREP_CHOICE_SETTINGS})
        if(${prefix}_${paradigmarg} MATCHES "^[0-9]+;([^;]*)(;(.*))?$")
            if(CMAKE_MATCH_COUNT EQUAL 1)
                list(APPEND arguments "--${paradigmarg}=${CMAKE_MATCH_1}")
            else()
                list(APPEND arguments "--${paradigmarg}=${CMAKE_MATCH_1}:${CMAKE_MATCH_3}")
            endif()
        elseif(${prefix}_${paradigmarg} MATCHES "^CONFLICT;[0-9]+;(.*)$")
            message(FATAL_ERROR "${CMAKE_MATCH_1}")
        endif()
    endforeach()
    if(${prefix}_io MATCHES "^[0-9]+;(.*)$")
        string(REPLACE ";" "," value "${CMAKE_MATCH_1}")
        list(APPEND arguments "--io=${value}")
    elseif(${prefix}_io MATCHES "^CONFLICT;[0-9]+;(.*)$")
        message(FATAL_ERROR "${CMAKE_MATCH_1}")
    endif()
    if(${prefix}_other MATCHES "^[0-9]+;(.*)$")
        list(APPEND arguments ${CMAKE_MATCH_1})
    elseif(${prefix}_other MATCHES "^CONFLICT;[0-9]+;(.*)$")
        message(FATAL_ERROR "${CMAKE_MATCH_1}")
    endif()
    set("${result}" "${arguments}" PARENT_SCOPE)
endfunction()

# Internal function which transforms target properties into setting variables with a prefix.
function(_scorep_properties2settings prefix language target)
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        get_target_property(value "${target}" "SCOREP_${language}_SETTING_${setting}")
        if(value STREQUAL "value-NOTFOUND")
            set("${prefix}_${setting}" "" PARENT_SCOPE)
        else()
            set("${prefix}_${setting}" "${value}" PARENT_SCOPE)
        endif()
    endforeach()
endfunction()

# Internal function which applies settings from variables with a prefix to a target.
function(_scorep_settings2properties prefix language target)
    foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
        if(${prefix}_${setting} MATCHES "^CONFLICT;[0-9]+;(.*)$")
            message(FATAL_ERROR "${CMAKE_MATCH_1}")
        elseif(NOT ${prefix}_${setting} STREQUAL "")
            set_target_properties(
                "${target}"
                PROPERTIES "SCOREP_${language}_SETTING_${setting}"
                "${${prefix}_${setting}}"
            )
        endif()
    endforeach()
endfunction()

# Infers Score-P arguments for instrumenting a specific language of a target.
function(scorep_infer_arguments target language arguments result)
    _scorep_arguments2settings("${arguments}" 100 ARGUMENT)
    _scorep_environment2settings("${language}" 1500 INFERRED)
    _scorep_merge_settings(ARGUMENT INFERRED ARGUMENT)
    _scorep_determine_link_closure("${target}" _scorep_all_visitor _scorep_all_visitor dependencies)
    foreach(dependency ${dependencies})
        _scorep_link_dependency2settings("${dependency}" "${language}" 1500 INFERRED)
        _scorep_merge_settings(ARGUMENT INFERRED ARGUMENT)
    endforeach()
    _scorep_settings2arguments(ARGUMENT arguments)
    set("${result}" "${arguments}" PARENT_SCOPE)
endfunction()


# Get components required to be present when finding Score-P based of the arguments and language of a target.
function(scorep_arguments2components arguments lang result)
    set(components "")
    foreach(argument ${arguments})
        if(argument MATCHES "^--thread=omp(:.+)?$")
            if(CMAKE_MATCH_1 STREQUAL ":opari2")
                list(APPEND components "OPARI2")
            elseif(CMAKE_MATCH_1 STREQUAL ":ompt")
                list(APPEND components "OMPT")
            endif()
            list(APPEND components "OMP_${lang}")
        elseif(argument STREQUAL "--thread=pthread")
            list(APPEND components PTHREAD)
        elseif(argument STREQUAL "--mpp=mpi")
            list(APPEND components MPP_mpi)
        elseif(argument STREQUAL "--mpp=shmem")
            list(APPEND components MPP_shmem)
        elseif(argument STREQUAL "--io=posix")
            list(APPEND components IO_posix)
        elseif(argument STREQUAL "--compiler")
            list(APPEND components COMPILER)
        elseif(argument STREQUAL "--cuda")
            list(APPEND components CUDA)
        elseif(argument STREQUAL "--openmp")
            list(APPEND components "OMP_${lang}")
        elseif(argument STREQUAL "--pdt")
            list(APPEND components PDT)
        elseif(argument STREQUAL "--opencl")
            list(APPEND components OPENCL)
        elseif(argument STREQUAL "--openacc")
            list(APPEND components OPENACC)
        elseif(argument STREQUAL "--memory")
            list(APPEND components MEMORY)
        elseif(argument STREQUAL "--kokkos")
            list(APPEND components KOKKOS)
        elseif(argument STREQUAL "--hip")
            list(APPEND components HIP)
        endif()
    endforeach()
    set("${result}" "${components}" PARENT_SCOPE)
endfunction()


# Get components required to be present when finding Score-P based on current CMake variables.
function(scorep_infer_components language result)
    set(detectedComponents "")
    if(language STREQUAL C)
        set(scorepLanguage "C99")
    elseif(language STREQUAL CXX)
        set(scorepLanguage "CXX11")
    elseif(language STREQUAL Fortran)
        set(scorepLanguage "Fortran")
    else()
        set("${result}" "${detectedComponents}" PARENT_SCOPE)
        return()
    endif()
    if(CMAKE_${language}_COMPILER)
        list(APPEND detectedComponents "COMPILER_${scorepLanguage}_${CMAKE_${language}_COMPILER}")
    endif()
    if(MPI_${language}_COMPILER)
        list(APPEND detectedComponents "MPI_COMPILER_${scorepLanguage}_${MPI_${language}_COMPILER}")
    endif()
    set("${result}" "${detectedComponents}" PARENT_SCOPE)
endfunction()


# Discovers targets in directories and stores them as a list in a variable.
function(scorep_discover_targets result)
    set(targets "")
    if("${ARGN}" STREQUAL "")
        set(directories "${CMAKE_CURRENT_SOURCE_DIR}")
    else()
        set(directories "${ARGN}")
    endif()
    foreach(directory ${directories})
        _scorep_get_all_targets("${directory}" directoryTargets)
        set(validTargets "")
        foreach(directoryTarget ${directoryTargets})
            get_target_property(type "${directoryTarget}" TYPE)
            if(type STREQUAL "INTERFACE_LIBRARY")
                continue()
            endif()
            get_target_property(imported "${directoryTarget}" IMPORTED)
            if((NOT imported STREQUAL "imported-NOTFOUND") AND imported)
                continue()
            endif()
            get_target_property(aliased "${directoryTarget}" ALIASED_TARGET)
            if((NOT aliased STREQUAL "aliased-NOTFOUND") AND aliased)
                continue()
            endif()
            list(APPEND validTargets "${directoryTarget}")
        endforeach()
        list(APPEND targets ${validTargets})
    endforeach()
    list(REMOVE_DUPLICATES targets)
    set("${result}" "${targets}" PARENT_SCOPE)
endfunction()


# Configures targets to be instrumented by Score-P.
function(scorep_instrument targets)
    cmake_parse_arguments(
        ARG
        "OVERRIDE;AUTO;OVERRIDE_VARIABLES"
        ""
        "LANGS;ARGUMENTS"
        ${ARGN}
    )
    if(NOT (DEFINED ScoreP_FOUND AND TARGET ScoreP::ScoreP))
        message(FATAL_ERROR "Score-P: called 'scorep_instrument' before finding ScoreP")
        return()
    endif()
    get_target_property(scorep ScoreP::ScoreP IMPORTED_LOCATION)

    if(ARG_AUTO)
        _scorep_arguments2settings("${ARG_ARGUMENTS}" 100 ARGUMENT)
    endif()

    foreach(target ${targets})
        if(NOT ARG_OVERRIDE_VARIABLES AND DEFINED "SCOREP_LANGUAGES_${target}")
            set(languages "${SCOREP_LANGUAGES_${target}}")
        else()
            set(languages ${ARG_LANGS})
        endif()
        if(ARG_AUTO)
            _scorep_determine_link_closure("${target}" _scorep_all_visitor _scorep_all_visitor dependencies)
        endif()
        foreach(lang ${languages})
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
            if(NOT ARG_OVERRIDE_VARIABLES AND DEFINED "SCOREP_${lang}_ARGUMENTS_${target}")
                set(arguments "${SCOREP_${lang}_ARGUMENTS_${target}}")
            else()
                set(arguments ${ARG_ARGUMENTS})
            endif()
            if(ARG_AUTO)
                _scorep_environment2settings("${lang}" 1500 INFERRED)
                _scorep_merge_settings(ARGUMENT INFERRED TARGET_ARGUMENT)
                foreach(dependency ${dependencies})
                    _scorep_link_dependency2settings("${dependency}" "${lang}" 1500 INFERRED)
                    _scorep_merge_settings(TARGET_ARGUMENT INFERRED TARGET_ARGUMENT)
                endforeach()
                _scorep_settings2arguments(TARGET_ARGUMENT targetLauncher)
                list(PREPEND targetLauncher "${scorep}")
            else()
                set(targetLauncher "${scorep}" ${arguments})
            endif()
            set_target_properties("${target}" PROPERTIES ${lang}_COMPILER_LAUNCHER "${targetLauncher}")
            set_target_properties("${target}" PROPERTIES ${lang}_LINKER_LAUNCHER "${targetLauncher}")
        endforeach()
    endforeach()
endfunction()


# Marks targets for the high-level interface.
function(scorep_mark mode targets)
    if(NOT (mode STREQUAL "HINT" OR mode STREQUAL "INSTRUMENT"))
        message(FATAL_ERROR "Score-P: called 'scorep_mark' with invalid mode: '${mode}'")
        return()
    endif()
    cmake_parse_arguments(
        ARG
        "AUTO"
        "PRIORITY"
        "LANGS;ARGUMENTS"
        ${ARGN}
    )
    if(NOT DEFINED ARG_PRIORITY)
        set(ARG_PRIORITY 100)
    elseif(ARG_PRIORITY STREQUAL "OPTIONAL")
        set(ARG_PRIORITY 1000)
    elseif(ARG_PRIORITY STREQUAL "DEFAULT")
        set(ARG_PRIORITY 100)
    elseif(ARG_PRIORITY STREQUAL "FORCE")
        set(ARG_PRIORITY 0)
    elseif(ARG_PRIORITY MATCHES "^[0-9]+$")
    else()
        message(FATAL_ERROR "Score-P: called 'scorep_mark' with invalid priority: '${ARG_PRIORITY}'")
        return()
    endif()
    _scorep_arguments2settings("${ARG_ARGUMENTS}" "${ARG_PRIORITY}" ARGUMENT)

    foreach(target ${targets})
        if(ARG_AUTO)
            _scorep_determine_link_closure("${target}" _scorep_all_visitor _scorep_all_visitor dependencies)
        endif()
        foreach(lang ${ARG_LANGS})
            if(ARG_AUTO)
                _scorep_environment2settings("${lang}" 1500 INFERRED)
                _scorep_merge_settings(ARGUMENT INFERRED TARGET_ARGUMENT)
                foreach(dependency ${dependencies})
                    _scorep_link_dependency2settings("${dependency}" "${lang}" 1500 INFERRED)
                    _scorep_merge_settings(TARGET_ARGUMENT INFERRED TARGET_ARGUMENT)
                endforeach()
                _scorep_settings2properties(TARGET_ARGUMENT "${lang}" "${target}")
            else()
                _scorep_settings2properties(ARGUMENT "${lang}" "${target}")
            endif()
        endforeach()
        if(mode STREQUAL "INSTRUMENT")
            get_target_property(imported "${target}" IMPORTED)
            get_target_property(aliased "${target}" ALIASED_TARGET)
            if(imported)
                message(WARNING "Score-P: imported target '${target}' can not be instrumented")
            elseif(aliased)
                message(WARNING "Score-P: alias target '${target}' can not be instrumented")
            else()
                set_property(TARGET "${target}" APPEND PROPERTY SCOREP_LANGUAGES ${ARG_LANGS})
            endif()
        endif()
    endforeach()
endfunction()


# Determines which and how targets marked by `scorep_mark` need to be instrumented.
function(scorep_determine_instrumentations targets)
    cmake_parse_arguments(
        ARG
        ""
        "COMPONENTS_VAR"
        ""
        ${ARGN}
    )
    set(components "")
    
    foreach(target ${targets})
        get_target_property(type "${target}" TYPE)
        if(type STREQUAL "EXECUTABLE" OR type STREQUAL "SHARED_LIBRARY" OR type STREQUAL "MODULE_LIBRARY")
            _scorep_determine_link_closure("${target}" _scorep_not_standalone_visitor _scorep_all_visitor dependencies)
            set(targets "")
            foreach(dependency ${dependencies})
                if(TARGET "${dependency}")
                    list(APPEND targets "${dependency}")
                endif()
            endforeach()
            set(dependencies "${targets}")

            set(languages "")
            foreach(dependency "${target}" ${dependencies})
                get_target_property(targetLanguages "${dependency}" SCOREP_LANGUAGES)
                if(NOT targetLanguages STREQUAL "targetLanguages-NOTFOUND")
                    list(APPEND languages ${targetLanguages})
                endif()
            endforeach()
            list(REMOVE_DUPLICATES languages)

            foreach(language ${languages})
                foreach(setting ${_SCOREP_FLAG_SETTINGS} ${_SCOREP_CHOICE_SETTINGS} ${_SCOREP_UNION_SETTINGS})
                    set("LANGUAGE_${setting}" "")
                endforeach()
                foreach(dependency "${target}" ${dependencies})
                    _scorep_properties2settings(DEPENDENCY "${language}" "${dependency}")
                    _scorep_merge_settings(LANGUAGE DEPENDENCY LANGUAGE)
                endforeach()

                _scorep_settings2arguments(LANGUAGE "arguments_${language}")
                if(ARG_COMPONENTS_VAR)
                    scorep_arguments2components("${arguments_${language}}" "${language}" targetComponents)
                    list(APPEND components ${targetComponents})
                    list(REMOVE_DUPLICATES components)
                endif()
            endforeach()

            foreach(dependency "${target}" ${dependencies})
                if(dependency STREQUAL target)
                    set(targetLanguages "${languages}")
                else()
                    get_target_property(targetLanguages "${dependency}" SCOREP_LANGUAGES)
                    if(targetLanguages STREQUAL "targetLanguages-NOTFOUND")
                        continue()
                    endif()
                endif()
                foreach(language ${targetLanguages})
                    get_target_property(targetArguments "${dependency}" "SCOREP_${language}_ARGUMENTS")
                    if(targetArguments STREQUAL "targetArguments-NOTFOUND")
                        set_target_properties(
                            "${dependency}"
                            PROPERTIES "SCOREP_${language}_ARGUMENTS"
                            "${arguments_${language}}"
                        )
                    elseif(NOT targetArguments STREQUAL "${arguments_${language}}")
                        message(FATAL_ERROR "Score-P: target ${dependency} has SCOREP_${language}_ARGUMENTS already set to '${targetArguments}'")
                    endif()
                endforeach()
            endforeach()
        endif()
    endforeach()

    if(ARG_COMPONENTS_VAR)
        set("${ARG_COMPONENTS_VAR}" "${components}" PARENT_SCOPE)
    endif()
endfunction()


# Instruments targets marked by `scorep_mark` using `scorep_instrument` based on the `SCOREP_<LANG>_ARGUMENTS` target property.
function(scorep_enable targets)
    cmake_parse_arguments(
        ARG
        "OVERRIDE;OVERRIDE_VARIABLES"
        ""
        ""
        ${ARGN}
    )

    foreach(target ${targets})
        if(NOT ARG_OVERRIDE_VARIABLES AND DEFINED "SCOREP_LANGUAGES_${target}")
            set(languages "${SCOREP_LANGUAGES_${target}}")
        else()
            get_target_property(languages "${target}" SCOREP_LANGUAGES)
            if(languages STREQUAL "languages-NOTFOUND")
                continue()
            endif()
        endif()
        foreach(lang ${languages})
            if(NOT ARG_OVERRIDE_VARIABLES AND DEFINED "SCOREP_${lang}_ARGUMENTS_${target}")
                set(arguments "${SCOREP_${lang}_ARGUMENTS_${target}}")
            else()
                get_target_property(arguments "${target}" SCOREP_${lang}_ARGUMENTS)
                if(arguments STREQUAL "arguments-NOTFOUND")
                    continue()
                endif()
            endif()
            if(ARG_OVERRIDE)
                scorep_instrument("${target}" LANGS ${lang} ARGUMENTS ${arguments} OVERRIDE_VARIABLES OVERRIDE)
            else()
                scorep_instrument("${target}" LANGS ${lang} ARGUMENTS ${arguments} OVERRIDE_VARIABLES)
            endif()
        endforeach()
    endforeach()
endfunction()
