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
        .method("getConstraintNumber", &SDPA::getConstraintNumber)
        .method("inputBlockNumber", &SDPA::inputBlockNumber)
        .method("getBlockNumber", &SDPA::getBlockNumber)
        .method("inputBlockSize", &SDPA::inputBlockSize)
        .method("getBlockSize", &SDPA::getBlockSize)
        .method("inputBlockType", &SDPA::inputBlockType)
        .method("getBlockType", &SDPA::getBlockType)
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
        //.method("getResultXMat", &SDPA::getResultXMat)
        .method("getResultXVec", &SDPA::getResultXVec)
        //.method("getResultYMat", &SDPA::getResultYMat)
        .method("terminate", &SDPA::terminate);


JULIA_CPP_MODULE_END
