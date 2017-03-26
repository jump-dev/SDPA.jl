abstract BlockSolution <: AbstractMatrix{Cdouble}
type PrimalSolution <: BlockSolution
    problem::SDPAProblem
end
getptr(X::PrimalSolution) = getResultXMat(X.problem)
type VarDualSolution <: BlockSolution
    problem::SDPAProblem
end
getptr(X::VarDualSolution) = getResultYMat(X.problem)
function Base.size(X::BlockSolution)
    n = sum([getBlockSize(X.problem, blk) for blk in 1:getBlockNumber(X.problem)])
    (n, n)
end
function Base.getindex(X::BlockSolution, i::Integer, j::Integer)
    for blk in 1:getBlockNumber(X.problem)
        n = getBlockSize(X.problem, blk)
        if i <= n && j <= n
            if getBlockType(X.problem, blk) == SDP
                return unsafe_load(getResultXMat(X.problem, blk), i + (j-1) * n)
            else
                return i == j ? unsafe_load(getResultXMat(X.problem, blk), i) : 0
            end
        elseif i <= n || j <= n
            return 0
        else
            i -= n
            j -= n
        end
    end
end
