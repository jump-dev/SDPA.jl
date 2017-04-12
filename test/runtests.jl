using SDPA
using Base.Test

include("example1.jl")
include("example2.jl")
if false
@testset "Linear tests" begin
    include(joinpath(Pkg.dir("MathProgBase"),"test","linproginterface.jl"))
    linprogsolvertest(SDPASolver(), 1e-7)
end
@testset "Conic tests" begin
    include(joinpath(Pkg.dir("MathProgBase"),"test","conicinterface.jl"))

    @testset "Conic linear tests" begin
        coniclineartest(SDPASolver(), duals=true, tol=1e-6)
    end

    @testset "Conic SOC tests" begin
        conicSOCtest(SDPASolver(write_prob="soc.prob"), duals=true, tol=1e-6)
    end

    @testset "Conic SOC rotated tests" begin
        conicSOCRotatedtest(SDPASolver(), duals=true, tol=1e-6)
    end

    @testset "Conic SDP tests" begin
        conicSDPtest(SDPASolver(), duals=false, tol=1e-6)
    end
end
end
