set(
    TEST_ARGUMENTS
    "-Wdev;-Werror=dev"
    CACHE
    STRING
    "Additional CMake arguments used during testing the module as a list."
)
set(temporaryBinaryDir "${CMAKE_CURRENT_BINARY_DIR}/temporary-binary-dir")

add_test(
    NAME "Test result variables"
    COMMAND "${CMAKE_COMMAND}" 
    ${TEST_ARGUMENTS}
    --fresh
    "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
    -S "${CMAKE_CURRENT_LIST_DIR}/TestResultVariables"
    -B "${temporaryBinaryDir}"
)

add_test(
    NAME "Test missing Score-P installation"
    COMMAND "${CMAKE_COMMAND}"
    ${TEST_ARGUMENTS}
    "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
    "-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF"
    -P "${CMAKE_CURRENT_LIST_DIR}/find_scorep.cmake"
)
set_property(TEST "Test missing Score-P installation" PROPERTY WILL_FAIL true)

add_test(
    NAME "Test multiple installed versions"
    COMMAND "${CMAKE_COMMAND}" -E env
    --modify "PATH=path_list_append:${CMAKE_CURRENT_LIST_DIR}/TestMultipleVersions/0.0.0.2"
    --modify "PATH=path_list_append:${CMAKE_CURRENT_LIST_DIR}/TestMultipleVersions/0.0.0.3"
    "${CMAKE_COMMAND}"
    ${TEST_ARGUMENTS}
    "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
    -P "${CMAKE_CURRENT_LIST_DIR}/TestMultipleVersions/find_multiple.cmake"
)

add_test(
    NAME "Test version range"
    COMMAND "${CMAKE_COMMAND}" -E env
    --modify "PATH=path_list_append:${CMAKE_CURRENT_LIST_DIR}/TestMultipleVersions/0.0.0.3"
    "${CMAKE_COMMAND}"
    ${TEST_ARGUMENTS}
    "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
    -P "${CMAKE_CURRENT_LIST_DIR}/TestMultipleVersions/find_range.cmake"
)
set_property(TEST "Test version range" PROPERTY WILL_FAIL true)
