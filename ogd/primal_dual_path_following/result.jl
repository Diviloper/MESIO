struct Result
    # Result
    o::VF

    # Vars
    x::VVF
    λ::VVF
    s::VVF
    
    # Directions
    Δx::VVF
    Δλ::VVF
    Δs::VVF

    # Residuals
    rc::VVF
    rb::VVF
    μ::VF
    
    # Gaps
    primal_gap::VF
    dual_gap::VF

    # Other
    iterations::Int
end
Result(o, x, λ, s, Δx, Δλ, Δs, rc, rb, μ, primal_gap, dual_gap) = Result(o, x, λ, s, Δx, Δλ, Δs, rc, rb, μ, primal_gap, dual_gap, size(x, 1))
Result(x, λ, s, Δx, Δλ, Δs, rc, rb, μ, primal_gap, dual_gap) = Result(x[end], x, λ, s, Δx, Δλ, Δs, rc, rb, μ, primal_gap, dual_gap, size(x, 1))