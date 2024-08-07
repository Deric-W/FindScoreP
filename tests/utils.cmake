function(_check_lists_equal actual expected)
    list(LENGTH actual actualLength)
    list(LENGTH expected expectedLength)
    if(NOT (actualLength EQUAL expectedLength))
        message(FATAL_ERROR "lists '${actual}' and '${expected}' have different lengths")
    endif()
    foreach(element ${expected})
        list(FIND actual "${element}" found)
        if(found EQUAL -1)
            message(FATAL_ERROR "Expected element '${element}' was not found in '${actual}'")
        endif()
    endforeach()
endfunction()