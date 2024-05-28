find_package(
    ScoreP
    "0.0.0.3"
    EXACT
    COMPONENTS "DUMMY_COMPONENT"
)

if(ScoreP_FOUND)
    message(FATAL_ERROR "found Score-P with wrong components")
endif()


find_package(
    ScoreP
    "0.0.0.3"
    EXACT
    REQUIRED
    COMPONENTS "COMPILER"
    OPTIONAL_COMPONENTS "DUMMY_COMPONENT"
)

if(NOT ScoreP_COMPILER_FOUND)
    message(FATAL_ERROR "ScoreP_COMPILER_FOUND not set")
endif()
if(ScoreP_DUMMY_COMPONENT_FOUND)
    message(FATAL_ERROR "ScoreP_DUMMY_COMPONENT_FOUND set")
endif()