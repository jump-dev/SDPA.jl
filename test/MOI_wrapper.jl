# Copyright (c) 2016: Benoît Legat and SDPA.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

module TestSDPA

using Test
import MathOptInterface as MOI
import SDPA

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

function test_solver_name()
    @test MOI.get(SDPA.Optimizer(), MOI.SolverName()) == "SDPA"
    return
end

function test_options()
    model = SDPA.Optimizer()
    attr_bad = MOI.RawOptimizerAttribute("bad_option")
    err = MOI.UnsupportedAttribute(attr_bad)
    @test_throws err MOI.get(model, attr_bad)
    @test_throws err MOI.set(model, attr_bad, 0)
    attr_mode = MOI.RawOptimizerAttribute("Mode")
    @test MOI.get(model, attr_mode) === nothing
    MOI.set(model, attr_mode, SDPA.PARAMETER_DEFAULT)
    @test MOI.get(model, attr_mode) == SDPA.PARAMETER_DEFAULT
    MOI.set(model, attr_mode, SDPA.PARAMETER_UNSTABLE_BUT_FAST)
    @test MOI.get(model, attr_mode) == SDPA.PARAMETER_UNSTABLE_BUT_FAST
    return
end

function test_runtests()
    model = MOI.Utilities.CachingOptimizer(
        MOI.Utilities.UniversalFallback(MOI.Utilities.Model{Float64}()),
        MOI.instantiate(SDPA.Optimizer; with_bridge_type = Float64),
    )
    # `Variable.ZerosBridge` makes dual needed by some tests fail.
    MOI.Bridges.remove_bridge(
        model.optimizer,
        MOI.Bridges.Variable.ZerosBridge{Float64},
    )
    MOI.set(model, MOI.Silent(), true)
    MOI.Test.runtests(
        model,
        MOI.Test.Config(;
            rtol = 1e-3,
            atol = 1e-3,
            exclude = Any[
                MOI.ConstraintBasisStatus,
                MOI.VariableBasisStatus,
                MOI.ObjectiveBound,
                MOI.SolverVersion,
            ],
        );
        exclude = String[
            # Unable to bridge RotatedSecondOrderCone to PSD because the dimension is too small: got 2, expected >= 3.
            "test_conic_SecondOrderCone_INFEASIBLE",
            "test_constraint_PrimalStart_DualStart_SecondOrderCone",
            # Expression: MOI.get(model, MOI.TerminationStatus()) == MOI.INFEASIBLE
            #  Evaluated: MathOptInterface.INFEASIBLE_OR_UNBOUNDED == MathOptInterface.INFEASIBLE
            "test_conic_NormInfinityCone_INFEASIBLE",
            "test_conic_NormOneCone_INFEASIBLE",
            # Incorrect objective
            # See https://github.com/jump-dev/MathOptInterface.jl/issues/1759
            "test_unbounded_MIN_SENSE",
            "test_unbounded_MIN_SENSE_offset",
            "test_unbounded_MAX_SENSE",
            "test_unbounded_MAX_SENSE_offset",
            "test_infeasible_MAX_SENSE",
            "test_infeasible_MAX_SENSE_offset",
            "test_infeasible_MIN_SENSE",
            "test_infeasible_MIN_SENSE_offset",
            "test_infeasible_affine_MAX_SENSE",
            "test_infeasible_affine_MAX_SENSE_offset",
            "test_infeasible_affine_MIN_SENSE",
            "test_infeasible_affine_MIN_SENSE_offset",
            # TODO remove when PR merged
            # See https://github.com/jump-dev/MathOptInterface.jl/pull/1769
            "test_objective_ObjectiveFunction_blank",
            # FIXME investigate
            #  Expression: isapprox(MOI.get(model, MOI.ObjectiveValue()), T(2), config)
            #   Evaluated: isapprox(5.999999984012059, 2.0, ...
            "test_modification_delete_variables_in_a_batch",
            # FIXME investigate
            #  Expression: isapprox(MOI.get(model, MOI.ObjectiveValue()), objective_value, config)
            #   Evaluated: isapprox(-2.1881334077988868e-7, 5.0, ...
            "test_objective_qp_ObjectiveFunction_edge_case",
            # FIXME investigate
            #  Expression: isapprox(MOI.get(model, MOI.ObjectiveValue()), objective_value, config)
            #   Evaluated: isapprox(-2.1881334077988868e-7, 5.0, ...
            "test_objective_qp_ObjectiveFunction_zero_ofdiag",
            # FIXME investigate
            #  Expression: isapprox(MOI.get(model, MOI.ConstraintPrimal(), index), solution_value, config)
            #   Evaluated: isapprox(2.5058846553349667e-8, 1.0, ...
            "test_variable_solve_with_lowerbound",
            # FIXME investigate
            # See https://github.com/jump-dev/SDPA.jl/runs/7246518765?check_suite_focus=true#step:6:128
            # Expression: ≈(MOI.get(model, MOI.ConstraintDual(), c), T[1, 0, 0, -1, 1, 0, -1, -1, 1] / T(3), config)
            #  Evaluated: ≈([0.3333333625488728, -0.16666659692134123, -0.16666659693012292, -0.16666659692134123, 0.33333336253987234, -0.16666659692112254, -0.16666659693012292, -0.16666659692112254, 0.333333362548654], [0.3333333333333333, 0.0, 0.0, -0.3333333333333333, 0.3333333333333333, 0.0, -0.3333333333333333, -0.3333333333333333, 0.3333333333333333]
            "test_conic_PositiveSemidefiniteConeSquare_3",
        ],
    )
    return
end

end  # module

TestSDPA.runtests()
