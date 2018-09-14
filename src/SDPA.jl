module SDPA

using CxxWrap

const depsfile = joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("SDPA not properly installed. Please run Pkg.build(\"SDPA\")")
end

@wrapmodule(joinpath(dirname(dirname(pathof(SDPA))), "deps", "usr", "lib", "libsdpa"))

function __init__()
    @initcxx
end

include("blockmat.jl")
include("options.jl")
include("MOIWrapper.jl")
include("MPBWrapper.jl")

end # module
