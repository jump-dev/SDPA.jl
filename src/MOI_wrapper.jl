export PARAMETER_DEFAULT, PARAMETER_UNSTABLE_BUT_FAST, PARAMETER_STABLE_BUT_SLOW

using MathOptInterface
MOI = MathOptInterface

mutable struct SDOptimizer <: SDOI.AbstractSDOptimizer
    problem::SDPAProblem
    solve_time::Float64
    silent::Bool
    options::Dict{Symbol, Any}
    function SDOptimizer(; kwargs...)
		optimizer = new(SDPAProblem(), NaN, false, Dict{Symbol, Any}())
		for (key, value) in kwargs
			MOI.set(optimizer, MOI.RawParameter(key), value)
		end
		return optimizer
    end
end
Optimizer(; kws...) = SDOI.SDOIOptimizer(SDOptimizer(; kws...))

function MOI.supports(optimizer::SDOptimizer, param::MOI.RawParameter)
	return param.name in keys(SET_PARAM)
end
function MOI.set(optimizer::SDOptimizer, param::MOI.RawParameter, value)
	if !MOI.supports(optimizer, param)
		throw(MOI.UnsupportedAttribute(param))
	end
	optimizer.options[param.name] = value
end
function MOI.get(optimizer::SDOptimizer, param::MOI.RawParameter)
	# TODO: This gives a poor error message if the name of the parameter is invalid.
	return optimizer.options[param.name]
end

MOI.supports(::SDOptimizer, ::MOI.Silent) = true
function MOI.set(optimizer::SDOptimizer, ::MOI.Silent, value::Bool)
	optimizer.silent = value
end
MOI.get(optimizer::SDOptimizer, ::MOI.Silent) = optimizer.silent

MOI.get(::SDOptimizer, ::MOI.SolverName) = "SDPA"

# See https://www.researchgate.net/publication/247456489_SDPA_SemiDefinite_Programming_Algorithm_User's_Manual_-_Version_600
# "SDPA (SemiDefinite Programming Algorithm) User's Manual — Version 6.00" Section 6.2
const RAW_STATUS = Dict(
    noINFO        => "The iteration has exceeded the maxIteration and stopped with no informationon the primal feasibility and the dual feasibility.",
    pdOPT => "The normal termination yielding both primal and dual approximate optimal solutions.",
    pFEAS => "The primal problem got feasible but the iteration has exceeded the maxIteration and stopped.",
    dFEAS => "The dual problem got feasible but the iteration has exceeded the maxIteration and stopped.",
    pdFEAS => "Both primal problem and the dual problem got feasible, but the iterationhas exceeded the maxIteration and stopped.",
    pdINF => "At least one of the primal problem and the dual problem is expected to be infeasible.",
    pFEAS_dINF => "The primal problem has become feasible but the dual problem is expected to be infeasible.",
    pINF_dFEAS => "The dual problem has become feasible but the primal problem is expected to be infeasible.",
    pUNBD => "The primal problem is expected to be unbounded.",
    dUNBD => "The dual problem is expected to be unbounded.")

function MOI.get(optimizer::SDOptimizer, ::MOI.RawStatusString)
	return RAW_STATUS[getPhaseValue(optimizer.problem)]
end
function MOI.get(optimizer::SDOptimizer, ::MOI.SolveTime)
	return optimizer.solve_time
end

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
	# TODO Take `silent` into account here
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
	start_time = time()
    SDPA.initializeUpperTriangle(m.problem, false)
    SDPA.initializeSolve(m.problem)
    SDPA.solve(m.problem)
    m.solve_time = time() - start_time
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

MOI.get(m::SDOptimizer, ::MOI.ObjectiveValue) = getPrimalObj(m.problem)
MOI.get(m::SDOptimizer, ::MOI.DualObjectiveValue) = getDualObj(m.problem)
SDOI.getX(m::SDOptimizer) = PrimalSolution(m.problem)
function SDOI.gety(m::SDOptimizer)
    unsafe_wrap(Array, getResultXVec(m.problem), getConstraintNumber(m.problem))
end
SDOI.getZ(m::SDOptimizer) = VarDualSolution(m.problem)
