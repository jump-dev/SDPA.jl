const SET_PARAM = Dict(:Mode         => setParameterType,
                       :MaxIteration => setParameterMaxIteration,
                       :EpsilonStar  => setParameterEpsilonStar,
                       :LambdaStar   => setParameterLambdaStar,
                       :OmegaStar    => setParameterOmegaStar,
                       :LowerBound   => setParameterLowerBound,
                       :UpperBound   => setParameterUpperBound,
                       :BetaStar     => setParameterBetaStar,
                       :BetaBar      => setParameterBetaBar,
                       :GammaStar    => setParameterGammaStar,
                       :EpsilonDash  => setParameterEpsilonDash)

function setparameters!(problem, options)
    for (optname, optval) in options
        SET_PARAM[optname](problem, optval)
    end
end
