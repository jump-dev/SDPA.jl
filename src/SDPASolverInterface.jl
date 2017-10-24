using SemidefiniteOptInterface
SOI = SemidefiniteOptInterface

export PARAMETER_DEFAULT, PARAMETER_UNSTABLE_BUT_FAST, PARAMETER_STABLE_BUT_SLOW

using MathOptInterface
MOI = MathOptInterface

export SDPASolver

struct SDPASolver <: SOI.AbstractSDSolver
    options::Dict{Symbol,Any}
end
SDPASolver(;kwargs...) = SDPASolver(Dict{Symbol,Any}(kwargs))

mutable struct SDPASolverInstance <: SOI.AbstractSDSolverInstance
    problem::SDPAProblem
    options::Dict{Symbol,Any}
    function SDPASolverInstance(; kwargs...)
        new(SDPAProblem(), Dict{Symbol, Any}(kwargs))
    end
end
SOI.SDSolverInstance(s::SDPASolver) = SDPASolverInstance(; s.options...)

const setparam = Dict(:Mode         =>setParameterType,
                      :MaxIteration =>setParameterMaxIteration,
                      :EpsilonStar  =>setParameterEpsilonStar,
                      :LambdaStar   =>setParameterLambdaStar,
                      :OmegaStar    =>setParameterOmegaStar,
                      :LowerBound   =>setParameterLowerBound,
                      :UpperBound   =>setParameterUpperBound,
                      :BetaStar     =>setParameterBetaStar,
                      :BetaBar      =>setParameterBetaBar,
                      :GammaStar    =>setParameterGammaStar,
                      :EpsilonDash  =>setParameterEpsilonDash)

function setparameters!(problem, options)
    for (optname, optval) in options
        setparam[optname](problem, optval)
    end
end

function SOI.initinstance!(m::SDPASolverInstance, blkdims::Vector{Int}, nconstrs::Int)
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
        SOI.setconstraintconstant!(m, 1., 1)
        SOI.setconstraintcoefficient!(m, 1., 1, length(blkdims), 1, 1)
    end
end

function SOI.setconstraintconstant!(m::SDPASolverInstance, val, constr::Integer)
    @assert constr > 0
    #println("b[$constr] = $val")
    inputCVec(m.problem, constr, val)
end
function SOI.setconstraintcoefficient!(m::SDPASolverInstance, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    @assert constr > 0
    #println("A[$constr][$blk][$i, $j] = $coef")
    inputElement(m.problem, constr, blk, i, j, float(coef), false)
end
function SOI.setobjectivecoefficient!(m::SDPASolverInstance, coef, blk::Integer, i::Integer, j::Integer)
    #println("C[$blk][$i, $j] = $coef")
    inputElement(m.problem, 0, blk, i, j, float(coef), false)
end

function MOI.optimize!(m::SDPASolverInstance)
    SDPA.initializeUpperTriangle(m.problem, false)
    SDPA.initializeSolve(m.problem)
    SDPA.solve(m.problem)
end

function MOI.get(m::SDPASolverInstance, ::MOI.TerminationStatus)
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

function MOI.canget(m::SDPASolverInstance, ::MOI.PrimalStatus)
    !(getPhaseValue(m.problem) in [noINFO, pINF_dFEAS, dUNBD, pdINF])
end
function MOI.get(m::SDPASolverInstance, ::MOI.PrimalStatus)
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

function MOI.canget(m::SDPASolverInstance, ::MOI.DualStatus)
    !(getPhaseValue(m.problem) in [noINFO, pFEAS_dINF, pUNBD])
end
function MOI.get(m::SDPASolverInstance, ::MOI.DualStatus)
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

SOI.getprimalobjectivevalue(m::SDPASolverInstance) = getPrimalObj(m.problem)
SOI.getdualobjectivevalue(m::SDPASolverInstance) = getDualObj(m.problem)
SOI.getX(m::SDPASolverInstance) = PrimalSolution(m.problem)
function SOI.gety(m::SDPASolverInstance)
    unsafe_wrap(Array, getResultXVec(m.problem), getConstraintNumber(m.problem))
end
SOI.getZ(m::SDPASolverInstance) = VarDualSolution(m.problem)
