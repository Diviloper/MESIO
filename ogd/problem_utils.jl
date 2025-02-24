using InvertedIndices

function expand_problem((; A, b, c)::Problem)::Tuple{Problem,VF}
    n = size(c, 1)
    x⁰ = [1.0 for _ = 1:n]

    r = b - A * x⁰
    Ā = hcat(A, r)

    M = maximum(abs.(c)) * 1000
    c̄ = push!(copy(c), M)

    x̄⁰ = push!(x⁰, 1)

    return Problem(Ā, b, c̄), x̄⁰
end

function make_full_rank(P::Problem)::Problem
    if rank(P.A) == size(P.A, 1)
        @info "Problem is already full rank"
    end
    @info "Removing empty constraints"
    P1 = remove_empty_constraints(P)
    if rank(P1.A) == size(P1.A, 1)
        return P1
    end
    @info "Removing linearly dependent constraints using QR decomposition"
    P2 = remove_linear_dependencies(P1)

    if rank(P2.A) == size(P2.A, 1)
        return P1
    end

    throw("Couldn't make A full-rank")
end

function remove_empty_constraints((; A, b, c)::Problem)::Problem
    empty_rows = [i for i=1:size(A, 1) if all(A[i,:] .== 0)]

    A_reduced = A[Not(empty_rows), :]
    b_reduced = b[Not(empty_rows)]

    return Problem(A_reduced, b_reduced, c)
end

function remove_linear_dependencies((; A, b, c)::Problem)::Problem
    _, _, p = qr(Matrix(A'), ColumnNorm())
    independent_rows = sort(p[1:rank(A)])

    A_reduced = A[independent_rows, :]
    b_reduced = b[independent_rows]
    
    return Problem(A_reduced, b_reduced, c)
end