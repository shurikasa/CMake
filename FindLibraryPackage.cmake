#
# Copyright 2011-2012 Stefan Eilemann <eile@eyescale.ch>
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#  - Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#  - Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#  - Neither the name of Eyescale Software GmbH nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE.
#
#==================================
#
# Module to find a standard library and includes. Intended to be used by
# FindFoo.cmake scripts. Assumes the following layout:
#   (root)/include/(name)/version.h
#      parsed for defines: NAME_VERSION_MAJOR, -_MINOR, -_PATCH, -_ABI
#
#
#==================================
#
# Invocation:
#
# find_library_package(name [QUIET] [REQUIRED] [VERSION version [EXACT]])
#
# The following CMAKE and environment variables are respected for
# finding the package. CMAKE_PREFIX_PATH can also be used for this
# (see find_library() CMake documentation):
#
#    NAME_ROOT
#
# This macro defines the following output variables:
#
#    NAME_FOUND - Was library and headers found?
#
#    NAME_VERSION - The version found
#
#    NAME_INCLUDE_DIRS - Where to find the headers
#
#    NAME_LIBRARIES - The libraries
#
#    NAME_LIBRARY_DIRS - Where to find the libraries
#
#==================================
# Example Usage:
#
#  find_library_package(Lunchbox VERSION 1.0.0 REQUIRED)
#  find_package_handle_standard_args(Lunchbox DEFAULT_MSG
#                                    LUNCHBOX_LIBRARIES LUNCHBOX_INCLUDE_DIRS)
#
#==================================
# Naming convention:
#  Local variables of the form _flp_foo

#
# find and parse name/version.h
include(CMakeParseArguments)

