function compare_multiplications(A::SMF, c::VF)
    dA = collect(A)
    D = Diagonal(ones(size(c, 1)))

    @time "Sparse Multiplication - Sparse Solve" begin
        ADA = A * D * A'
        ADc = A * D * c
        y = solve(LinearProblem(ADA, ADc))
    end

    @time "Sparse Multiplication - Dense Solve" begin
        ADA = collect(A * D * A')
        ADc = collect(A * D * c)
        y = solve(LinearProblem(ADA, ADc))
    end

    @time "Sparse Multiplication - Dense \\" begin
        ADA = collect(A * D * A')
        ADc = collect(A * D * c)
        y = Symmetric(ADA) \ ADc
    end

    @time "Dense Multiplication - Dense Solve" begin
        ADA = dA * D * dA'
        ADc = dA * D * c
        y = solve(LinearProblem(ADA, ADc))
    end

    @time "Dense Multiplication - Dense Symmetric Solve" begin
        ADA = dA * D * dA'
        ADc = dA * D * c
        y = solve(LinearProblem(Symmetric(ADA), ADc))
    end

    @time "Sparse Multiplication - Dense Cholesky \\" begin
        ADA = collect(A * D * A')
        ADc = collect(A * D * c)
        y = cholesky!(Symmetric(ADA)) \ ADc
    end
    return
end
