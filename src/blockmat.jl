# Copyright (c) 2016: Benoît Legat and SDPA.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

abstract type BlockSolution <: AbstractBlockMatrix{Cdouble} end

struct PrimalSolution <: BlockSolution
    problem::SDPAProblem
end

_get_ptr(X::PrimalSolution, blk) = getResultYMat(X.problem, blk).cpp_object

struct VarDualSolution <: BlockSolution
    problem::SDPAProblem
end

_get_ptr(X::VarDualSolution, blk) = getResultXMat(X.problem, blk).cpp_object

_n_blocks(X::BlockSolution) = getBlockNumber(X.problem)

function block(X::BlockSolution, blk::Integer)
    if blk <= 0 || blk > getBlockNumber(X.problem)
        throw(BoundsError(X, blk))
    end
    n = getBlockSize(X.problem, blk)
    if getBlockType(X.problem, blk) == SDP
        return unsafe_wrap(Array, _get_ptr(X, blk), (n, n))
    end
    return LinearAlgebra.Diagonal(unsafe_wrap(Array, _get_ptr(X, blk), (n,)))
end
