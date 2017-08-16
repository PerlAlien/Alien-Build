add_executable (palx main.c)
target_link_libraries (palx LINK_PUBLIC palindromeStatic)
install(TARGETS palx RUNTIME DESTINATION bin)
