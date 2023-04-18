# Copyright (c) 2016: Benoît Legat and SDPA.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

mutable struct Optimizer <: MOI.AbstractOptimizer
    objective_constant::Cdouble
    objective_sign::Int
    block_dims::Vector{Int}
    variable_map::Vector{Tuple{Int,Int,Int}} # Variable Index vi -> blk, i, j
    b::Vector{Cdouble}
    problem::Union{Nothing,SDPAProblem}
    optimized::Bool
    solve_time::Float64
    silent::Bool
    options::Dict{Symbol,Any}

    function Optimizer()
        return new(
            zero(Cdouble),
            1,
            Int[],
            Tuple{Int,Int,Int}[],
            Cdouble[],
            nothing,
            false,
            NaN,
            false,
            Dict{Symbol,Any}(),
        )
    end
end

function _variable_map(optimizer::Optimizer, vi::MOI.VariableIndex)
    return optimizer.variable_map[vi.value]
end

function MOI.supports(optimizer::Optimizer, param::MOI.RawOptimizerAttribute)
    return haskey(_SET_PARAM, Symbol(param.name))
end

function MOI.set(optimizer::Optimizer, param::MOI.RawOptimizerAttribute, value)
    if !MOI.supports(optimizer, param)
        throw(MOI.UnsupportedAttribute(param))
    end
    return optimizer.options[Symbol(param.name)] = value
end

function MOI.get(optimizer::Optimizer, param::MOI.RawOptimizerAttribute)
    # TODO: This gives a poor error message if the name of the parameter is invalid.
    return optimizer.options[Symbol(param.name)]
end

MOI.supports(::Optimizer, ::MOI.Silent) = true

function MOI.set(optimizer::Optimizer, ::MOI.Silent, value::Bool)
    optimizer.silent = value
    return
end

MOI.get(optimizer::Optimizer, ::MOI.Silent) = optimizer.silent

MOI.get(::Optimizer, ::MOI.SolverName) = "SDPA"

# FIXME `hash` needs this, this should be fixed upstream in CxxWrap
Base.hash(p::PhaseType, u::UInt64) = hash(convert(Int32, p), u)

# See https://www.researchgate.net/publication/247456489_SDPA_SemiDefinite_Programming_Algorithm_User's_Manual_-_Version_600
# "SDPA (SemiDefinite Programming Algorithm) User's Manual — Version 6.00" Section 6.2
const _RAW_STATUS = Dict(
    noINFO => "The iteration has exceeded the maxIteration and stopped with no informationon the primal feasibility and the dual feasibility.",
    pdOPT => "The normal termination yielding both primal and dual approximate optimal solutions.",
    pFEAS => "The primal problem got feasible but the iteration has exceeded the maxIteration and stopped.",
    dFEAS => "The dual problem got feasible but the iteration has exceeded the maxIteration and stopped.",
    pdFEAS => "Both primal problem and the dual problem got feasible, but the iterationhas exceeded the maxIteration and stopped.",
    pdINF => "At least one of the primal problem and the dual problem is expected to be infeasible.",
    pFEAS_dINF => "The primal problem has become feasible but the dual problem is expected to be infeasible.",
    pINF_dFEAS => "The dual problem has become feasible but the primal problem is expected to be infeasible.",
    pUNBD => "The primal problem is expected to be unbounded.",
    dUNBD => "The dual problem is expected to be unbounded.",
)

function MOI.get(optimizer::Optimizer, ::MOI.RawStatusString)
    if optimizer.problem === nothing
        return "`MOI.optimize!` not called."
    end
    return _RAW_STATUS[getPhaseValue(optimizer.problem)]
end

function MOI.get(optimizer::Optimizer, ::MOI.SolveTimeSec)
    return optimizer.solve_time
end

function MOI.is_empty(optimizer::Optimizer)
    return iszero(optimizer.objective_constant) &&
           optimizer.objective_sign == 1 &&
           isempty(optimizer.block_dims) &&
           isempty(optimizer.variable_map) &&
           isempty(optimizer.b)
end

function MOI.empty!(optimizer::Optimizer)
    optimizer.objective_constant = zero(Cdouble)
    optimizer.objective_sign = 1
    empty!(optimizer.block_dims)
    empty!(optimizer.variable_map)
    empty!(optimizer.b)
    optimizer.problem = nothing
    optimizer.optimized = false
    return
end

