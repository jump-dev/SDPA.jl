using SDPA
using Base.Test

include("example1.jl")
include("example2.jl")

using MathOptInterfaceTests
const MOIT = MathOptInterfaceTests

const solver = () -> SDPA.SDPAInstance()
const config = MOIT.TestConfig(1e-5, 1e-5, true, true, true)

@testset "Linear tests" begin
    MOIT.contlineartest(solver, config)
end
@testset "Conic tests" begin
    MOIT.contconictest(solver, config)
end
