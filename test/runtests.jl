using SDPA
using Base.Test

include("example1.jl")
include("example2.jl")

@testset "Linear tests" begin
    include(joinpath(Pkg.dir("MathOptInterface"), "test", "contlinear.jl"))
    contlineartest(SDPA.SDPASolver(), 1e-5)
end
@testset "Conic tests" begin
    include(joinpath(Pkg.dir("MathOptInterface"), "test", "contconic.jl"))
    contconictest(SDPA.SDPASolver(), 1e-5)
end
