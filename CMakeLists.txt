cmake_minimum_required(VERSION 3.10)
project(hybrid-compute LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add conda environment to CMAKE_PREFIX_PATH for OpenCV
if(APPLE)
    set(CMAKE_PREFIX_PATH "$ENV{HOME}/miniconda3" ${CMAKE_PREFIX_PATH})
endif()

find_package(OpenCV REQUIRED)
find_package(CUDAToolkit)

include_directories(${OpenCV_INCLUDE_DIRS})
include_directories(${CMAKE_SOURCE_DIR}/include)

add_executable(preprocess src/preprocess.cpp)
target_link_libraries(preprocess ${OpenCV_LIBS})



# Unit tests
enable_testing()
add_executable(test_utils tests/test_utils.cpp)
target_link_libraries(test_utils ${OpenCV_LIBS})
add_test(NAME test_utils COMMAND test_utils)