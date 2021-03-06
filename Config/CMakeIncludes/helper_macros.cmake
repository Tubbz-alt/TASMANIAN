########################################################################
# Various CMake macros to be used by Tasmanian
########################################################################

# CMake native includes used in Tasmanian CMake scripts
include(FindPackageHandleStandardArgs)
include(CMakePackageConfigHelpers)

# usage: Tasmanian_find_libraries(REQUIRED foo1 foo2 OPTIONAL foo3 PREFIX bar LIST saloon NO_DEFAULT_PATH)
# this will search for foo1/2/3 in bar/<lib/lib64/arch> with NO_DEFAULT_PATH (skip if defaults are to be used)
# the found libraries will be added to a list Tasmanian_saloon
# the search results will be also added to cached variables Tasmanian_foo1 and Tasmanian_foo2
# that can be used to call find_package_handle_standard_args(... DEFAULT_MSG Tasmanian_foo1 Tasmanian_foo2)
# the macro will not call find_package_handle_standard_args()
# the optional libraries will not create cached entries and mission optional will not be added to the LIST
macro(Tasmanian_find_libraries)
    cmake_parse_arguments(Tasmanian_findlibs "NO_DEFAULT_PATH" "PREFIX;LIST" "REQUIRED;OPTIONAL" ${ARGN})

    foreach(_tsg_lib ${Tasmanian_findlibs_REQUIRED})
        list(APPEND Tasmanian_findlibs_required "Tasmanian_${_tsg_lib}")
    endforeach()

    set(Tasmanian_findlibs_default "")
    if (${Tasmanian_findlibs_NO_DEFAULT_PATH})
        set(Tasmanian_findlibs_default "NO_DEFAULT_PATH")
    endif()

    foreach(_tsg_lib ${Tasmanian_findlibs_REQUIRED} ${Tasmanian_findlibs_OPTIONAL})

        find_library(Tasmanian_${_tsg_lib} ${_tsg_lib}
                     HINTS "${Tasmanian_findlibs_PREFIX}"
                     HINTS "${Tasmanian_findlibs_PREFIX}/lib/"
                     HINTS "${Tasmanian_findlibs_PREFIX}/lib/intel64"
                     HINTS "${Tasmanian_findlibs_PREFIX}/${CMAKE_LIBRARY_ARCHITECTURE}/lib/"
                     HINTS "${Tasmanian_findlibs_PREFIX}/lib/${CMAKE_LIBRARY_ARCHITECTURE}"
                     HINTS "${Tasmanian_findlibs_PREFIX}/lib64/"
                     HINTS "${Tasmanian_findlibs_PREFIX}/${CMAKE_LIBRARY_ARCHITECTURE}/lib64/"
                     HINTS "${Tasmanian_findlibs_PREFIX}/lib64/${CMAKE_LIBRARY_ARCHITECTURE}"
                     ${Tasmanian_findlibs_default})

        if (CMAKE_FIND_DEBUG_MODE)
            message(STATUS "Tasmanian searching library: ${_tsg_lib} => ${Tasmanian_${_tsg_lib}}")
        endif()

        list(FIND Tasmanian_findlibs_required "Tasmanian_${_tsg_lib}" Tasmanian_findlibs_is_required)
        if (${Tasmanian_findlibs_is_required} EQUAL -1) # not a required library
            if (Tasmanian_${_tsg_lib})
                list(APPEND Tasmanian_${Tasmanian_findlibs_LIST} ${Tasmanian_${_tsg_lib}})
            endif()
            unset(Tasmanian_${_tsg_lib} CACHE)
        else()
            list(APPEND Tasmanian_${Tasmanian_findlibs_LIST} ${Tasmanian_${_tsg_lib}})
        endif()

    endforeach()

    foreach(_tsg_lib default required NO_DEFAULT_PATH PREFIX LIST REQUIRED OPTIONAL) # cleanup
        unset(Tasmanian_${_tsg_lib})
    endforeach()
    unset(_tsg_lib)
endmacro()

# usage: Tasmanian_find_header(FILE foo.h RESULT foo_h ROOT bar HINT saloon NO_DEFAULT_PATH)
# will search for file named foo.h and will add the folder in variable Tasmanian_foo_h
# NO_DEFAULT_PATH defines whether to use NO_DEFAULT_PATH in the find_path() command
# in addition to the default paths, the method will search for folders bar and bar/include
# as well as saloon_dir, saloon_dir/include, saloon_dir/../include and saloon_dir/../../include
# where saloon_dir is the directory of the file saloon
macro(Tasmanian_find_header)
    cmake_parse_arguments(Tasmanian_findh "NO_DEFAULT_PATH" "FILE;ROOT;HINT;RESULT" "" ${ARGN})

    if (Tasmanian_findh_HINT)
        get_filename_component(Tasmanian_findh_dir ${Tasmanian_findh_HINT} DIRECTORY)
    endif()

    set(Tasmanian_findh_default "")
    if (${Tasmanian_findh_NO_DEFAULT_PATH})
        set(Tasmanian_findh_default "NO_DEFAULT_PATH")
    endif()

    find_path(Tasmanian_${Tasmanian_findh_RESULT} "${Tasmanian_findh_FILE}"
              HINTS "${Tasmanian_findh_ROOT}"
              HINTS "${Tasmanian_findh_ROOT}/include"
              HINTS "${Tasmanian_findh_dir}"
              HINTS "${Tasmanian_findh_dir}/include"
              HINTS "${Tasmanian_findh_dir}/../include"
              HINTS "${Tasmanian_findh_dir}/../../include"
              ${Tasmanian_findh_default})

    if (CMAKE_FIND_DEBUG_MODE)
        message(STATUS "Tasmanian searching header: ${Tasmanian_findh_FILE} => ${Tasmanian_${Tasmanian_findh_RESULT}}")
    endif()

    foreach(_tsg_opts dir default NO_DEFAULT_PATH FILE ROOT HINT RESULT) # cleanup
        unset(Tasmanian_${_tsg_opts})
    endforeach()
    unset(_tsg_opts)
endmacro()

# usage: Tasmanian_find_rpath(LIBRARIES ${BLAS_LIBRARIES} LIST rpath)
# will find the rpaths for each library in the BLAS_LIBRARIES list
# and will append the rpath to a list called Tasmanian_rpath
macro(Tasmanian_find_rpath)
    cmake_parse_arguments(Tasmanian_findrpath "" "LIST" "LIBRARIES" ${ARGN})

    foreach(_tsg_lib ${Tasmanian_findrpath_LIBRARIES})
        get_filename_component(_tsg_libpath ${_tsg_lib} DIRECTORY)
        list(APPEND Tasmanian_${Tasmanian_findrpath_LIST} ${_tsg_libpath})
        #message(STATUS "rpath for ${_tsg_lib} => ${_tsg_libpath}")
    endforeach()

    foreach(_tsg_lib LIST LIBRARIES) # cleanup
        unset(Tasmanian_${_tsg_lib})
    endforeach()
    unset(_tsg_lib)
    unset(_tsg_libpath)
endmacro()
