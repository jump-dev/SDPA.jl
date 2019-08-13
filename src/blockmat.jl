using LinearAlgebra

abstract type BlockSolution <: AbstractBlockMatrix{Cdouble} end
struct PrimalSolution <: BlockSolution
    problem::SDPAProblem
end
getptr(X::PrimalSolution, blk) = getResultYMat(X.problem, blk)
struct VarDualSolution <: BlockSolution
    problem::SDPAProblem
end
getptr(X::VarDualSolution, blk) = getResultXMat(X.problem, blk)
nblocks(X::BlockSolution) = getBlockNumber(X.problem)
function block(X::BlockSolution, blk::Integer)
    if blk <= 0 || blk > getBlockNumber(X.problem)
        throw(BoundsError(X, blk))
    end
    n = getBlockSize(X.problem, blk)
    if getBlockType(X.problem, blk) == SDP
        unsafe_wrap(Array, getptr(X, blk), (n, n))
    else
        Diagonal(unsafe_wrap(Array, getptr(X, blk), (n,)))
    end
end
# Needed by MPB_wrapper
function Base.getindex(A::BlockSolution, i::Integer)
    block(A, i)
end
