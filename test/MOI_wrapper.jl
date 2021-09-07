using Test

using MathOptInterface
const MOI = MathOptInterface
const MOIT = MOI.DeprecatedTest
const MOIU = MOI.Utilities
const MOIB = MOI.Bridges

import SDPA
const optimizer = SDPA.Optimizer()
MOI.set(optimizer, MOI.Silent(), true)

@testset "SolverName" begin
    @test MOI.get(optimizer, MOI.SolverName()) == "SDPA"
end

# UniversalFallback is needed for starting values, even if they are ignored by SDPA
const cache = MOIU.UniversalFallback(MOIU.Model{Float64}())
const cached = MOIU.CachingOptimizer(cache, optimizer)
const bridged = MOIB.full_bridge_optimizer(cached, Float64)
# test 1e-3 because of rsoc3 test, otherwise, 1e-5 is enough
const config = MOIT.Config(atol=1e-3, rtol=1e-3)

@testset "Unit" begin
    MOIT.unittest(bridged, config, [
        # TODO(odow): FIX THIS
        "solve_twice",
        # `NumberOfThreads` not supported.
        "number_threads",
        # `TimeLimitSec` not supported.
        "time_limit_sec",
        # SingleVariable objective of bridged variables, will be solved by objective bridges
        "solve_time",
        "raw_status_string",
        "solve_singlevariable_obj",
        # Quadratic functions are not supported
        "solve_qcp_edge_cases",
        "solve_qp_edge_cases",
        "solve_qp_zero_offdiag",
        # Integer and ZeroOne sets are not supported
        "solve_integer_edge_cases",
        "solve_objbound_edge_cases",
        "solve_zero_one_with_bounds_1",
        "solve_zero_one_with_bounds_2",
        "solve_zero_one_with_bounds_3",
        # FarkasDual tests: SDPA doesn't like proving infeasibility for these...
        # Expression: MOI.get(model, MOI.TerminationStatus()) == MOI.INFEASIBLE
        #  Evaluated: MathOptInterface.INFEASIBLE_OR_UNBOUNDED == MathOptInterface.INFEASIBLE
        "solve_farkas_equalto_upper",
        "solve_farkas_equalto_lower",
        "solve_farkas_lessthan",
        "solve_farkas_greaterthan",
        "solve_farkas_interval_lower",
        "solve_farkas_interval_upper",
        "solve_farkas_variable_lessthan",
        "solve_farkas_variable_lessthan_max",
        "solve_start_soc", # RSOCtoPSDBridge seems to be incorrect for dimension-2 RSOC cone.
    ])
end

@testset "Linear tests" begin
    # See explanation in `MOI/test/Bridges/lazy_bridge_optimizer.jl`.
    # This is to avoid `Variable.VectorizeBridge` which does not support
    # `ConstraintSet` modification.
    MOIB.remove_bridge(bridged, MOIB.Constraint.ScalarSlackBridge{Float64})
    MOIT.contlineartest(bridged, config, [
        # `MOI.UNKNOWN_RESULT_STATUS` instead of `MOI.INFEASIBILITY_CERTIFICATE`
        "linear8a",
        "linear12"
    ])
end
@testset "Conic tests" begin
    MOIT.contconictest(bridged, config, [
        "lin3", "soc3", "normone2", "norminf2",
        # Missing bridges
        "rootdets",
        # Does not support power and exponential cone
        "pow", "dualpow", "logdet", "exp", "dualexp", "relentr"])
end
