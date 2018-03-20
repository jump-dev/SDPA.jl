using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.Test
const MOIU = MOI.Utilities

MOIU.@model SDModelData () (EqualTo, GreaterThan, LessThan) (Zeros, Nonnegatives, Nonpositives, PositiveSemidefiniteConeTriangle) () (SingleVariable,) (ScalarAffineFunction,) (VectorOfVariables,) (VectorAffineFunction,)

using MathOptInterfaceBridges
const MOIB = MathOptInterfaceBridges

MOIB.@bridge SplitInterval MOIB.SplitIntervalBridge () (Interval,) () () () (ScalarAffineFunction,) () ()
MOIB.@bridge SOCtoPSDC MOIB.SOCtoPSDCBridge () () (SecondOrderCone,) () () () (VectorOfVariables,) (VectorAffineFunction,)
MOIB.@bridge RSOCtoPSDC MOIB.RSOCtoPSDCBridge () () (RotatedSecondOrderCone,) () () () (VectorOfVariables,) (VectorAffineFunction,)
MOIB.@bridge GeoMean MOIB.GeoMeanBridge () () (GeometricMeanCone,) () () () (VectorOfVariables,) (VectorAffineFunction,)
MOIB.@bridge RootDet MOIB.RootDetBridge () () (RootDetConeTriangle,) () () () (VectorOfVariables,) (VectorAffineFunction,)

const optimizer = SDPA.SDPAOptimizer(printlevel=0)
# test 1e-3 because of rsoc3 test, otherwise, 1e-5 is enough
const config = MOIT.TestConfig(atol=1e-3, rtol=1e-3)

@testset "Linear tests" begin
    MOIT.contlineartest(SplitInterval{Float64}(MOIU.CachingOptimizer(SDModelData{Float64}(), optimizer)), config)
end
@testset "Conic tests" begin
    MOIT.contconictest(RootDet{Float64}(GeoMean{Float64}(RSOCtoPSDC{Float64}(SOCtoPSDC{Float64}(MOIU.CachingOptimizer(SDModelData{Float64}(), optimizer))))), config, ["psds", "rootdets", "logdet", "exp"])
end