function MOI.supports(
    ::Optimizer,
    ::Union{
        MOI.ObjectiveSense,
        MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Cdouble}},
    },
)
    return true
end

MOI.supports_add_constrained_variables(::Optimizer, ::Type{MOI.Reals}) = false

const _SupportedSets =
    Union{MOI.Nonnegatives,MOI.PositiveSemidefiniteConeTriangle}

function MOI.supports_add_constrained_variables(
    ::Optimizer,
    ::Type{<:_SupportedSets},
)
    return true
end

function MOI.supports_constraint(
    ::Optimizer,
    ::Type{MOI.ScalarAffineFunction{Cdouble}},
    ::Type{MOI.EqualTo{Cdouble}},
)
    return true
end

function _new_block(optimizer::Optimizer, set::MOI.Nonnegatives)
    push!(optimizer.block_dims, -MOI.dimension(set))
    blk = length(optimizer.block_dims)
    for i in 1:MOI.dimension(set)
        push!(optimizer.variable_map, (blk, i, i))
    end
    return
end

function _new_block(
    optimizer::Optimizer,
    set::MOI.PositiveSemidefiniteConeTriangle,
)
    push!(optimizer.block_dims, set.side_dimension)
    blk = length(optimizer.block_dims)
    for i in 1:set.side_dimension
        for j in 1:i
            push!(optimizer.variable_map, (blk, i, j))
        end
    end
    return
end

function _add_constrained_variables(optimizer::Optimizer, set::_SupportedSets)
    offset = length(optimizer.variable_map)
    _new_block(optimizer, set)
    ci = MOI.ConstraintIndex{MOI.VectorOfVariables,typeof(set)}(offset + 1)
    return [MOI.VariableIndex(i) for i in offset .+ (1:MOI.dimension(set))], ci
end

function _error(start, stop)
    return error(
        start,
        ". Use `MOI.instantiate(SDPA.Optimizer; with_bridge_type = Float64)` ",
        stop,
    )
end

function _constrain_variables_on_creation(
    dest::MOI.ModelLike,
    src::MOI.ModelLike,
    index_map::MOI.Utilities.IndexMap,
    ::Type{S},
) where {S<:MOI.AbstractVectorSet}
    for ci_src in
        MOI.get(src, MOI.ListOfConstraintIndices{MOI.VectorOfVariables,S}())
        f_src = MOI.get(src, MOI.ConstraintFunction(), ci_src)
        if !allunique(f_src.variables)
            _error(
                "Cannot copy constraint `$(ci_src)` as variables constrained on creation because there are duplicate variables in the function `$(f_src)`",
                "to bridge this by creating slack variables.",
            )
        elseif any(vi -> haskey(index_map, vi), f_src.variables)
            _error(
                "Cannot copy constraint `$(ci_src)` as variables constrained on creation because some variables of the function `$(f_src)` are in another constraint as well.",
                "to bridge constraints having the same variables by creating slack variables.",
            )
        else
            set = MOI.get(src, MOI.ConstraintSet(), ci_src)::S
            vis_dest, ci_dest = _add_constrained_variables(dest, set)
            index_map[ci_src] = ci_dest
            for (vi_src, vi_dest) in zip(f_src.variables, vis_dest)
                index_map[vi_src] = vi_dest
            end
        end
    end
    return
end

function _load_objective_term(optimizer::Optimizer, α, vi::MOI.VariableIndex)
    blk, i, j = _variable_map(optimizer, vi)
    coef = optimizer.objective_sign * α
    if i != j
        coef /= 2
    end
    # in SDP format, it is max and in MPB Conic format it is min
    inputElement(optimizer.problem, 0, blk, i, j, float(coef), false)
    return
end

