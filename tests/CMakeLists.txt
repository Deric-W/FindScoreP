set(
    TEST_ARGUMENTS
    "-Wdev;-Werror=dev"
    CACHE
    STRING
    "Additional CMake arguments used during testing the module as a list."
)
set(temporaryDir "${CMAKE_CURRENT_BINARY_DIR}/test-tmpdir")
set_property(
    DIRECTORY
    APPEND
    PROPERTY ADDITIONAL_CLEAN_FILES "${temporaryDir}"
)

add_test(
    NAME "Clear tempdir"
    COMMAND "${CMAKE_COMMAND}" -E rm -rf "${temporaryDir}"
)
set_property(TEST "Clear tempdir" PROPERTY FIXTURES_SETUP tmpdir)

add_test(
    NAME "Create tempdir"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${temporaryDir}"
)
set_property(TEST "Create tempdir" PROPERTY FIXTURES_SETUP tmpdir)
set_property(TEST "Create tempdir" PROPERTY DEPENDS "Clear tempdir")


add_test(
    NAME "Test result variables"
    COMMAND "${CMAKE_COMMAND}" 
    ${TEST_ARGUMENTS}
    --fresh
    "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
    -S "${CMAKE_CURRENT_LIST_DIR}/TestResultVariables"
    -B "${temporaryDir}/TestResultVariables"
)
set_property(TEST "Test result variables" PROPERTY FIXTURES_REQUIRED tmpdir)

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

add_test(
    NAME "Test Score-P instrumentation during configure phase"
    COMMAND "${CMAKE_COMMAND}" 
    ${TEST_ARGUMENTS}
    --fresh
    "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
    "-DCMAKE_C_COMPILER_LAUNCHER=scorep"
    "-DCMAKE_C_LINKER_LAUNCHER=scorep"
    -S "${CMAKE_CURRENT_LIST_DIR}/TestTryCompile"
    -B "${temporaryDir}/TestTryCompile"
)
set_property(TEST "Test Score-P instrumentation during configure phase" PROPERTY FIXTURES_REQUIRED tmpdir)
