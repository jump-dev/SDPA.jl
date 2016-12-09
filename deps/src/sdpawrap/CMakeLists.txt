project(SDPA)

cmake_minimum_required(VERSION 2.8.12)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
set(CMAKE_MACOSX_RPATH 1)

list(APPEND CMAKE_CXX_FLAGS "-std=c++11")
add_definitions(-DJULIA_ENABLE_THREADING)

if(WIN32 AND "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=pentium4")
endif()

find_package(CxxWrap)

add_library(sdpawrap SHARED sdpawrap.cpp)
target_link_libraries(sdpawrap CxxWrap::cxx_wrap)

get_property(JULIA_LIBRARY TARGET CxxWrap::cxx_wrap PROPERTY INTERFACE_LINK_LIBRARIES)
get_property(JULIA_INCLUDES TARGET CxxWrap::cxx_wrap PROPERTY INTERFACE_INCLUDE_DIRECTORIES)

install(TARGETS
    sdpawrap
LIBRARY DESTINATION lib${LIBDIR_SUFFIX}
ARCHIVE DESTINATION lib${LIBDIR_SUFFIX}
RUNTIME DESTINATION lib${LIBDIR_SUFFIX}
INCLUDES DESTINATION include)
