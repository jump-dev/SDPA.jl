# Copyright (c) 2016: Benoît Legat and SDPA.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module SDPA

using CxxWrap  # CxxWrap doesn't have good hygiene so this must be using.
import LinearAlgebra
import MathOptInterface as MOI
import SDPA_jll

CxxWrap.@wrapmodule(SDPA_jll.libsdpawrap_path)

function __init__()
    CxxWrap.@initcxx
    return
end

include("blockdiag.jl")
include("blockmat.jl")
include("options.jl")
include("MOI_wrapper.jl")

export PARAMETER_DEFAULT, PARAMETER_UNSTABLE_BUT_FAST, PARAMETER_STABLE_BUT_SLOW

end # module
