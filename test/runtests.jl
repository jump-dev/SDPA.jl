# Copyright (c) 2016: Benoît Legat and SDPA.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

for f in filter(f -> endswith(f, ".jl"), readdir(@__DIR__))
    if f != "runtests.jl"
        include(f)
    end
end
