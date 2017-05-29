#include "jlcxx/jlcxx.hpp"
#include <sdpa_call.h>

namespace jlcxx
{
  template<> struct IsBits<SDPA::ConeType> : std::true_type {};
  template<> struct IsBits<SDPA::PhaseType> : std::true_type {};
}

JULIA_CPP_MODULE_BEGIN(registry)

    jlcxx::Module& sdpa = registry.create_module("SDPA");

    sdpa.add_bits<SDPA::ConeType>("ConeType");
    sdpa.set_const("SDP", SDPA::SDP);
    sdpa.set_const("SOCP", SDPA::SOCP);
    sdpa.set_const("LP", SDPA::LP);

    sdpa.add_bits<SDPA::PhaseType>("PhaseType");
    sdpa.set_const("noINFO", SDPA::noINFO);
    sdpa.set_const("pFEAS", SDPA::pFEAS);
    sdpa.set_const("dFEAS", SDPA::dFEAS);
    sdpa.set_const("pdFEAS", SDPA::pdFEAS);
    sdpa.set_const("pdINF", SDPA::pdINF);
    sdpa.set_const("pFEAS_dINF", SDPA::pFEAS_dINF);
    sdpa.set_const("pINF_dFEAS", SDPA::pINF_dFEAS);
    sdpa.set_const("pdOPT", SDPA::pdOPT);
    sdpa.set_const("pUNBD", SDPA::pUNBD);
    sdpa.set_const("dUNBD", SDPA::dUNBD);

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
        .method("getPhaseValue", &SDPA::getPhaseValue)
        .method("getResultXMat", &SDPA::getResultXMat)
        .method("getResultXVec", &SDPA::getResultXVec)
        .method("getResultYMat", &SDPA::getResultYMat)
        .method("terminate", &SDPA::terminate);
      //.method("writeInputSparse", &SDPA::writeInputSparse);


JULIA_CPP_MODULE_END
