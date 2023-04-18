# Copyright (c) 2016: Benoît Legat and SDPA.jl contributors
#
# Use of this source code is governed by an MIT-style license that can be found
# in the LICENSE.md file or at https://opensource.org/licenses/MIT.

const _SET_PARAM = Dict(
    :Mode => setParameterType,
    :MaxIteration => setParameterMaxIteration,
    :EpsilonStar => setParameterEpsilonStar,
    :LambdaStar => setParameterLambdaStar,
    :OmegaStar => setParameterOmegaStar,
    :LowerBound => setParameterLowerBound,
    :UpperBound => setParameterUpperBound,
    :BetaStar => setParameterBetaStar,
    :BetaBar => setParameterBetaBar,
    :GammaStar => setParameterGammaStar,
    :EpsilonDash => setParameterEpsilonDash,
)

function _set_parameters(problem, options)
    for (optname, optval) in options
        _SET_PARAM[optname](problem, optval)
    end
    return
end
