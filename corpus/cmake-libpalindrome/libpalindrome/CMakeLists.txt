add_library (palindrome SHARED palindrome.c)
add_library (palindromeStatic palindrome.c)
target_include_directories (palindrome PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories (palindromeStatic PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

IF (WIN32 OR CYGWIN OR MINGW)
ELSE()
  set_target_properties(palindromeStatic PROPERTIES OUTPUT_NAME palindrome)
ENDIF()

IF (WIN32 OR CYGWIN OR MINGW)
  install(TARGETS palindrome RUNTIME DESTINATION bin)
ELSE()
  install(TARGETS palindrome LIBRARY DESTINATION lib)
ENDIF()

install(TARGETS palindromeStatic ARCHIVE DESTINATION lib)
install(FILES libpalindrome.h DESTINATION include)
