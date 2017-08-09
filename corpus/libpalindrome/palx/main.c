#include <libpalindrome.h>

int
main(int argc, char *argv[])
{
  /*
   * If we do not have EXACTLY one argument,
   * return a usage error.
   */
  if(argc != 2)
    return 1;

  if(is_palindrome(argv[1]))
    return 0;
  else
    return 2;
}
