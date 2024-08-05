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

# Visitor which visits all targets.
function(_scorep_all_visitor dependency variable)
endfunction()

# Visitor which only visits standalone targets.
function(_scorep_not_standalone_visitor dependency variable)
    if(TARGET "${dependency}")
        get_target_property(type "${dependency}" TYPE)
        if(type STREQUAL "EXECUTABLE" OR type STREQUAL "SHARED_LIBRARY" OR type STREQUAL "MODULE_LIBRARY")
            set("${variable}" FALSE PARENT_SCOPE)
        endif()
    endif()
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
