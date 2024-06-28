cmake_minimum_required(VERSION 3.16)

project(Berry VERSION 0.1 LANGUAGES CXX)


set(CMAKE_CXX_STANDARD_REQUIRED ON)
list(APPEND CMAKE_PREFIX_PATH "C:/Qt/6.6.3/mingw_64/lib/cmake")

include(FetchContent)
FetchContent_Declare(cpr GIT_REPOSITORY https://github.com/libcpr/cpr.git
        GIT_TAG 3b15fa82ea74739b574d705fea44959b58142eb8) # Replace with your desired git commit from: https://github.com/libcpr/cpr/releases
FetchContent_MakeAvailable(cpr)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Widgets QuickWidgets)


set(CMAKE_AUTORCC ON)
qt_standard_project_setup(REQUIRES 6.5)

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
        RESOURCES images/appIcons/favicon.ico images/appIcons/favicon.rc images/appIcons/trayIcon.png
        RESOURCES images/Berry/action_1.svg images/Berry/action_2.svg images/Berry/action_3.svg
        RESOURCES images/environment/ball.svg images/Berry/kickBallEnd.svg images/Berry/kickBallStart.svg images/Berry/charging.svg images/environment/chargingModule.svg images/environment/dialog.svg
        RESOURCES images/Berry/happy/moveBottom_6.svg images/Berry/happy/moveLeft_8.svg images/Berry/happy/moveRight_8.svg images/Berry/happy/stand_5.svg images/Berry/happy/moveTop_6.svg
        RESOURCES images/Berry/sad/moveBottom_6.svg   images/Berry/sad/moveLeft_8.svg   images/Berry/sad/moveRight_8.svg   images/Berry/sad/stand_5.svg
        RESOURCES images/Berry/crazy/moveBottom_6.svg images/Berry/crazy/moveLeft_8.svg images/Berry/crazy/moveRight_8.svg images/Berry/crazy/stand_5.svg
        RESOURCES images/Berry/thinking.svg images/Berry/smiling.svg images/Berry/sadHi.svg images/Berry/hi.svg

        RESOURCES audio/singleBerryTalk.wav audio/berryTalk.mp3 audio/ballKick.wav

        RESOURCES font/BalsamiqSans-BoldItalic.ttf
        RESOURCES images/appIcons/favicon.ico images/appIcons/favicon.rc images/appIcons/trayIcon.png images/Berry/crazy/moveBottom_6.svg images/Berry/crazy/moveLeft_8.svg images/Berry/crazy/moveRight_8.svg images/Berry/crazy/stand_5.svg images/Berry/happy/moveBottom_6.svg images/Berry/happy/moveLeft_8.svg images/Berry/happy/moveRight_8.svg images/Berry/happy/moveTop_6.svg images/Berry/happy/stand_5.svg images/Berry/sad/moveBottom_6.png images/Berry/sad/moveBottom_6.svg images/Berry/sad/moveLeft_8.png images/Berry/sad/moveLeft_8.svg images/Berry/sad/moveRight_8.png images/Berry/sad/moveRight_8.svg images/Berry/sad/stand_5.png images/Berry/sad/stand_5.svg images/Berry/action_1.svg images/Berry/action_2.svg images/Berry/action_3.svg images/Berry/charging.svg images/Berry/eyesBottom.svg images/Berry/eyesDown.svg images/Berry/eyesInSomewhere.svg images/Berry/eyesOnPlayer.svg images/Berry/eyesSomewhere.svg images/Berry/eyesUp.svg images/Berry/hi.svg images/Berry/holdHead.svg images/Berry/kickBallEnd.svg images/Berry/kickBallStart.svg images/Berry/sadHi.svg images/Berry/smiling.svg images/Berry/thinking.svg images/Berry/toDoListWow.svg images/environment/ball.svg images/environment/chargingModule.svg images/environment/dialog.svg images/environment/toDoList.svg
        RESOURCES images/appIcons/favicon.ico images/appIcons/favicon.rc images/appIcons/trayIcon.png images/Berry/crazy/moveBottom_6.svg images/Berry/crazy/moveLeft_8.svg images/Berry/crazy/moveRight_8.svg images/Berry/crazy/stand_5.svg images/Berry/happy/moveBottom_6.svg images/Berry/happy/moveLeft_8.svg images/Berry/happy/moveRight_8.svg images/Berry/happy/moveTop_6.svg images/Berry/happy/stand_5.svg images/Berry/sad/moveBottom_6.png images/Berry/sad/moveBottom_6.svg images/Berry/sad/moveLeft_8.png images/Berry/sad/moveLeft_8.svg images/Berry/sad/moveRight_8.png images/Berry/sad/moveRight_8.svg images/Berry/sad/stand_5.png images/Berry/sad/stand_5.svg images/Berry/action_1.svg images/Berry/action_2.svg images/Berry/action_3.svg images/Berry/charging.svg images/Berry/eyesBottom.svg images/Berry/eyesDown.svg images/Berry/eyesInSomewhere.svg images/Berry/eyesOnPlayer.svg images/Berry/eyesSomewhere.svg images/Berry/eyesUp.svg images/Berry/hi.svg images/Berry/holdHead.svg images/Berry/kickBallEnd.svg images/Berry/kickBallStart.svg images/Berry/sadHi.svg images/Berry/smiling.svg images/Berry/thinking.svg images/Berry/toDoListWow.svg images/environment/ball.svg images/environment/chargingModule.svg images/environment/dialog.svg images/environment/toDoList.png images/environment/toDoList.svg

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
FetchContent_GetProperties(cpr)
if(NOT cpr_POPULATED)
    FetchContent_Populate(cpr)
endif()
target_include_directories(appBerry PRIVATE ${cpr_BINARY_DIR}/include)
target_link_libraries(appBerry PRIVATE cpr)
set(PATH_TO_CPR_LIBS "images/appIcons")

file(GLOB LIBS_FILES "${PATH_TO_CPR_LIBS}/*")
foreach(file ${LIBS_FILES})
    # install(FILES ${file} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
    file(COPY ${file} DESTINATION "/")
endforeach()

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

set(PATH_TO_ICONS "images/appIcons")

file(GLOB ICONS_FILES "${PATH_TO_ICONS}/*")
foreach(file ${ICONS_FILES})
    install(FILES ${file} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
    file(COPY ${file} DESTINATION ${PATH_TO_ICONS})
endforeach()

set(QT_PATH "C:/Qt/6.6.3/mingw_64")
# add_custom_command(TARGET appBerry POST_BUILD
#     COMMAND "${QT_PATH}/bin/windeployqt.exe" --release $<TARGET_FILE:appBerry>
#     COMMENT "Deploying dependencies with windeployqt"
# )
