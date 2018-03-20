#__precompile__()

module SDPA

using CxxWrap

const depsfile = joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("SDPA not properly installed. Please run Pkg.build(\"SDPA\")")
end

wrap_module(_l_sdpa_wrap, SDPA)

include("blockmat.jl")
include("options.jl")
include("MOIInterface.jl")
include("MPBInterface.jl")

end # module
