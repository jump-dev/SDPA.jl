module TestSDPA

using Test
using MathOptInterface
import SDPA

const MOI = MathOptInterface

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
end

function test_options()
    param = MOI.RawOptimizerAttribute("bad_option")
    err = MOI.UnsupportedAttribute(param)
    @test_throws err MOI.set(
        SDPA.Optimizer(),
        MOI.RawOptimizerAttribute("bad_option"),
        0,
    )
end

function test_runtests()
    model = MOI.Utilities.CachingOptimizer(
        MOI.Utilities.UniversalFallback(MOI.Utilities.Model{Float64}()),
        MOI.instantiate(SDPA.Optimizer, with_bridge_type = Float64),
    )
    # `Variable.ZerosBridge` makes dual needed by some tests fail.
    MOI.Bridges.remove_bridge(
        model.optimizer,
        MathOptInterface.Bridges.Variable.ZerosBridge{Float64},
    )
    MOI.set(model, MOI.Silent(), true)
    MOI.Test.runtests(
        model,
        MOI.Test.Config(
            rtol = 1e-3,
            atol = 1e-3,
            exclude = Any[
                MOI.ConstraintBasisStatus,
                MOI.VariableBasisStatus,
                MOI.ObjectiveBound,
                MOI.SolverVersion,
            ],
        ),
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
        ],
    )
    return
end

end  # module

TestSDPA.runtests()
