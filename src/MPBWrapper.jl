import MathProgBase
const MPB = MathProgBase.SolverInterface
import SemidefiniteModels
const SDM = SemidefiniteModels

export PARAMETER_DEFAULT, PARAMETER_UNSTABLE_BUT_FAST, PARAMETER_STABLE_BUT_SLOW

export SDPAMathProgModel, SDPASolver

struct SDPASolver <: MPB.AbstractMathProgSolver
    options::Dict{Symbol,Any}
end
SDPASolver(;kwargs...) = SDPASolver(Dict{Symbol,Any}(kwargs))

mutable struct SDPAMathProgModel <: SDM.AbstractSDModel
    problem::SDPAProblem
    options::Dict{Symbol,Any}
    function SDPAMathProgModel(; kwargs...)
        new(SDPAProblem(), Dict{Symbol, Any}(kwargs))
    end
end
SDM.SDModel(s::SDPASolver) = SDPAMathProgModel(; s.options...)
MPB.ConicModel(s::SDPASolver) = SDM.SDtoConicBridge(SDM.SDModel(s))
MPB.LinearQuadraticModel(s::SDPASolver) = MPB.ConicToLPQPBridge(MPB.ConicModel(s))

MPB.supportedcones(s::SDPASolver) = [:Free,:Zero,:NonNeg,:NonPos,:SOC,:RSOC,:SDP]
function MPB.setvartype!(m::SDPAMathProgModel, vtype, blk, i, j)
    if vtype != :Cont
        error("Unsupported variable type $vtype by SDPA")
    end
end

function MPB.loadproblem!(m::SDPAMathProgModel, filename::AbstractString)
    error("not supported yet")
end
#writeproblem(m, filename::String)
function MPB.loadproblem!(m::SDPAMathProgModel, blkdims::Vector{Int}, constr::Int)
    m.problem = SDPAProblem()
    setParameterType(m.problem, PARAMETER_DEFAULT)
    setparameters!(m.problem, m.options)
    inputConstraintNumber(m.problem, constr)
    inputBlockNumber(m.problem, length(blkdims))
    for (i, blkdim) in enumerate(blkdims)
        inputBlockSize(m.problem, i, blkdim)
        inputBlockType(m.problem, i, blkdim < 0 ? LP : SDP)
    end
    initializeUpperTriangleSpace(m.problem)
end

function SDM.setconstrB!(m::SDPAMathProgModel, val, constr::Integer)
    @assert constr > 0
    inputCVec(m.problem, constr, val)
end
function SDM.setconstrentry!(m::SDPAMathProgModel, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    @assert constr > 0
    inputElement(m.problem, constr, blk, i, j, float(coef), false)
end
function SDM.setobjentry!(m::SDPAMathProgModel, coef, blk::Integer, i::Integer, j::Integer)
    inputElement(m.problem, 0, blk, i, j, float(coef), false)
end

function MPB.optimize!(m::SDPAMathProgModel)
    SDPA.initializeUpperTriangle(m.problem, false)
    SDPA.initializeSolve(m.problem)
    SDPA.solve(m.problem)
end

function MPB.status(m::SDPAMathProgModel)
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
    end
end

function MPB.getobjval(m::SDPAMathProgModel)
    getPrimalObj(m.problem)
end
function MPB.getsolution(m::SDPAMathProgModel)
    PrimalSolution(m.problem)
end
function MPB.getdual(m::SDPAMathProgModel)
    unsafe_wrap(Array, getResultXVec(m.problem), getConstraintNumber(m.problem))
end
function MPB.getvardual(m::SDPAMathProgModel)
    VarDualSolution(m.problem)
end
