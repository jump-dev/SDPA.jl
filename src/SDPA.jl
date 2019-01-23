module SDPA

using CxxWrap

# This 'using' is required to suppress a warning about SDPA not having Libdl in its
# dependencies (Libdl is used by BinaryProvider), e.g.: bicycle1885/CodecZlib.jl#26.
using Libdl

const depsfile = joinpath(dirname(dirname(@__FILE__)), "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("SDPA not properly installed. Please run Pkg.build(\"SDPA\")")
end

@wrapmodule(joinpath(dirname(dirname(pathof(SDPA))), "deps", "usr", "lib",
                     "libsdpawrap"))

function __init__()
    @initcxx
end

using SemidefiniteOptInterface
SDOI = SemidefiniteOptInterface

include("blockmat.jl")
include("options.jl")
include("MOI_wrapper.jl")
include("MPB_wrapper.jl")

end # module
