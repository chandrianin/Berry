cmake_minimum_required(VERSION 3.28)
project(Berry)

set(CMAKE_CXX_STANDARD 17)

file(GLOB project_GLOB
        src/*)

set(wxWidgets_ROOT_DIR "D:/Berry/wxWidgets")
set(wxWidgets_LIB_DIR "D:/Berry/wxWidgets/lib/gcc810_x64_dll")

find_package(wxWidgets REQUIRED COMPONENTS net core base)

if(wxWidgets_USE_FILE) # not defined in CONFIG mode
    include(${wxWidgets_USE_FILE})
endif()

add_executable(${PROJECT_NAME} ${project_GLOB})

target_link_libraries(${PROJECT_NAME} ${wxWidgets_LIBRARIES})
target_include_directories(${PROJECT_NAME} PRIVATE ${wxWidgets_INCLUDE_DIR})