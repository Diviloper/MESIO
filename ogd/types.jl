const VF = Vector{Float64}
const VVF = Vector{VF}
const MF = SparseMatrixCSC{Float64,Int64}

struct StandardProblem
    A::MF
    b::VF
    c::VF
end
StandardProblem(A, b::MF, c::MF) = StandardProblem(A, b[:, 1], c[:, 1])

struct ExtendedProblem
    A::MF
    b::VF
    c::VF
    lo::VF
    hi::VF
end

struct Result
    o::VF
    x::VVF
    Δ::VVF
    gap::VF
    iterations::Int
end
Result(o, x, Δ, gap) = Result(o, x, Δ, gap, size(x, 1))
Result(x, Δ, gap) = Result(x[end], x, Δ, gap, size(x, 1))
