module SDPA

using CxxWrap

# This 'using' is required to suppress a warning about SDPA not having Libdl in its
# dependencies (Libdl is used by BinaryProvider), e.g.: bicycle1885/CodecZlib.jl#26.
using Libdl

import SDPA_jll: libsdpawrap_path, libsdpawrap
@wrapmodule(libsdpawrap_path)

function __init__()
    @initcxx
end

include("blockdiag.jl")
include("blockmat.jl")
include("options.jl")
include("MOI_wrapper.jl")

end # module
