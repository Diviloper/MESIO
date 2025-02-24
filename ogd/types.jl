const VF = Vector{Float64}
const VVF = Vector{VF}
const MF = Union{Matrix{Float64},SparseMatrixCSC{Float64,Int64}}

struct Problem
    A::MF
    b::VF
    c::VF
end
Problem(A, b::MF, c::MF) = Problem(A, b[:, 1], c[:, 1])

struct Result
    o::VF
    x::VVF
    Δ::VVF
    gap::VF
    iterations::Int
end
Result(o, x, Δ, gap) = Result(o, x, Δ, gap, x.size[1])
Result(x, Δ, gap) = Result(round.(x[end], digits=6), x, Δ, gap, x.size[1])