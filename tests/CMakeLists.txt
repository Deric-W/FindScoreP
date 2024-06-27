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
set_property(TEST "Test result variables" PROPERTY LABELS scorep)

add_test(
    NAME "Test missing Score-P installation"
    COMMAND "${CMAKE_COMMAND}"
    ${TEST_ARGUMENTS}
    "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
    "-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF"
    -P "${CMAKE_CURRENT_LIST_DIR}/find_scorep.cmake"
)
set_property(TEST "Test missing Score-P installation" PROPERTY WILL_FAIL true)
set_property(TEST "Test missing Score-P installation" PROPERTY LABELS cmake)

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
set_property(TEST "Test multiple installed versions" PROPERTY LABELS cmake)

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
set_property(TEST "Test version range" PROPERTY LABELS cmake)

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
set_property(TEST "Test Score-P instrumentation during configure phase" PROPERTY LABELS scorep c)

add_test(
    NAME "Test handling of components"
    COMMAND "${CMAKE_COMMAND}" -E env
    --modify "PATH=path_list_append:${CMAKE_CURRENT_LIST_DIR}/TestMultipleVersions/0.0.0.3"
    "${CMAKE_COMMAND}"
    ${TEST_ARGUMENTS}
    "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
    -P "${CMAKE_CURRENT_LIST_DIR}/find_components.cmake"
)
set_property(TEST "Test handling of components" PROPERTY LABELS cmake)

add_test(
    NAME "Test ScorePUtilities detecting all targets"
    COMMAND "${CMAKE_COMMAND}"
    ${TEST_ARGUMENTS}
    --fresh
    "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
    -S "${CMAKE_CURRENT_LIST_DIR}/TestListTargets"
    -B "${temporaryDir}/TestListTargets"
)
set_property(TEST "Test ScorePUtilities detecting all targets" PROPERTY FIXTURES_REQUIRED tmpdir)
set_property(TEST "Test ScorePUtilities detecting all targets" PROPERTY LABELS cmake)

function(_add_example_tests example labels)
    add_test(
        NAME "Test ${example} example without Score-P"
        COMMAND "${CMAKE_CTEST_COMMAND}"
        --build-and-test "${CMAKE_SOURCE_DIR}/examples/${example}" "${temporaryDir}/${example}/without"
        --build-generator "${CMAKE_GENERATOR}"
        --build-options --fresh "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src"
        --test-command "${CMAKE_CTEST_COMMAND}"
    )
    set_property(TEST "Test ${example} example without Score-P" PROPERTY FIXTURES_REQUIRED tmpdir)
    set_property(TEST "Test ${example} example without Score-P" PROPERTY LABELS examples ${labels})

    add_test(
        NAME "Test ${example} example with Score-P"
        COMMAND "${CMAKE_CTEST_COMMAND}"
        --build-and-test "${CMAKE_SOURCE_DIR}/examples/${example}" "${temporaryDir}/${example}/with"
        --build-generator "${CMAKE_GENERATOR}"
        --build-options --fresh "-DCMAKE_MODULE_PATH=${CMAKE_SOURCE_DIR}/src" "-DENABLE_SCOREP=ON"
        --test-command "${CMAKE_CTEST_COMMAND}"
    )
    set_property(TEST "Test ${example} example with Score-P" PROPERTY FIXTURES_REQUIRED tmpdir)
    set_property(TEST "Test ${example} example with Score-P" PROPERTY LABELS examples scorep ${labels})
endfunction()

_add_example_tests(openmp "openmp;boost")
_add_example_tests(pthread "pthread;boost")
