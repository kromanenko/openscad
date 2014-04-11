#
# CMake Toolchain file for cross compiling OpenSCAD tests linux->mingw-win32
# --------------------------------------------------------------------------
#
# This CMake Toolchain file will cross-compile the regression test 
# programs for OpenSCAD, and generate a CTestTestfile.cmake
#
# The result will not be directly usable. Please see doc/testing.txt
# for complete instructions for running the regression tests under Windows(TM) 
# 
# Prerequisites:
# 
# Please see doc/testing.txt for pre-requisites.
#
# Usage:
#
# Please see doc/testing.txt for usage
#
# Please do not use this file directly unless you are experimenting. 
# This file is typically called from release-common.sh automatically, 
# not used directly by a human.
#
# Assuming you want to build 64bit:
# 
# cd openscad
# source scripts/setenv-mingw-xbuild.sh 64
# cd openscad/tests && mkdir build-mingw64 && cd build-mingw64
# export OPENSCADPATH=../../libraries # (to find MCAD for some tests)
# cmake .. -DCMAKE_TOOLCHAIN_FILE=../CMingw-cross-env.cmake \
#          -DMINGW_CROSS_ENV_DIR=$MXEDIR \
#          -DMACHINE=x86_64-w64-mingw32
#
# For 32 bit, change '64' to '32' in setenv/mkdir and use this machine:
#          -DMACHINE=i686-pc-mingw32
#
# make # (should proceed as normal.)
#
# See also:
# 
# http://lists.gnu.org/archive/html/mingw-cross-env-list/2010-11/threads.html#00078
#  (thread "Qt with Cmake")
# http://lists.gnu.org/archive/html/mingw-cross-env-list/2011-01/threads.html#00012
#  (thread "Qt: pkg-config files?")
# http://mingw-cross-env.nongnu.org/#requirements
# http://www.vtk.org/Wiki/CMake_Cross_Compiling
# https://bitbucket.org/muellni/mingw-cross-env-cmake/src/2067fcf2d52e/src/cmake-1-toolchain-file.patch
# http://code.google.com/p/qtlobby/source/browse/trunk/toolchain-mingw.cmake
# http://gcc.gnu.org/onlinedocs/gcc-3.4.6/gcc/Link-Options.html
# Makefile.Release generated by qmake 
# cmake's FindQt4.cmake & Qt4ConfigDependentSettings.cmake files
# mingw-cross-env's qmake.conf and *.prl files
# mingw-cross-env's pkg-config files in usr/${MACHINE}/lib/pkgconfig
# (may have to add to env var PKG_CONFIG_PATH to find qt .pc files)
# http://www.vtk.org/Wiki/CMake:How_To_Find_Libraries
#

#
# Notes: 
#
# To debug the build process run "make VERBOSE=1". 'strace -f' is also useful. 
#
# This file is actually called multiple times by cmake, so various 'if NOT set' 
# guards are used to keep programs from running twice.
#

#
# Part 1: Skip imagemagick search.
#

set( SKIP_IMAGEMAGICK TRUE )

#
# Part 2. cross-compiler setup
#

message(STATUS "Machine: ${MACHINE}")

set(MINGW_CROSS_ENV_DIR $ENV{MINGW_CROSS_ENV_DIR})

set(BUILD_SHARED_LIBS OFF)
set(CMAKE_SYSTEM_NAME Windows)
set(MSYS 1)
set(CMAKE_FIND_ROOT_PATH ${MINGW_CROSS_ENV_DIR}/usr/${MACHINE})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)

set(CMAKE_C_COMPILER ${MINGW_CROSS_ENV_DIR}/usr/bin/${MACHINE}-gcc)
set(CMAKE_CXX_COMPILER ${MINGW_CROSS_ENV_DIR}/usr/bin/${MACHINE}-g++)
set(CMAKE_RC_COMPILER ${MINGW_CROSS_ENV_DIR}/usr/bin/${MACHINE}-windres)
set(QT_QMAKE_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/${MACHINE}-qmake)
set(PKG_CONFIG_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/${MACHINE}-pkg-config)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

#
# Part 3. library settings for mingw-cross-env
#

set( Boost_USE_STATIC_LIBS ON )
set( Boost_USE_MULTITHREADED ON )
set( Boost_COMPILER "_win32" )
# set( Boost_DEBUG TRUE ) # for debugging cmake's FindBoost, not boost itself

set( OPENSCAD_LIBRARIES ${CMAKE_FIND_ROOT_PATH} )
set( EIGEN2_DIR ${CMAKE_FIND_ROOT_PATH} )
set( CGAL_DIR ${CMAKE_FIND_ROOT_PATH}/lib/CGAL )
set( GLEW_DIR ${CMAKE_FIND_ROOT_PATH} )

