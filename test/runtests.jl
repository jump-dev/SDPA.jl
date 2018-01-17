using SDPA
using Base.Test

include("example1.jl")
include("example2.jl")

using MathOptInterfaceTests
const MOIT = MathOptInterfaceTests

const solver = () -> SDPA.SDPAInstance()
const config = MOIT.TestConfig(atol=1e-5, rtol=1e-5)

@testset "Linear tests" begin
    MOIT.contlineartest(solver, config)
end
@testset "Conic tests" begin
    MOIT.contconictest(solver, config, ["logdet", "exp"])
end
