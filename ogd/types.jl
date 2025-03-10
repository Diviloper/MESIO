using SparseArrays

const VF = Vector{Float64}
const VVF = Vector{VF}
const MF = Matrix{Float64}
const SMF = SparseMatrixCSC{Float64}

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
end
Result(o, x, Δ, gap) = Result(o, x, Δ, gap, size(x, 1))
Result(x, Δ, gap) = Result(x[end], x, Δ, gap, size(x, 1))
