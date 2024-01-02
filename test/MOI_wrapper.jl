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
    model = MOI.instantiate(SDPA.Optimizer; with_bridge_type = Float64)
    # `Variable.ZerosBridge` makes dual needed by some tests fail.
    MOI.Bridges.remove_bridge(model, MOI.Bridges.Variable.ZerosBridge{Float64})
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
        exclude = Regex[
            # Expression: MOI.get(model, MOI.TerminationStatus()) == MOI.INFEASIBLE
            #  Evaluated: MathOptInterface.INFEASIBLE_OR_UNBOUNDED == MathOptInterface.INFEASIBLE
            r"test_conic_NormInfinityCone_INFEASIBLE$",
            r"test_conic_NormOneCone_INFEASIBLE$",
            # Incorrect objective
            # See https://github.com/jump-dev/MathOptInterface.jl/issues/1759
            r"test_unbounded_MIN_SENSE$",
            r"test_unbounded_MIN_SENSE_offset$",
            r"test_unbounded_MAX_SENSE$",
            r"test_unbounded_MAX_SENSE_offset$",
            r"test_infeasible_MAX_SENSE$",
            r"test_infeasible_MAX_SENSE_offset$",
            r"test_infeasible_MIN_SENSE$",
            r"test_infeasible_MIN_SENSE_offset$",
            r"test_infeasible_affine_MAX_SENSE$",
            r"test_infeasible_affine_MAX_SENSE_offset$",
            r"test_infeasible_affine_MIN_SENSE$",
            r"test_infeasible_affine_MIN_SENSE_offset$",
            # FIXME investigate
            #  Expression: isapprox(MOI.get(model, MOI.ObjectiveValue()), objective_value, config)
            #   Evaluated: isapprox(-2.1881334077988868e-7, 5.0, ...
            r"test_objective_qp_ObjectiveFunction_edge_case$",
            # FIXME investigate
            #  Expression: isapprox(MOI.get(model, MOI.ObjectiveValue()), objective_value, config)
            #   Evaluated: isapprox(-2.1881334077988868e-7, 5.0, ...
            r"test_objective_qp_ObjectiveFunction_zero_ofdiag$",
            # FIXME investigate
            # See https://github.com/jump-dev/SDPA.jl/runs/7246518765?check_suite_focus=true#step:6:128
            # Expression: ≈(MOI.get(model, MOI.ConstraintDual(), c), T[1, 0, 0, -1, 1, 0, -1, -1, 1] / T(3), config)
            #  Evaluated: ≈([0.3333333625488728, -0.16666659692134123, -0.16666659693012292, -0.16666659692134123, 0.33333336253987234, -0.16666659692112254, -0.16666659693012292, -0.16666659692112254, 0.333333362548654], [0.3333333333333333, 0.0, 0.0, -0.3333333333333333, 0.3333333333333333, 0.0, -0.3333333333333333, -0.3333333333333333, 0.3333333333333333]
            r"test_conic_PositiveSemidefiniteConeSquare_3$",
        ],
    )
    return
end

end  # module

TestSDPA.runtests()
