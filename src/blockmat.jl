abstract BlockSolution <: AbstractMatrix{Cdouble}
type PrimalSolution <: BlockSolution
    problem::SDPAProblem
end
getptr(X::PrimalSolution, blk) = getResultYMat(X.problem, blk)
type VarDualSolution <: BlockSolution
    problem::SDPAProblem
end
getptr(X::VarDualSolution, blk) = getResultXMat(X.problem, blk)
function Base.size(X::BlockSolution)
    n = sum([getBlockSize(X.problem, blk) for blk in 1:getBlockNumber(X.problem)])
    (n, n)
end
function Base.getindex(X::BlockSolution, blk::Integer)
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
function Base.getindex(X::BlockSolution, i::Integer, j::Integer)
    if i <= 0 || j <= 0 || max(i, j) > size(X, 1)
        throw(BoundsError(X, (i, j)))
    end
    for blk in 1:getBlockNumber(X.problem)
        n = getBlockSize(X.problem, blk)
        if i <= n && j <= n
            if getBlockType(X.problem, blk) == SDP
                return unsafe_load(getptr(X, blk), i + (j-1) * n)
            else
                return i == j ? unsafe_load(getptr(X, blk), i) : 0
            end
        elseif i <= n || j <= n
            return 0
        else
            i -= n
            j -= n
        end
    end
end
