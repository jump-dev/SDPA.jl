using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIB = MOI.Bridges

const MOIU = MOI.Utilities
MOIU.@model SDModelData () (EqualTo, GreaterThan, LessThan) (Zeros, Nonnegatives, Nonpositives, PositiveSemidefiniteConeTriangle) () (SingleVariable,) (ScalarAffineFunction,) (VectorOfVariables,) (VectorAffineFunction,)
const optimizer = MOIU.CachingOptimizer(SDModelData{Float64}(), SDPA.SDPAOptimizer())
# test 1e-3 because of rsoc3 test, otherwise, 1e-5 is enough
const config = MOIT.TestConfig(atol=1e-3, rtol=1e-3)

@testset "Linear tests" begin
    MOIT.contlineartest(MOIB.SplitInterval{Float64}(optimizer), config)
end
@testset "Conic tests" begin
    MOIT.contconictest(MOIB.RootDet{Float64}(MOIB.GeoMean{Float64}(MOIB.RSOCtoPSD{Float64}(MOIB.SOCtoPSD{Float64}(optimizer)))), config, ["psds", "rootdets", "logdet", "exp"])
end
