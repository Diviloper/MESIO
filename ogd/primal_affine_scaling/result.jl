struct Result
    o::VF
    x::VVF
    Δ::VVF
    gap::VF
    iterations::Int
    reason::StopReason
    feasible::Bool
end
Result(o, x, Δ, gap, reason, feasible) = Result(o, x, Δ, gap, size(x, 1), reason, feasible)
Result(x, Δ, gap, reason, feasible) = Result(x[end], x, Δ, gap, size(x, 1), reason, feasible)