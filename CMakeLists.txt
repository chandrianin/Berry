cmake_minimum_required(VERSION 3.16)

project(Berry VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
list(APPEND CMAKE_PREFIX_PATH "C:/Qt/6.6./msvc2019_64/lib/cmake")

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Widgets QuickWidgets)

# include_directories(inc)
set(CMAKE_AUTORCC ON)
qt_standard_project_setup(REQUIRES 6.5)

# target_sources(appBerry
#   PRIVATE
#     src/tray.cpp
# )
enable_language("RC")
set (WIN32_RESOURCES "${CMAKE_CURRENT_SOURCE_DIR}/Images/appIcons/favicon.rc")

qt_add_executable(appBerry
    main.cpp
    ${WIN32_RESOURCES}
)

qt_add_qml_module(appBerry
    URI Berry
    VERSION 1.0
    QML_FILES
        Main.qml
        RESOURCES images/appIcons/trayIcon.png images/Berry/test.gif images/Berry/testDialog.png images/Berry/testRectangle.gif images/einvironment/dialog.png
        RESOURCES images/appIcons/trayIcon.png images/Berry/happy/stand_5.png images/Berry/test.gif images/Berry/testDialog.png images/Berry/testRectangle.gif images/einvironment/dialog.png
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appBerry PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appBerry
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appBerry
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Widgets
    PRIVATE Qt6::QuickWidgets

)

include(GNUInstallDirs)
install(TARGETS appBerry
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

set(PATH_TO_BERRY "Images/Berry")

file(GLOB BERRY_FILES "${PATH_TO_BERRY}/*")
foreach(file ${BERRY_FILES})
    file(COPY ${file} DESTINATION ${PATH_TO_BERRY})
endforeach()


set(PATH_TO_EINVIRONMENT "Images/einvironment")

file(GLOB EINVIRONMENT_FILES "${PATH_TO_EINVIRONMENT}/*")
foreach(file ${EINVIRONMENT_FILES})
    install(FILES ${file} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
    file(COPY ${file} DESTINATION ${PATH_TO_EINVIRONMENT})
endforeach()

set(PATH_TO_ICONS "Images/appIcons")

file(GLOB ICONS_FILES "${PATH_TO_ICONS}/*")
foreach(file ${ICONS_FILES})
    install(FILES ${file} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
    file(COPY ${file} DESTINATION ${PATH_TO_ICONS})
endforeach()

set(QT_PATH "C:/Qt/6.6.3/mingw_64")
add_custom_command(TARGET appBerry POST_BUILD
    COMMAND "${QT_PATH}/bin/windeployqt.exe" --release $<TARGET_FILE:appBerry>
    COMMENT "Deploying dependencies with windeployqt"
)
