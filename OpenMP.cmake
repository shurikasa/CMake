find_package(OpenMP)
if(OPENMP_FOUND)
    if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL "ppc64")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -qsmp -qthreaded")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -qsmp -qthreaded")
    else()
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fopenmp")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fopenmp")
    endif()
endif()