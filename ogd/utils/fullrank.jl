using InvertedIndices


function make_full_rank(P::StandardProblem)::StandardProblem
    if rank(P.A) == size(P.A, 1)
        @debug "Problem is already full rank"
        return P
    end
    @debug "Removing empty constraints"
    P1 = remove_empty_constraints(P)
    if rank(P1.A) == size(P1.A, 1)
        return P1
    end
    @debug "Removing linearly dependent constraints using QR decomposition"
    P2 = remove_linear_dependencies(P1)

    if rank(P2.A) != size(P2.A, 1)
        @warn "Couldn't make A full-rank"
    end

    return P2
end

function remove_empty_constraints((; A, b, c)::StandardProblem)::StandardProblem
    empty_rows = [i for i = 1:size(A, 1) if all(A[i, :] .== 0)]

    A_reduced = A[Not(empty_rows), :]
    b_reduced = b[Not(empty_rows)]

    return StandardProblem(A_reduced, b_reduced, c)
end

function remove_linear_dependencies((; A, b, c)::StandardProblem)::StandardProblem
    _, _, p = qr(Matrix(A'), ColumnNorm())
    independent_rows = sort(p[1:rank(A)])

    A_reduced = A[independent_rows, :]
    b_reduced = b[independent_rows]

    return StandardProblem(A_reduced, b_reduced, c)
end