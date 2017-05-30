project(SDPAWrap)

cmake_minimum_required(VERSION 2.8.12)
set(CMAKE_MACOSX_RPATH 1)

# debug
set(CMAKE_VERBOSE_MAKEFILE ON)

list(APPEND CMAKE_CXX_FLAGS "-std=c++11")
add_definitions(-DJULIA_ENABLE_THREADING)

if(WIN32 AND "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=pentium4")
endif()

find_package(JlCxx)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib;${JlCxx_DIR}/../../../lib")

# SDPA_DIR is set by build.jl
include_directories(${SDPA_DIR})
include_directories(${MUMPS_INCLUDE_DIR})

add_library(sdpawrap SHARED sdpawrap.cpp)
# ${PORD_LIB}: PORD_LIB does not seem usefull
target_link_libraries(sdpawrap JlCxx::jlcxx ${SDPA_LIBRARY})

get_property(JULIA_LIBRARY TARGET JlCxx::jlcxx PROPERTY INTERFACE_LINK_LIBRARIES)
get_property(JULIA_INCLUDES TARGET JlCxx::jlcxx PROPERTY INTERFACE_INCLUDE_DIRECTORIES)

install(TARGETS
    sdpawrap
LIBRARY DESTINATION lib${LIBDIR_SUFFIX}
ARCHIVE DESTINATION lib${LIBDIR_SUFFIX}
RUNTIME DESTINATION lib${LIBDIR_SUFFIX}
INCLUDES DESTINATION include)
