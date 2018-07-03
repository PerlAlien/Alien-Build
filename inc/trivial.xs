#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Trivial::XS PACKAGE = Trivial::XS

int
answer()
    CODE:
      RETVAL = 42;
    OUTPUT:
      RETVAL
