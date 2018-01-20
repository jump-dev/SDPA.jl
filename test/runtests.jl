using SDPA
using Base.Test

include("example1.jl")
include("example2.jl")

using MathOptInterfaceTests
const MOIT = MathOptInterfaceTests

const solver = () -> SDPA.SDPAInstance()
# test 1e-3 because of rsoc3 test, otherwise, 1e-5 is enough
const config = MOIT.TestConfig(atol=1e-3, rtol=1e-3)

@testset "Linear tests" begin
    MOIT.contlineartest(solver, config)
end
@testset "Conic tests" begin
    MOIT.contconictest(solver, config, ["logdet", "exp"])
end
