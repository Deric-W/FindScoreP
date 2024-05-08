add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/FindScoreP.cmake
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/FindScoreP.cmake
    COMMAND 
        ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_CURRENT_SOURCE_DIR}/FindScoreP.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/FindScoreP.cmake
)
add_custom_target(build_module ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/FindScoreP.cmake)