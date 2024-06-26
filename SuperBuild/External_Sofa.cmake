set(proj Sofa)

# Set dependency list
set(${proj}_DEPENDS
  Boost
  Eigen3
  GLEW
  TinyXML2
  pybind11
  OpenIGTLink
  )

# Include dependent projects if any
ExternalProject_Include_Dependencies(${proj} PROJECT_VAR proj)

if(${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${proj})
  message(FATAL_ERROR "Enabling ${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${proj} is not supported !")
endif()

# Sanity checks
if(DEFINED SOFA_DIR AND NOT EXISTS ${SOFA_DIR})
  message(FATAL_ERROR "SOFA_DIR [${SOFA_DIR}] variable is defined but corresponds to nonexistent directory")
endif()

if(NOT DEFINED ${proj}_DIR AND NOT ${SUPERBUILD_TOPLEVEL_PROJECT}_USE_SYSTEM_${proj})

  set(SOFA_EXTERNAL_DIRECTORIES)

  include(FetchContent)

  # SofaIGTLink
  set(plugin_name "SofaIGTLink")
  set(${plugin_name}_SOURCE_DIR "${CMAKE_BINARY_DIR}/${plugin_name}")
  FetchContent_Populate(${plugin_name}
    SOURCE_DIR     ${${plugin_name}_SOURCE_DIR}
    GIT_REPOSITORY "https://github.com/sofa-framework/SofaIGTLink.git"
    GIT_TAG        "055351b5532a2d273b43121c23d1e715855f7d0d" # master-20240423
    GIT_PROGRESS   1
    QUIET
    )
  list(APPEND SOFA_EXTERNAL_DIRECTORIES ${${plugin_name}_SOURCE_DIR})
  ExternalProject_Message(${proj} "${plugin_name} sources [OK]")

  # SofaPython3
  set(plugin_name "SofaPython3")
  set(${plugin_name}_SOURCE_DIR "${CMAKE_BINARY_DIR}/${plugin_name}")
  FetchContent_Populate(${plugin_name}
    SOURCE_DIR     ${${plugin_name}_SOURCE_DIR}
    GIT_REPOSITORY "https://github.com/sofa-framework/SofaPython3.git"
    GIT_TAG        "1972c51819b6eb5ac1bbc479ff4e29f6f55f36f4" # v23.12-20240313
    GIT_PROGRESS   1
    QUIET
    )
  list(APPEND SOFA_EXTERNAL_DIRECTORIES ${${plugin_name}_SOURCE_DIR})
  ExternalProject_Message(${proj} "${plugin_name} sources [OK]")

  # SofaSTLIB
  set(plugin_name "SofaSTLIB")
  set(${plugin_name}_SOURCE_DIR "${CMAKE_BINARY_DIR}/${plugin_name}")
  FetchContent_Populate(${plugin_name}
    SOURCE_DIR     ${${plugin_name}_SOURCE_DIR}
    GIT_REPOSITORY "https://github.com/SofaDefrost/STLIB.git"
    GIT_TAG        "41de3a79e9bb887db3e163eebb7ad3d40f3d31e8" # v23.12-20240313
    GIT_PROGRESS   1
    QUIET
    )
  list(APPEND SOFA_EXTERNAL_DIRECTORIES ${${plugin_name}_SOURCE_DIR})
  ExternalProject_Message(${proj} "${plugin_name} sources [OK]")

  set(EP_SOURCE_DIR ${CMAKE_BINARY_DIR}/${proj})
  set(EP_BINARY_DIR ${CMAKE_BINARY_DIR}/${proj}-build)

  ExternalProject_Add(${proj}
    ${${proj}_EP_ARGS}
    # Note: Update the repository URL and tag to match the correct SOFA version
    GIT_REPOSITORY "https://github.com/sofa-framework/sofa.git"
    GIT_TAG "2628b9f29cf3e082a514ca591f5a998bc3b0331d" #v24.06.00
    URL ${SOFA_URL}
    URL_HASH ${SOFA_URL_HASH}
    DOWNLOAD_DIR ${CMAKE_BINARY_DIR}/download
    SOURCE_DIR ${EP_SOURCE_DIR}
    BINARY_DIR ${EP_BINARY_DIR}
    CMAKE_CACHE_ARGS
      -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
      -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
      -DCMAKE_C_FLAGS:STRING=${ep_common_c_flags}
      -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
      -DCMAKE_CXX_FLAGS:STRING=${ep_common_cxx_flags}
      -DCMAKE_CXX_STANDARD:STRING=${CMAKE_CXX_STANDARD}
      -DCMAKE_CXX_STANDARD_REQUIRED:BOOL=${CMAKE_CXX_STANDARD_REQUIRED}
      -DCMAKE_CXX_EXTENSIONS:BOOL=${CMAKE_CXX_EXTENSIONS}
      -DSOFA_BUILD_TESTS:BOOL=${BUILD_TESTING}
      -DAPPLICATION_RUNSOFA:BOOL=ON
      -DAPPLICATION_SCENECHECKING:BOOL=ON
      -DCOLLECTION_SOFACONSTRAINT:BOOL=ON
      -DCOLLECTION_SOFAGENERAL:BOOL=ON
      -DCOLLECTION_SOFAGRAPHCOMPONENT:BOOL=ON
      -DCOLLECTION_SOFAGUI:BOOL=ON
      -DCOLLECTION_SOFAGUICOMMON:BOOL=ON
      -DCOLLECTION_SOFAGUIQT:BOOL=ON
      -DCOLLECTION_SOFAMISCCOLLISION:BOOL=ON
      -DCOLLECTION_SOFAUSERINTERACTION:BOOL=ON
      -DSOFA_GUI_QT_ENABLE_QDOCBROWSER:BOOL=OFF
      -DSOFA_INSTALL_RESOURCES_FILES:BOOL=OFF
      # Output directory
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH=${CMAKE_BINARY_DIR}/${Slicer_THIRDPARTY_BIN_DIR}
      -DCMAKE_LIBRARY_OUTPUT_DIRECTORY:PATH=${CMAKE_BINARY_DIR}/${Slicer_THIRDPARTY_LIB_DIR}
      -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH=${CMAKE_ARCHIVE_OUTPUT_DIRECTORY}
      -DSofaSTLIB_ENABLED:BOOL=ON
      -DLIBRARY_SOFA_GUI:BOOL=ON
      -DLIBRARY_SOFA_GUI_COMMON:BOOL=ON
      -DMODULE_SOFA_GUI_COMPONENT:BOOL=ON
      -DPLUGIN_SOFA_GUI_BATCH:BOOL=ON
      -DPLUGIN_SOFA_GUI_QT:BOOL=ON
      -DSOFA_ROOT:PATH=${EP_SOURCE_DIR}
      -DSOFA_WITH_OPENGL:BOOL=ON
      -DGLEW_DIR:PATH=${GLEW_DIR}
      -DBoost_INCLUDE_DIR:PATH=${Boost_DIR}/include
      -DEIGEN3_INCLUDE_DIR:PATH=${Eigen3_DIR}/include/eigen3
      -DTinyXML2_INCLUDE_DIR:PATH=${TinyXML2_DIR}/../TinyXML2
      -DTinyXML2_LIBRARY:PATH=${CMAKE_BINARY_DIR}/${Slicer_THIRDPARTY_LIB_DIR}/libtinyxml2.so.10
      -DSOFA_EXTERNAL_DIRECTORIES:STRING=${SOFA_EXTERNAL_DIRECTORIES}
      -DPYTHON_EXECUTABLE:FILEPATH=${PYTHON_EXECUTABLE}
      -DPython3_EXECUTABLE:FILEPATH=${PYTHON_EXECUTABLE}
      -DPython_EXECUTABLE:FILEPATH=${PYTHON_EXECUTABLE}
      -DPYTHON_LIBRARIES:FILEPATH=${PYTHON_LIBRARY}
      -DPYTHON_INCLUDE_DIRS:PATH=${PYTHON_INCLUDE_DIR}
      -Dpybind11_DIR:PATH=${pybind11_DIR}/share/cmake/pybind11
      -DOpenIGTLink_DIR:PATH=${OpenIGTLink_DIR}
    DEPENDS
      ${${proj}_DEPENDS}
    INSTALL_COMMAND ""
    )
  set(${proj}_DIR ${EP_BINARY_DIR})

  #-----------------------------------------------------------------------------
  # Launcher setting specific to build tree

  # library paths
  set(${proj}_LIBRARY_PATHS_LAUNCHER_BUILD
    ${${proj}_DIR}/lib
    # ${CMAKE_BINARY_DIR}/${Slicer_THIRDPARTY_BIN_DIR}
    # ${CMAKE_BINARY_DIR}/${Slicer_THIRDPARTY_BIN_DIR}/<CMAKE_CFG_INTDIR>
    )
  mark_as_superbuild(
    VARS ${proj}_LIBRARY_PATHS_LAUNCHER_BUILD
    LABELS "LIBRARY_PATHS_LAUNCHER_BUILD"
    )

  # python paths
  set(${proj}_PYTHONPATH_LAUNCHER_BUILD
    ${${proj}_DIR}/lib/python3/site-packages
    # ${CMAKE_BINARY_DIR}/${Slicer_THIRDPARTY_BIN_DIR}
    # ${CMAKE_BINARY_DIR}/${Slicer_THIRDPARTY_BIN_DIR}/<CMAKE_CFG_INTDIR>
    )
  mark_as_superbuild(
    VARS ${proj}_PYTHONPATH_LAUNCHER_BUILD
    LABELS "PYTHONPATH_LAUNCHER_BUILD"
    )

else()
  ExternalProject_Add_Empty(${proj} DEPENDS ${${proj}_DEPENDS})
endif()

mark_as_superbuild(${proj}_DIR:PATH)
