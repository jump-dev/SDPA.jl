#include <cxx_wrap.hpp>
#include <sdpa_call.h>

std::string greet()
{
   return "hello, world";
}

namespace cxx_wrap
{
  template<> struct IsBits<SDPA::ConeType> : std::true_type {};
}

JULIA_CPP_MODULE_BEGIN(registry)

    cxx_wrap::Module& sdpa = registry.create_module("SDPA");
    sdpa.method("greet", &greet);

    sdpa.add_bits<SDPA::ConeType>("ConeType");
    sdpa.set_const("SDP", SDPA::SDP);
    sdpa.set_const("SOCP", SDPA::SOCP);
    sdpa.set_const("LP", SDPA::LP);

    sdpa.add_type<SDPA>("SDPAProblem")
        .method("inputConstraintNumber", &SDPA::inputConstraintNumber)
        .method("inputBlockNumber", &SDPA::inputBlockNumber)
        .method("inputBlockSize", &SDPA::inputBlockSize)
        .method("inputBlockType", &SDPA::inputBlockType)
        .method("initializeUpperTriangleSpace", &SDPA::initializeUpperTriangleSpace)
        .method("inputCVec", &SDPA::inputCVec)
        .method("inputElement", &SDPA::inputElement)
        .method("initializeUpperTriangle", &SDPA::initializeUpperTriangle)
        .method("initializeSolve", &SDPA::initializeSolve)
        .method("solve", &SDPA::solve)
        .method("getIteration", &SDPA::getIteration)
        .method("getPrimalObj", &SDPA::getPrimalObj)
        .method("getDualObj", &SDPA::getDualObj)
        .method("getPrimalError", &SDPA::getPrimalError)
        .method("getDualError", &SDPA::getDualError)
        .method("terminate", &SDPA::terminate);


JULIA_CPP_MODULE_END