macro(FIND_LIBRARY_PACKAGE name)
  # reset internal variables
  set(_flp_EPIC_FAIL)
  set(_flp_REQUIRED)
  set(_flp_QUIET)
  set(_flp_output)

  # options
  set(options REQUIRED EXACT)
  set(oneValueArgs VERSION)
  set(multiValueArgs)
  cmake_parse_arguments(_flp "${options}" "${oneValueArgs}" "${multiValueArgs}"
    ${ARGN} )

  string(TOUPPER ${name} NAME)

  find_path(${NAME}_INCLUDE_DIR ${name}/version.h
    HINTS "${${NAME}_ROOT}/include" "$ENV{${NAME}_ROOT}/include"
    PATHS /usr/include /usr/local/include /opt/local/include /opt/include)

  if(_flp_REQUIRED)
    set(_flp_version_output_type FATAL_ERROR)
    set(_flp_output 1)
  else()
    set(_flp_version_output_type STATUS)
    if(NOT _flp_QUIET)
      set(_flp_output 1)
    endif()
  endif()

  # Try to ascertain the version...
  if(${NAME}_INCLUDE_DIR)
    set(_flp_Version_file "${${NAME}_INCLUDE_DIR}/${name}/version.h")
    if("${${NAME}_INCLUDE_DIR}" MATCHES "\\.framework$" AND
        NOT EXISTS "${_flp_Version_file}")
      set(_flp_Version_file "${${NAME}_INCLUDE_DIR}/Headers/version.h")
    endif()

    if(EXISTS "${_flp_Version_file}")
      file(READ "${_flp_Version_file}" _flp_Version_contents)
    else()
      set(_flp_Version_contents "unknown")
    endif()

    string(REGEX MATCH ".*define ${NAME}_VERSION_MAJOR[ \t]+[0-9]+.*"
      ${NAME}_VERSION_MAJOR ${_flp_Version_contents})
    string(REGEX MATCH ".*define ${NAME}_VERSION_MINOR[ \t]+[0-9]+.*"
      ${NAME}_VERSION_MINOR ${_flp_Version_contents})
    string(REGEX MATCH ".*define ${NAME}_VERSION_PATCH[ \t]+[0-9]+.*"
      ${NAME}_VERSION_PATCH ${_flp_Version_contents})
    string(REGEX MATCH ".*define ${NAME}_VERSION_ABI[ \t]+[0-9]+.*"
      ${NAME}_VERSION_ABI ${_flp_Version_contents})

    if("${NAME}_VERSION_MAJOR" STREQUAL "")
      set(_flp_EPIC_FAIL TRUE)
      if(_flp_output)
        message(${_flp_version_output_type} "Can't parse ${_flp_Version_file}.")
      endif()
    else()
      string(REGEX REPLACE "([0-9]+)" "\\1" ${NAME}_VERSION_MAJOR
        ${${NAME}_VERSION_MAJOR})

      if("${NAME}_VERSION_MINOR" STREQUAL "")
        set(${NAME}_VERSION_MINOR 0)
      else()
        string(REGEX REPLACE "([0-9]+)" "\\1" ${NAME}_VERSION_MINOR
          ${${NAME}_VERSION_MINOR})
      endif()
      if("${NAME}_VERSION_PATCH" STREQUAL "")
        set(${NAME}_VERSION_PATCH 0)
      else()
        string(REGEX REPLACE "([0-9]+)" "\\1" ${NAME}_VERSION_PATCH
          ${${NAME}_VERSION_PATCH})
      endif()
      if("${NAME}_VERSION_ABI" STREQUAL "")
        set(${NAME}_VERSION_ABI 0)
      else()
        string(REGEX REPLACE "([0-9]+)" "\\1" ${NAME}_VERSION_ABI
          ${${NAME}_VERSION_ABI})
      endif()

      set(${NAME}_VERSION "${${NAME}_VERSION_MAJOR}.${${NAME}_VERSION_MINOR}.${${NAME}_VERSION_PATCH}")
    endif()
  else()
    set(_flp_EPIC_FAIL TRUE)
    if(_flp_output)
      message(${_flp_version_output_type} "Can't find ${name}/version.h.")
    endif()
  endif()

  # Version checking
  if(_flp_VERSION AND ${NAME}_VERSION)
    if(_flp_EXACT)
      if(NOT ${NAME}_VERSION VERSION_EQUAL _flp_VERSION})
        set(_flp_EPIC_FAIL TRUE)
        if(_flp_output)
          message(${_flp_version_output_type}
            "Version _flp_VERSION} of ${name} is required exactly. "
            "Version ${${NAME}_VERSION} was found.")
        endif()
    else()
      if( NOT ${NAME}_VERSION VERSION_EQUAL _flp_VERSION} AND 
          NOT ${NAME}_VERSION VERSION_GREATER _flp_VERSION} )
        set(_flp_EPIC_FAIL TRUE)
        if(_flp_output)
          message(${_flp_version_output_type}
            "Version ${_flp_VERSION} or higher of ${name} is required. "
            "Version ${${NAME}_VERSION} was found in ${${NAME}_INCLUDE_DIR}.")
        endif()
      endif()
    endif()
  endif()

  # include
  set(${NAME}_INCLUDE_DIRS ${${NAME}_INCLUDE_DIR})

  # library
  find_library(${NAME}_LIBRARY ${name}
    PATHS ${${NAME}_INCLUDE_DIR}/.. PATH_SUFFIXES lib NO_DEFAULT_PATH)
  set(${NAME}_LIBRARIES ${${NAME}_LIBRARY})

  if(_flp_REQUIRED)
    if(${NAME}_LIBRARY MATCHES "${NAME}_LIBRARY-NOTFOUND")
      set(_flp_EPIC_FAIL TRUE)
      if(_flp_output)
        message(${_flp_version_output_type}
          "ERROR: Missing the ${name} library.\n"
          "Consider using CMAKE_PREFIX_PATH or the ${NAME}_ROOT variable. "
          "See ${CMAKE_CURRENT_LIST_FILE} for more details.")
      endif()
    endif()
  endif()

  if(_flp_EPIC_FAIL)
    # Zero out everything, we didn't meet version requirements
    set(${NAME}_FOUND)
    set(${NAME}_LIBRARIES)
    set(${NAME}_INCLUDE_DIRS)
  else()
    get_filename_component(${NAME}_LIBRARY_DIRS ${${NAME}_LIBRARY} PATH)

    if(${NAME}_FOUND AND _flp_output)
      message(STATUS "Found ${name} ${${NAME}_VERSION} in "
        "${${NAME}_INCLUDE_DIRS}:${${NAME}_LIBRARIES}")
    endif()
  endif()
endmacro()