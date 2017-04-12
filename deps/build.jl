using BinDeps
# If I do not do using CxxWrap, when BinDeps try dlopen on libsdpawrap.so, I get
# ERROR: could not load library "~/.julia/v0.5/SDPA/deps/usr/lib/libsdpawrap"
# libcxx_wrap.so.0: cannot open shared object file: No such file or directory
using CxxWrap

@BinDeps.setup

include("blaslapack.jl")
include("sdpa.jl")
include("sdpawrap.jl")

@BinDeps.install Dict(:sdpawrap => :_l_sdpa_wrap)
