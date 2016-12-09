#include <cxx_wrap.hpp>

std::string greet()
{
   return "hello, world";
}

JULIA_CPP_MODULE_BEGIN(registry)
    cxx_wrap::Module& sdpa = registry.create_module("SDPA");
    sdpa.method("greet", &greet);
JULIA_CPP_MODULE_END
