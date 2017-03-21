using SDPA
using Base.Test

@test SDPA.greet() == "hello, world"
include("example1.jl")
