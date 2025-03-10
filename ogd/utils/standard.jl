function standardize((; A, b, c, lo, hi)::ExtendedProblem)::StandardProblem
    # Handle lower bounds
    surplus_indices = findall(!=(0), lo)
    slack_indices = findall(!=(Inf), hi)
    if size(surplus_indices, 1) == 0 && size(slack_indices, 1) == 0
        return StandardProblem(A, b, c)
    end

    (I, J, V) = findnz(A)
    # Add surplus variabls and constraints for every lo
    num_variables = size(A, 2)
    for index in surplus_indices
        push!(I, )
    end


end