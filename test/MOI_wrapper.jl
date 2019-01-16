using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges

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
const optimizer = MOIU.CachingOptimizer(cache,
                                        SDPA.Optimizer())
# test 1e-3 because of rsoc3 test, otherwise, 1e-5 is enough
const config = MOIT.TestConfig(atol=1e-3, rtol=1e-3)

@testset "SolverName" begin
    @test MOI.get(optimizer, MOI.SolverName()) == "SDPA"
end

@testset "Linear tests" begin
    MOIT.contlineartest(MOIB.SplitInterval{Float64}(optimizer), config,
                        ["linear12"])
end
@testset "Conic tests" begin
    MOIT.contconictest(MOIB.RootDet{Float64}(MOIB.GeoMean{Float64}(MOIB.RSOCtoPSD{Float64}(MOIB.SOCtoPSD{Float64}(optimizer)))),
                       config,
                       ["lin3", "soc3", "psds", "rootdets", "logdet", "exp"])
end
