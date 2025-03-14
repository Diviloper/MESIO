function standardize((; A, b, c, lo, hi)::ExtendedProblem)::Tuple{StandardProblem, Int, Int}
    original_constraints = size(A, 1)
    original_variables = size(A, 2)

    surplus_indices = findall(!=(0), lo)
    slack_indices = findall(!=(Inf), hi)

    if size(surplus_indices, 1) == 0 && size(slack_indices, 1) == 0
        @info "No standardization required"
        return StandardProblem(A, b, c), original_constraints, original_variables
    end

    num_constraints = original_constraints
    num_variables = original_variables

    (I, J, V) = findnz(A)
    b̂ = copy(b)

    # Add surplus variable and constraint for every variable with a lower bound
    for var_index in surplus_indices
        num_constraints += 1
        num_variables += 1

        # Add constraint x - s = lo

        push!(I, num_constraints)
        push!(J, num_variables)
        push!(V, -1)

        push!(I, num_constraints)
        push!(J, var_index)
        push!(V, 1)

        push!(b̂, lo[var_index])
    end

    # Add slack variable and constraint for every variable with an upper bound
    for var_index in slack_indices
        num_constraints += 1
        num_variables += 1

        # Add constraint x + s = hi

        push!(I, num_constraints)
        push!(J, num_variables)
        push!(V, 1)

        push!(I, num_constraints)
        push!(J, var_index)
        push!(V, 1)

        push!(b̂, hi[var_index])
    end

    @info "Standardization applied: #Constraints: $original_constraints -> $num_constraints, #Variables: $original_variables -> $num_variables"

    return StandardProblem(sparse(I, J, V), b̂, vcat(c, zeros(num_variables - original_variables))), original_constraints, original_variables
end