function MOI.copy_to(dest::Optimizer, src::MOI.ModelLike)
    MOI.empty!(dest)
    index_map = MOI.Utilities.IndexMap()
    # Step 1) Compute the dimensions of what needs to be allocated
    _constrain_variables_on_creation(dest, src, index_map, MOI.Nonnegatives)
    _constrain_variables_on_creation(
        dest,
        src,
        index_map,
        MOI.PositiveSemidefiniteConeTriangle,
    )
    vis_src = MOI.get(src, MOI.ListOfVariableIndices())
    if length(vis_src) != length(index_map.var_map)
        _error(
            "Free variables are not supported by SDPA",
            "to bridge free variables into `x - y` where `x` and `y` are nonnegative.",
        )
    end
    F, S = MOI.ScalarAffineFunction{Cdouble}, MOI.EqualTo{Cdouble}
    cis_src = MOI.get(src, MOI.ListOfConstraintIndices{F,S}())
    dest.b = Vector{Cdouble}(undef, length(cis_src))
    funcs = Vector{F}(undef, length(cis_src))
    for (k, ci_src) in enumerate(cis_src)
        funcs[k] = MOI.get(src, MOI.CanonicalConstraintFunction(), ci_src)
        set = MOI.get(src, MOI.ConstraintSet(), ci_src)
        if !iszero(MOI.constant(funcs[k]))
            throw(
                MOI.ScalarFunctionConstantNotZero{Cdouble,F,S}(
                    MOI.constant(funcs[k]),
                ),
            )
        end
        dest.b[k] = MOI.constant(set)
        index_map[ci_src] = MOI.ConstraintIndex{F,S}(k)
    end
    # Step 2) Allocate SDPA datastructures
    dummy = isempty(dest.b)
    if dummy
        dest.b = [1.0]
        dest.block_dims = [dest.block_dims; -1]
    end
    dest.problem = SDPAProblem()
    setParameterType(dest.problem, PARAMETER_DEFAULT)
    # TODO Take `silent` into account here
    _set_parameters(dest.problem, dest.options)
    inputConstraintNumber(dest.problem, length(dest.b))
    inputBlockNumber(dest.problem, length(dest.block_dims))
    for (i, blkdim) in enumerate(dest.block_dims)
        inputBlockSize(dest.problem, i, blkdim)
        inputBlockType(dest.problem, i, blkdim < 0 ? LP : SDP)
    end
    initializeUpperTriangleSpace(dest.problem)
    for i in eachindex(dest.b)
        inputCVec(dest.problem, i, dest.b[i])
    end
    if dummy
        inputElement(dest.problem, 1, length(dest.block_dims), 1, 1, 1.0, false)
    end
    # Step 3) Load data in the datastructures
    for k in eachindex(funcs)
        for term in funcs[k].terms
            if !iszero(term.coefficient)
                blk, i, j = _variable_map(dest, index_map[term.variable])
                coef = term.coefficient
                if i != j
                    coef /= 2
                end
                inputElement(dest.problem, k, blk, i, j, float(coef), false)
            end
        end
    end
    MOI.Utilities.pass_attributes(dest, src, index_map, vis_src)
    MOI.Utilities.pass_attributes(dest, src, index_map, cis_src)
    # Pass objective attributes and throw error for other ones
    model_attributes = MOI.get(src, MOI.ListOfModelAttributesSet())
    obj_attr = MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Cdouble}}()
    for attr in model_attributes
        if attr != MOI.ObjectiveSense() && attr != obj_attr
            throw(MOI.UnsupportedAttribute(attr))
        end
    end
    # We make sure to set `objective_sign` first before setting the objective
    if MOI.ObjectiveSense() in model_attributes
        sense = MOI.get(src, MOI.ObjectiveSense())
        dest.objective_sign = sense == MOI.MIN_SENSE ? -1 : 1
    end
    if obj_attr in model_attributes
        func = MOI.get(src, obj_attr)
        obj = MOI.Utilities.canonical(func)
        dest.objective_constant = obj.constant
        for term in obj.terms
            if !iszero(term.coefficient)
                _load_objective_term(
                    dest,
                    term.coefficient,
                    index_map[term.variable],
                )
            end
        end
    end
    return index_map
end

function MOI.optimize!(m::Optimizer)
    # SDPA segfault if `optimize!` is called twice
    if !m.optimized
        start_time = time()
        SDPA.initializeUpperTriangle(m.problem, false)
        SDPA.initializeSolve(m.problem)
        SDPA.solve(m.problem)
        m.solve_time = time() - start_time
        m.optimized = true
    end
    return
end

function MOI.get(m::Optimizer, ::MOI.TerminationStatus)
    if m.problem === nothing
        return MOI.OPTIMIZE_NOT_CALLED
    end
    status = getPhaseValue(m.problem)
    if status == noINFO
        return MOI.ITERATION_LIMIT
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
    else
        @assert status == dUNBD
        return MOI.INFEASIBLE
    end
end

function MOI.get(m::Optimizer, attr::MOI.PrimalStatus)
    if attr.result_index > MOI.get(m, MOI.ResultCount())
        return MOI.NO_SOLUTION
    end
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
    else
        @assert status == dUNBD
        return MOI.INFEASIBLE_POINT
    end
