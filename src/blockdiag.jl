# Copyright (c) 2016: Benoît Legat and SDPA.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

abstract type AbstractBlockMatrix{T} <: AbstractMatrix{T} end

function nblocks end

function block end

function Base.size(bm::AbstractBlockMatrix)
    n = mapreduce(+, 1:nblocks(bm); init = 0) do blk
        return LinearAlgebra.checksquare(block(bm, blk))
    end
    return (n, n)
end
function Base.getindex(bm::AbstractBlockMatrix, i::Integer, j::Integer)
    if (i < 0 || j < 0)
        throw(BoundsError(i, j))
    end
    for k in 1:nblocks(bm)
        blk = block(bm, k)
        n = size(blk, 1)
        if i <= n && j <= n
            return blk[i, j]
        elseif i <= n || j <= n
            return 0
        else
            i -= n
            j -= n
        end
    end
    i, j = (i, j) .+ size(bm)
    return throw(BoundsError(i, j))
end

Base.getindex(A::AbstractBlockMatrix, I::Tuple) = getindex(A, I...)
