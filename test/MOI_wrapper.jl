using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges

import SDPA
const optimizer = SDPA.Optimizer()

@testset "SolverName" begin
    @test MOI.get(optimizer, MOI.SolverName()) == "SDPA"
end

MOIU.@model(SDModelData,
            (),
            (MOI.EqualTo, MOI.GreaterThan, MOI.LessThan),
            (MOI.Zeros, MOI.Nonnegatives, MOI.Nonpositives,
             MOI.PositiveSemidefiniteConeTriangle),
            (),
            (MOI.SingleVariable,),
            (MOI.ScalarAffineFunction,),
            (MOI.VectorOfVariables,),
            (MOI.VectorAffineFunction,))
# UniversalFallback is needed for starting values, even if they are ignored by SDPA
const cache = MOIU.UniversalFallback(SDModelData{Float64}())
const cached = MOIU.CachingOptimizer(cache, optimizer)
const bridged = MOIB.full_bridge_optimizer(cached, Float64)
# test 1e-3 because of rsoc3 test, otherwise, 1e-5 is enough
const config = MOIT.TestConfig(atol=1e-3, rtol=1e-3)

@testset "Unit" begin
    MOIT.unittest(bridged, config,
                  [# Multiple variable constraints on same variable
                   "solve_with_lowerbound", "solve_affine_interval",
                   "solve_with_upperbound",
                   # Quadratic functions are not supported
                   "solve_qcp_edge_cases", "solve_qp_edge_cases",
                   # Integer and ZeroOne sets are not supported
                   "solve_integer_edge_cases", "solve_objbound_edge_cases"])
end
@testset "Linear tests" begin
    MOIT.contlineartest(bridged, config,
                        ["linear12",
                         # https://github.com/JuliaOpt/MathOptInterface.jl/issues/693
                         "linear1",
                         # Multiple variable constraints on same variable
                         "linear10", "linear10b", "linear14"])
end
@testset "Conic tests" begin
    MOIT.contconictest(bridged, config,
                       ["lin3", "soc3", "rootdets", "logdet", "exp",
                        # Multiple variable constraints on same variable
                        "rotatedsoc3"])
end
