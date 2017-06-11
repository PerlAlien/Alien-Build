#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "lzma.h"

MODULE = LZMA::Example PACKAGE = LZMA::Example

const char *
lzma_version_string()
