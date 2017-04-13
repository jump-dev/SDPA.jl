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
        new(SDPAProblem(), Dict{Symbol, Any}(kwargs))
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
    @assert constr > 0
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
    SDPA.initializeUpperTriangle(m.problem, false)
    SDPA.initializeSolve(m.problem)
    SDPA.solve(m.problem)
end

function status(m::SDPAMathProgModel)
    status = getPhaseValue(m.problem)
    if status == noINFO
        return :Uninitialized
    elseif status == pFEAS
        return :Suboptimal
    elseif status == dFEAS
        return :Suboptimal
    elseif status == pdFEAS
        return :Optimal
    elseif status == pdINF
        return :Infeasible
    elseif status == pFEAS_dINF
        return :Unbounded
    elseif status == pINF_dFEAS
        return :Infeasible
    elseif status == pdOPT
        return :Optimal
    elseif status == pUNBD
        return :Unbounded
    elseif status == dUNBD
        return :Infeasible
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
