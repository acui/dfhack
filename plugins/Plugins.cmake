IF(UNIX)
    add_definitions(-DLINUX_BUILD)
    SET(CMAKE_CXX_FLAGS_DEBUG "-g -Wall")
    SET(CMAKE_CXX_FLAGS "-fvisibility=hidden -m32 -std=c++0x")
    SET(CMAKE_C_FLAGS "-fvisibility=hidden -m32")
ENDIF()

include_directories("${dfhack_SOURCE_DIR}/library/include")
include_directories("${dfhack_SOURCE_DIR}/library/proto")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/proto")
include_directories("${dfhack_SOURCE_DIR}/library/depends/xgetopt")

MACRO(CAR var)
  SET(${var} ${ARGV1})
ENDMACRO()

MACRO(CDR var junk)
  SET(${var} ${ARGN})
ENDMACRO()

MACRO(LIST_CONTAINS var value)
  SET(${var})
  FOREACH (value2 ${ARGN})
    IF (${value} STREQUAL ${value2})
      SET(${var} TRUE)
    ENDIF()
  ENDFOREACH()
ENDMACRO()

MACRO(PARSE_ARGUMENTS prefix arg_names option_names)
  SET(DEFAULT_ARGS)
  FOREACH(arg_name ${arg_names})
    SET(${prefix}_${arg_name})
  ENDFOREACH()

  FOREACH(option ${option_names})
    SET(${prefix}_${option} FALSE)
  ENDFOREACH()

  SET(current_arg_name DEFAULT_ARGS)
  SET(current_arg_list)
  FOREACH(arg ${ARGN})
    LIST_CONTAINS(is_arg_name ${arg} ${arg_names})
    IF (is_arg_name)
      SET(${prefix}_${current_arg_name} ${current_arg_list})
      SET(current_arg_name ${arg})
      SET(current_arg_list)
    ELSE()
      LIST_CONTAINS(is_option ${arg} ${option_names})
      IF(is_option)
        SET(${prefix}_${arg} TRUE)
      ELSE()
        SET(current_arg_list ${current_arg_list} ${arg})
      ENDIF()
    ENDIF()
  ENDFOREACH()
  SET(${prefix}_${current_arg_name} ${current_arg_list})
ENDMACRO()

MACRO(DFHACK_PLUGIN)
  PARSE_ARGUMENTS(PLUGIN
    "LINK_LIBRARIES;DEPENDS;PROTOBUFS"
    "SOME_OPT"
    ${ARGN}
    )
  CAR(PLUGIN_NAME ${PLUGIN_DEFAULT_ARGS})
  CDR(PLUGIN_SOURCES ${PLUGIN_DEFAULT_ARGS})

  FOREACH(pbuf ${PLUGIN_PROTOBUFS})
    SET(PLUGIN_SOURCES ${PLUGIN_SOURCES} ${CMAKE_CURRENT_SOURCE_DIR}/proto/${pbuf}.pb.cc)
  ENDFOREACH()

  ADD_LIBRARY(${PLUGIN_NAME} MODULE ${PLUGIN_SOURCES})
  IDE_FOLDER(${PLUGIN_NAME} "Plugins")

  LIST(LENGTH PLUGIN_PROTOBUFS NUM_PROTO)
  IF(NUM_PROTO)
    TARGET_LINK_LIBRARIES(${PLUGIN_NAME} dfhack protobuf-lite ${PLUGIN_LINK_LIBRARIES})
    IF(UNIX)
      SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES COMPILE_FLAGS "-include Export.h")
    ELSE()
      SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES COMPILE_FLAGS "/FI\"Export.h\"")
    ENDIF()
  ELSE()
    TARGET_LINK_LIBRARIES(${PLUGIN_NAME} dfhack ${PLUGIN_LINK_LIBRARIES})
  ENDIF()

  IF(UNIX)
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES SUFFIX .plug.so PREFIX "")
  ELSE()
    SET_TARGET_PROPERTIES(${PLUGIN_NAME} PROPERTIES SUFFIX .plug.dll)
  ENDIF()

  install(TARGETS ${PLUGIN_NAME}
          LIBRARY DESTINATION ${DFHACK_PLUGIN_DESTINATION}
          RUNTIME DESTINATION ${DFHACK_PLUGIN_DESTINATION})
ENDMACRO(DFHACK_PLUGIN)