end

function MOI.get(m::Optimizer, attr::MOI.DualStatus)
    if attr.result_index > MOI.get(m, MOI.ResultCount())
        return MOI.NO_SOLUTION
    end
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
    else
        @assert status == dUNBD
        return MOI.INFEASIBILITY_CERTIFICATE
    end
end

MOI.get(m::Optimizer, ::MOI.ResultCount) = m.problem === nothing ? 0 : 1

function MOI.get(m::Optimizer, attr::MOI.ObjectiveValue)
    MOI.check_result_index_bounds(m, attr)
    return m.objective_sign * getPrimalObj(m.problem) + m.objective_constant
end

function MOI.get(m::Optimizer, attr::MOI.DualObjectiveValue)
    MOI.check_result_index_bounds(m, attr)
    return m.objective_sign * getDualObj(m.problem) + m.objective_constant
end

struct PrimalSolutionMatrix <: MOI.AbstractModelAttribute end

MOI.is_set_by_optimize(::PrimalSolutionMatrix) = true

function MOI.get(optimizer::Optimizer, ::PrimalSolutionMatrix)
    return PrimalSolution(optimizer.problem)
end

struct DualSolutionVector <: MOI.AbstractModelAttribute end

MOI.is_set_by_optimize(::DualSolutionVector) = true

function MOI.get(optimizer::Optimizer, ::DualSolutionVector)
    return unsafe_wrap(
        Array,
        getResultXVec(optimizer.problem).cpp_object,
        getConstraintNumber(optimizer.problem),
    )
end

struct DualSlackMatrix <: MOI.AbstractModelAttribute end

MOI.is_set_by_optimize(::DualSlackMatrix) = true

function MOI.get(optimizer::Optimizer, ::DualSlackMatrix)
    return VarDualSolution(optimizer.problem)
end

function block(
    optimizer::Optimizer,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables},
)
    return optimizer.variable_map[ci.value][1]
end

function _vectorize_block(M, blk::Integer, s::Type{MOI.Nonnegatives})
    return LinearAlgebra.diag(block(M, blk))
end

function _vectorize_block(
    M::AbstractMatrix{Cdouble},
    blk::Integer,
    s::Type{MOI.PositiveSemidefiniteConeTriangle},
)
    B = block(M, blk)
    d = LinearAlgebra.checksquare(B)
    n = MOI.dimension(MOI.PositiveSemidefiniteConeTriangle(d))
    v = Vector{Cdouble}(undef, n)
    k = 0
    for j in 1:d
        for i in 1:j
            k += 1
            v[k] = B[i, j]
        end
    end
    @assert k == n
    return v
end

function MOI.get(
    optimizer::Optimizer,
    attr::MOI.VariablePrimal,
    vi::MOI.VariableIndex,
)
    MOI.check_result_index_bounds(optimizer, attr)
    blk, i, j = _variable_map(optimizer, vi)
    return block(MOI.get(optimizer, PrimalSolutionMatrix()), blk)[i, j]
end

function MOI.get(
    optimizer::Optimizer,
    attr::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {S<:_SupportedSets}
    MOI.check_result_index_bounds(optimizer, attr)
    return _vectorize_block(
        MOI.get(optimizer, PrimalSolutionMatrix()),
        block(optimizer, ci),
        S,
    )
end

function MOI.get(
    m::Optimizer,
    attr::MOI.ConstraintPrimal,
    ci::MOI.ConstraintIndex{
        MOI.ScalarAffineFunction{Cdouble},
        MOI.EqualTo{Cdouble},
    },
)
    MOI.check_result_index_bounds(m, attr)
    return m.b[ci.value]
end

function MOI.get(
    optimizer::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{MOI.VectorOfVariables,S},
) where {S<:_SupportedSets}
    MOI.check_result_index_bounds(optimizer, attr)
    return _vectorize_block(
        MOI.get(optimizer, DualSlackMatrix()),
        block(optimizer, ci),
        S,
    )
end

function MOI.get(
    optimizer::Optimizer,
    attr::MOI.ConstraintDual,
    ci::MOI.ConstraintIndex{
        MOI.ScalarAffineFunction{Cdouble},
        MOI.EqualTo{Cdouble},
    },
)
    MOI.check_result_index_bounds(optimizer, attr)
    return -MOI.get(optimizer, DualSolutionVector())[ci.value]
end
