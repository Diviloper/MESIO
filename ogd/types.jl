using SparseArrays

const VF = Vector{Float64}
const VVF = Vector{VF}
const MF = Matrix{Float64}
const SMF = SparseMatrixCSC{Float64}

@enum StopReason begin
    stop_gap_reached
    stop_small_ρ
    stop_cholesky_fail
    stop_rank
    stop_error
end

struct StandardProblem
    A::SMF
    b::VF
    c::VF
end
StandardProblem(A, b::MF, c::MF) = StandardProblem(A, b[:, 1], c[:, 1])

struct ExtendedProblem
    A::SMF
    b::VF
    c::VF
    lo::VF
    hi::VF
end
ExtendedProblem(A, b::MF, c::MF, lo::MF, hi::MF) = ExtendedProblem(A, b[:, 1], c[:, 1], lo[:, 1], hi[:, 1])

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

struct Summary
    iterations::Int64
    time::Float64
    cost::Float64
    feasible::Bool
end