#include "greeenboii.h"

VALUE rb_mGreeenboii;

RUBY_FUNC_EXPORTED void
Init_greeenboii(void)
{
  rb_mGreeenboii = rb_define_module("Greeenboii");
}
