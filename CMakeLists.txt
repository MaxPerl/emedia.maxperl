cmake_minimum_required(VERSION 3.0.0)
project(emedia C CXX)

# Automatische Erstellung von Qt-Moc-Dateien
set(CMAKE_AUTOMOC ON)

# Alle benötigten Qt5-Pakete suchen
find_package(Qt5Core REQUIRED)
find_package(Qt5Gui REQUIRED)
find_package(Qt5Qml REQUIRED)
find_package(Qt5Quick REQUIRED)
find_package(Qt5QuickControls2 REQUIRED)
find_package(Qt5DBus REQUIRED)

# PkgConfig aktivieren und das gefundene Lomiri-Paket einbinden
find_package(PkgConfig REQUIRED)
pkg_check_modules(CONTENT_HUB REQUIRED liblomiri-content-hub)

execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_MULTIARCH
    OUTPUT_VARIABLE ARCH_TRIPLET
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
set(QT_IMPORTS_DIR "lib/${ARCH_TRIPLET}")

set(PROJECT_NAME "emedia")
set(FULL_PROJECT_NAME "emedia.maxperl")
set(DATA_DIR /)
set(DESKTOP_FILE_NAME ${PROJECT_NAME}.desktop)

# Manifest verarbeiten und installieren
configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES ${PROJECT_NAME}.apparmor DESTINATION ${DATA_DIR})
install(FILES assets/logo.svg DESTINATION assets)

# Ressourcen laden
qt5_add_resources(QT_RESOURCES qml/qml.qrc)
qt5_add_resources(QT_RESOURCES assets/assets.qrc)

# Das ausführbare Programm erstellen
add_executable(${PROJECT_NAME} main.cpp ${QT_RESOURCES})
set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS_RELEASE -s)

# WICHTIG: Hier übergeben wir die Suchpfade für den Content-Hub UND für Qt5DBus an den Compiler
target_include_directories(${PROJECT_NAME} PRIVATE 
    ${CONTENT_HUB_INCLUDE_DIRS}
)

# Bibliotheken sauber verlinken. Qt5::DBus injiziert hierbei die Pfade für die Header
target_link_libraries(${PROJECT_NAME} 
    Qt5::Core
    Qt5::Gui 
    Qt5::Qml 
    Qt5::Quick 
    Qt5::QuickControls2 
    Qt5::DBus
    ${CONTENT_HUB_LIBRARIES}
)

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX})

# Übersetzungen (Translations)
file(GLOB_RECURSE I18N_SRC_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/po qml/*.qml qml/*.js)
list(APPEND I18N_SRC_FILES ${DESKTOP_FILE_NAME}.in.h)

find_program(INTLTOOL_MERGE intltool-merge)
if(NOT INTLTOOL_MERGE)
    message(FATAL_ERROR "Could not find intltool-merge, please install the intltool package")
endif()
find_program(INTLTOOL_EXTRACT intltool-extract)
if(NOT INTLTOOL_EXTRACT)
    message(FATAL_ERROR "Could not find intltool-extract, please install the intltool package")
endif()

add_custom_target(${DESKTOP_FILE_NAME} ALL
    COMMENT "Merging translations into ${DESKTOP_FILE_NAME}..."
    COMMAND LC_ALL=C ${INTLTOOL_MERGE} -d -u ${CMAKE_SOURCE_DIR}/po ${CMAKE_SOURCE_DIR}/${DESKTOP_FILE_NAME}.in ${DESKTOP_FILE_NAME}
    COMMAND sed -i 's/${PROJECT_NAME}-//g' ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE_NAME}
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${DESKTOP_FILE_NAME} DESTINATION ${DATA_DIR})
install(FILES ${PROJECT_NAME}-contenthub.json DESTINATION ${DATA_DIR})

add_subdirectory(po)
add_subdirectory(plugins)

# Sichtbarkeit in QtCreator erhalten
file(GLOB_RECURSE PROJECT_SRC_FILES
    RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}
    qml/*.qml
    qml/*.js
    src/*
    *.json
    *.json.in
    *.apparmor
    *.desktop.in
)

add_custom_target(${PROJECT_NAME}_FILES ALL SOURCES ${PROJECT_SRC_FILES})