#
# Qt4
# 
# To workaround problems with CMake's FindQt4.cmake when combined with 
# mingw-cross-env (circa early 2012), we here instead use pkg-config. To 
# workaround Cmake's insertion of -bdynamic, we stick 'static' on the 
# end of QT_LIBRARIES
#

set(QT_QMAKE_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/${MACHINE}-qmake)
set(QT_MOC_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/${MACHINE}-moc)
set(QT_UIC_EXECUTABLE ${MINGW_CROSS_ENV_DIR}/usr/bin/${MACHINE}-uic)

function(mingw_cross_env_find_qt)
  # called from CMakeLists.txt
  set(PKGC_DEST ${MINGW_CROSS_ENV_DIR}/usr/${MACHINE}/lib/pkgconfig)
  set(QT_PKGC_SRC ${MINGW_CROSS_ENV_DIR}/usr/${MACHINE}/qt/lib/pkgconfig/)
  file(COPY ${QT_PKGC_SRC} DESTINATION ${PKGC_DEST} FILES_MATCHING PATTERN "*.pc")

  find_package( PkgConfig )
  pkg_check_modules( QTCORE QtCore )
  pkg_check_modules( QTGUI QtGui )
  pkg_check_modules( QTOPENGL QtOpenGL )

  set(QT_INCLUDE_DIRS ${QTCORE_INCLUDE_DIRS} ${QTGUI_INCLUDE_DIRS} ${QTOPENGL_INCLUDE_DIRS})
  set(QT_CFLAGS_OTHER "${QTCORE_CFLAGS_OTHER} ${QTGUI_CFLAGS_OTHER} ${QTOPENGL_CFLAGS_OTHER}")
  set(QT_LIBRARIES "${QTCORE_STATIC_LDFLAGS} ${QTGUI_STATIC_LDFLAGS} ${QTOPENGL_STATIC_LDFLAGS};-static")

  set(QT_INCLUDE_DIRS ${QT_INCLUDE_DIRS} PARENT_SCOPE)
  set(QT_CFLAGS_OTHER ${QT_CFLAGS_OTHER} PARENT_SCOPE)
  set(QT_LIBRARIES ${QT_LIBRARIES} PARENT_SCOPE)
endfunction()

function(mingw_cross_env_info)
  message(STATUS "QT INCLUDE_DIRS: ${QT_INCLUDE_DIRS}")
  message(STATUS "QT LIBRARIES: ${QT_LIBRARIES}")
  message(STATUS "QT_CFLAGS_OTHER: ${QT_CFLAGS_OTHER}")
endfunction()

#
# Part 4. -D definitions
#

if( NOT cross_defs_set )
  add_definitions( -DGLEW_STATIC ) # FindGLEW.cmake needs this
  add_definitions( -DBOOST_STATIC ) 
  add_definitions( -DBOOST_THREAD_USE_LIB )
  add_definitions( -DUNICODE ) # because qmake does it
  set(cross_defs_set 1)
endif()

#
# Part 5. Fill the ctest_cross_info.py.template into ctest_cross_info.py
# 

function(mingw_cross_fill_ctest_template)
  file(READ ${CMAKE_CURRENT_SOURCE_DIR}/ctest_cross_info.py.template TMP)
  string(REPLACE __cmake_current_binary_dir__ ${CMAKE_CURRENT_BINARY_DIR} TMP ${TMP})
  string(REPLACE __cmake_current_source_dir__ ${CMAKE_CURRENT_SOURCE_DIR} TMP ${TMP})
  string(REPLACE __python_exec__ ${PYTHON_EXECUTABLE} TMP ${TMP})
  string(REPLACE __header__ "Generated by cmake from ${CMAKE_CURRENT_SOURCE_DIR}/ctest_cross_info.py.template" TMP ${TMP})
  string(REPLACE __test_cmdline_tool__ "${tests_SOURCE_DIR}/test_cmdline_tool.py" TMP ${TMP})
  string(REPLACE __cmake_system_name__ ${CMAKE_SYSTEM_NAME} TMP ${TMP})
  string(REPLACE __openscad_binpath__ ${OPENSCAD_BINPATH} TMP ${TMP})
  string(REPLACE __convert_exec__ ${ImageMagick_convert_EXECUTABLE} TMP ${TMP})
  message(STATUS "creating ctest_cross_info.py from ctest_cross_info.py.template")
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/ctest_cross_info.py ${TMP})
endfunction()

