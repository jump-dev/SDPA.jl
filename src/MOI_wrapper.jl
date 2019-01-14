export PARAMETER_DEFAULT, PARAMETER_UNSTABLE_BUT_FAST, PARAMETER_STABLE_BUT_SLOW

using MathOptInterface
MOI = MathOptInterface

mutable struct SDOptimizer <: SDOI.AbstractSDOptimizer
    problem::SDPAProblem
    options::Dict{Symbol,Any}
    function SDOptimizer(; kwargs...)
        new(SDPAProblem(), Dict{Symbol, Any}(kwargs))
    end
end
Optimizer(; kws...) = SDOI.SDOIOptimizer(SDOptimizer(; kws...))

MOI.get(::SDOptimizer, ::MOI.SolverName) = "SDPA"

function MOI.empty!(optimizer::SDOptimizer)
    optimizer.problem = SDPAProblem()
end

function SDOI.init!(m::SDOptimizer, blkdims::Vector{Int}, nconstrs::Int)
    @assert nconstrs >= 0
    dummy = nconstrs == 0
    if dummy
        nconstrs = 1
        blkdims = [blkdims; -1]
    end
    m.problem = SDPAProblem()
    setParameterType(m.problem, PARAMETER_DEFAULT)
    setparameters!(m.problem, m.options)
    inputConstraintNumber(m.problem, nconstrs)
    inputBlockNumber(m.problem, length(blkdims))
    for (i, blkdim) in enumerate(blkdims)
        inputBlockSize(m.problem, i, blkdim)
        inputBlockType(m.problem, i, blkdim < 0 ? LP : SDP)
    end
    initializeUpperTriangleSpace(m.problem)
    if dummy
        SDOI.setconstraintconstant!(m, 1., 1)
        SDOI.setconstraintcoefficient!(m, 1., 1, length(blkdims), 1, 1)
    end
end

function SDOI.setconstraintconstant!(m::SDOptimizer, val, constr::Integer)
    @assert constr > 0
    #println("b[$constr] = $val")
    inputCVec(m.problem, constr, val)
end
function SDOI.setconstraintcoefficient!(m::SDOptimizer, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    @assert constr > 0
    #println("A[$constr][$blk][$i, $j] = $coef")
    inputElement(m.problem, constr, blk, i, j, float(coef), false)
end
function SDOI.setobjectivecoefficient!(m::SDOptimizer, coef, blk::Integer, i::Integer, j::Integer)
    #println("C[$blk][$i, $j] = $coef")
    inputElement(m.problem, 0, blk, i, j, float(coef), false)
end

function MOI.optimize!(m::SDOptimizer)
    SDPA.initializeUpperTriangle(m.problem, false)
    SDPA.initializeSolve(m.problem)
    SDPA.solve(m.problem)
end

function MOI.get(m::SDOptimizer, ::MOI.TerminationStatus)
    status = getPhaseValue(m.problem)
    if status == noINFO
        return MOI.OPTIMIZE_NOT_CALLED
    elseif status == pFEAS
        return MOI.SLOW_PROGRESS
    elseif status == dFEAS
        return MOI.SLOW_PROGRESS
    elseif status == pdFEAS
        return MOI.OPTIMAL
    elseif status == pdINF
        return MOI.INFEASIBLE_OR_UNBOUNDED
    elseif status == pFEAS_dINF
        return MOI.DUAL_INFEASIBLE
    elseif status == pINF_dFEAS
        return MOI.INFEASIBLE
    elseif status == pdOPT
        return MOI.OPTIMAL
    elseif status == pUNBD
        return MOI.DUAL_INFEASIBLE
    elseif status == dUNBD
        return MOI.INFEASIBLE
    end
end

function MOI.get(m::SDOptimizer, ::MOI.PrimalStatus)
    status = getPhaseValue(m.problem)
    if status == noINFO
        return MOI.UNKNOWN_RESULT_STATUS
    elseif status == pFEAS
        return MOI.FEASIBLE_POINT
    elseif status == dFEAS
        return MOI.UNKNOWN_RESULT_STATUS
    elseif status == pdFEAS
        return MOI.FEASIBLE_POINT
    elseif status == pdINF
        return MOI.UNKNOWN_RESULT_STATUS
    elseif status == pFEAS_dINF
        return MOI.INFEASIBILITY_CERTIFICATE
    elseif status == pINF_dFEAS
        return MOI.INFEASIBLE_POINT
    elseif status == pdOPT
        return MOI.FEASIBLE_POINT
    elseif status == pUNBD
        return MOI.INFEASIBILITY_CERTIFICATE
    elseif status == dUNBD
        return MOI.INFEASIBLE_POINT
    end
end

function MOI.get(m::SDOptimizer, ::MOI.DualStatus)
    status = getPhaseValue(m.problem)
    if status == noINFO
        return MOI.UNKNOWN_RESULT_STATUS
    elseif status == pFEAS
        return MOI.UNKNOWN_RESULT_STATUS
    elseif status == dFEAS
        return MOI.FEASIBLE_POINT
    elseif status == pdFEAS
        return MOI.FEASIBLE_POINT
    elseif status == pdINF
        return MOI.UNKNOWN_RESULT_STATUS
    elseif status == pFEAS_dINF
        return MOI.INFEASIBLE_POINT
    elseif status == pINF_dFEAS
        return MOI.INFEASIBILITY_CERTIFICATE
    elseif status == pdOPT
        return MOI.FEASIBLE_POINT
    elseif status == pUNBD
        return MOI.INFEASIBLE_POINT
    elseif status == dUNBD
        return MOI.INFEASIBILITY_CERTIFICATE
    end
end

SDOI.getprimalobjectivevalue(m::SDOptimizer) = getPrimalObj(m.problem)
SDOI.getdualobjectivevalue(m::SDOptimizer) = getDualObj(m.problem)
SDOI.getX(m::SDOptimizer) = PrimalSolution(m.problem)
function SDOI.gety(m::SDOptimizer)
    unsafe_wrap(Array, getResultXVec(m.problem), getConstraintNumber(m.problem))
end
SDOI.getZ(m::SDOptimizer) = VarDualSolution(m.problem)
