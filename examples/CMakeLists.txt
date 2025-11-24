cmake_minimum_required(VERSION 3.16)

project(ExampleApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)

include(FetchContent)
FetchContent_Declare(
    NativeWebView
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..
)
FetchContent_MakeAvailable(NativeWebView)

qt_add_executable(ExampleAppRunner
    main.cpp
)

qt_add_qml_module(ExampleAppRunner
    URI ExampleApp
    VERSION 1.0
    QML_FILES
        Main.qml
)

target_link_libraries(ExampleAppRunner PRIVATE
    Qt6::Core
    Qt6::Quick
    NativeWebView
    NativeWebViewplugin
)
