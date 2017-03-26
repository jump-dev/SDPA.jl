importall MathProgBase.SolverInterface
importall SemidefiniteModels

export SDPAMathProgModel, SDPASolver

immutable SDPASolver <: AbstractMathProgSolver
    options::Dict{Symbol,Any}
end
SDPASolver(;kwargs...) = SDPASolver(Dict{Symbol,Any}(kwargs))

type SDPAMathProgModel <: AbstractSDModel
    problem::SDPAProblem
    options::Dict{Symbol,Any}
    function SDPAMathProgModel(; kwargs...)
        new(nothing, Dict{Symbol, Any}(kwargs))
    end
end
SDModel(s::SDPASolver) = SDPAMathProgModel(; s.options...)
ConicModel(s::SDPASolver) = SDtoConicBridge(SDModel(s))
LinearQuadraticModel(s::SDPASolver) = ConicToLPQPBridge(ConicModel(s))

supportedcones(s::SDPASolver) = [:Free,:Zero,:NonNeg,:NonPos,:SOC,:RSOC,:SDP]
function setvartype!(m::SDPAMathProgModel, vtype, blk, i, j)
    if vtype != :Cont
        error("Unsupported variable type $vtype by SDPA")
    end
end

function loadproblem!(m::SDPAMathProgModel, filename::AbstractString)
    error("not supported yet")
    if endswith(filename,".dat-s")
       m.C, m.b, As = read_prob(filename)
       m.As = [ConstraintMatrix(As[i], i) for i in 1:length(As)]
    else
       error("unrecognized input format extension in $filename")
    end
end
#writeproblem(m, filename::String)
function loadproblem!(m::SDPAMathProgModel, blkdims::Vector{Int}, constr::Int)
    m.problem = SDPAProblem()
    inputConstraintNumber(m.problem, constr)
    inputBlockNumber(m.problem, length(blkdims))
    for (i, blkdim) in enumerate(blkdims)
        inputBlockSize(m.problem, i, blkdim)
        inputBlockType(m.problem, i, blkdim < 0 ? LP : SDP)
    end
    initializeUpperTriangleSpace(m.problem)
end

function setconstrB!(m::SDPAMathProgModel, val, constr::Integer)
    inputCVec(m.problem, constr, val)
end
function setconstrentry!(m::SDPAMathProgModel, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    @assert constr > 0
    inputElement(m.problem, constr, blk, i, j, float(coef), false)
end
function setobjentry!(m::SDPAMathProgModel, coef, blk::Integer, i::Integer, j::Integer)
    inputElement(m.problem, 0, blk, i, j, float(coef), false)
end

function optimize!(m::SDPAMathProgModel)
    SDPA.initializeUpperTriangle(p, false)
    SDPA.initializeSolve(p)
    SDPA.solve(p)
end

function status(m::SDPAMathProgModel)
    return :Optimal
    status = m.status
    if status == 0
        return :Optimal
    elseif status == 1
        return :Infeasible
    elseif status == 2
        return :Unbounded
    elseif status == 3
        return :Suboptimal
    elseif status == 4
        return :UserLimit
    elseif 5 <= status <= 9
        return :Error
    elseif status == -1
        return :Uninitialized
    else
        error("Internal library error: status=$status")
    end
end

function getobjval(m::SDPAMathProgModel)
    getPrimalObj(m.problem)
end
function getsolution(m::SDPAMathProgModel)
    PrimalSolution(m.problem)
end
function getdual(m::SDPAMathProgModel)
    unsafe_wrap(Array, getResultXVec(m.problem), getConstraintNumber(m.problem))
end
function getvardual(m::SDPAMathProgModel)
    VarDualSolution(m.problem)
end
