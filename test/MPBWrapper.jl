@testset "Linear tests" begin
    include(joinpath(Pkg.dir("MathProgBase"),"test","linproginterface.jl"))
    linprogsolvertest(SDPASolver(), 1e-5)
end
@testset "Conic tests" begin
    include(joinpath(Pkg.dir("MathProgBase"),"test","conicinterface.jl"))

    @testset "Conic linear tests" begin
        coniclineartest(SDPASolver(), duals=true, tol=1e-5)
    end

    @testset "Conic SOC tests" begin
        conicSOCtest(SDPASolver(), duals=true, tol=1e-5)
    end

    @testset "Conic SOC rotated tests" begin
        conicSOCRotatedtest(SDPASolver(), duals=true, tol=1e-5)
    end

    @testset "Conic SDP tests" begin
        conicSDPtest(SDPASolver(), duals=false, tol=1e-5)
    end
end

using SemidefiniteModels
@testset "MPB interface" begin
    solver = SDPASolver()
    @test supportedcones(solver) == [:Free,:Zero,:NonNeg,:NonPos,:SOC,:RSOC,:SDP]
    m = SDModel(solver)
    @test_throws ErrorException loadproblem!(m, "in.dat-s")
    # If I put 0 as third argument, the .cov coverage files get deleted
    # Weirdest thing ever :o
    loadproblem!(m, [1], 1)
    @test_throws ErrorException setvartype!(m, :Int, 1, 1, 1)
    @test status(m) == :Uninitialized
end
