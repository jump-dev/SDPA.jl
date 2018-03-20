using SemidefiniteOptInterface
SDOI = SemidefiniteOptInterface

export PARAMETER_DEFAULT, PARAMETER_UNSTABLE_BUT_FAST, PARAMETER_STABLE_BUT_SLOW

using MathOptInterface
MOI = MathOptInterface

export SDPAOptimizer

mutable struct SDPASDOptimizer <: SDOI.AbstractSDOptimizer
    problem::SDPAProblem
    options::Dict{Symbol,Any}
    function SDPASDOptimizer(; kwargs...)
        new(SDPAProblem(), Dict{Symbol, Any}(kwargs))
    end
end
SDPAOptimizer(; kws...) = SDOI.SDOIOptimizer(SDPASDOptimizer(; kws...))

function SDOI.init!(m::SDPASDOptimizer, blkdims::Vector{Int}, nconstrs::Int)
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

function SDOI.setconstraintconstant!(m::SDPASDOptimizer, val, constr::Integer)
    @assert constr > 0
    #println("b[$constr] = $val")
    inputCVec(m.problem, constr, val)
end
function SDOI.setconstraintcoefficient!(m::SDPASDOptimizer, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    @assert constr > 0
    #println("A[$constr][$blk][$i, $j] = $coef")
    inputElement(m.problem, constr, blk, i, j, float(coef), false)
end
function SDOI.setobjectivecoefficient!(m::SDPASDOptimizer, coef, blk::Integer, i::Integer, j::Integer)
    #println("C[$blk][$i, $j] = $coef")
    inputElement(m.problem, 0, blk, i, j, float(coef), false)
end

function MOI.optimize!(m::SDPASDOptimizer)
    SDPA.initializeUpperTriangle(m.problem, false)
    SDPA.initializeSolve(m.problem)
    SDPA.solve(m.problem)
end

function MOI.get(m::SDPASDOptimizer, ::MOI.TerminationStatus)
    status = getPhaseValue(m.problem)
    if status == noINFO
        return MOI.OtherError
    elseif status == pFEAS
        return MOI.SlowProgress
    elseif status == dFEAS
        return MOI.SlowProgress
    elseif status == pdFEAS
        return MOI.Success
    elseif status == pdINF
        return MOI.Success
    elseif status == pFEAS_dINF
        return MOI.Success
    elseif status == pINF_dFEAS
        return MOI.Success
    elseif status == pdOPT
        return MOI.Success
    elseif status == pUNBD
        return MOI.Success
    elseif status == dUNBD
        return MOI.Success
    end
end

function MOI.canget(m::SDPASDOptimizer, ::MOI.PrimalStatus)
    !(getPhaseValue(m.problem) in [noINFO, pINF_dFEAS, dUNBD, pdINF])
end
function MOI.get(m::SDPASDOptimizer, ::MOI.PrimalStatus)
    status = getPhaseValue(m.problem)
    if status == noINFO
        return MOI.UnknownResultStatus
    elseif status == pFEAS
        return MOI.FeasiblePoint
    elseif status == dFEAS
        return MOI.UnknownResultStatus
    elseif status == pdFEAS
        return MOI.FeasiblePoint
    elseif status == pdINF
        return MOI.InfeasibilityCertificate
    elseif status == pFEAS_dINF
        return MOI.InfeasibilityCertificate
    elseif status == pINF_dFEAS
        return MOI.InfeasiblePoint
    elseif status == pdOPT
        return MOI.FeasiblePoint
    elseif status == pUNBD
        return MOI.InfeasibilityCertificate
    elseif status == dUNBD
        return MOI.InfeasiblePoint
    end
end

function MOI.canget(m::SDPASDOptimizer, ::MOI.DualStatus)
    !(getPhaseValue(m.problem) in [noINFO, pFEAS_dINF, pUNBD])
end
function MOI.get(m::SDPASDOptimizer, ::MOI.DualStatus)
    status = getPhaseValue(m.problem)
    if status == noINFO
        return MOI.UnknownResultStatus
    elseif status == pFEAS
        return MOI.UnknownResultStatus
    elseif status == dFEAS
        return MOI.FeasiblePoint
    elseif status == pdFEAS
        return MOI.FeasiblePoint
    elseif status == pdINF
        return MOI.InfeasibilityCertificate
    elseif status == pFEAS_dINF
        return MOI.InfeasiblePoint
    elseif status == pINF_dFEAS
        return MOI.InfeasibilityCertificate
    elseif status == pdOPT
        return MOI.FeasiblePoint
    elseif status == pUNBD
        return MOI.InfeasiblePoint
    elseif status == dUNBD
        return MOI.InfeasibilityCertificate
    end
end

SDOI.getprimalobjectivevalue(m::SDPASDOptimizer) = getPrimalObj(m.problem)
SDOI.getdualobjectivevalue(m::SDPASDOptimizer) = getDualObj(m.problem)
SDOI.getX(m::SDPASDOptimizer) = PrimalSolution(m.problem)
function SDOI.gety(m::SDPASDOptimizer)
    unsafe_wrap(Array, getResultXVec(m.problem), getConstraintNumber(m.problem))
end
SDOI.getZ(m::SDPASDOptimizer) = VarDualSolution(m.problem)
