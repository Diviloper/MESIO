nbstep = NewtonStep(0.1, base)
nastep = NewtonStep(0.1, augmented)
nnstep = NewtonStep(0.1, normal)
npstep = NewtonStep(0.1, normal_permuted)

mbstep = MehrotraStep(base)
mastep = MehrotraStep(augmented)
mnstep = MehrotraStep(normal)

read_and_standardize(path::String)::StandardProblem = standardize(read_from_mat_file(path))[1]
read_and_standardize_full(path::String)::Tuple{StandardProblem,Int,Int} = standardize(read_from_mat_file(path))

function random_point(P::StandardProblem)::Tuple{VF,VF,VF}
    # Create random point
    x = rand(size(P.A, 2)) .* 40
    λ = rand(size(P.A, 1)) .* 40
    s = rand(size(P.A, 2)) .* 40
    return (x, λ, s)
end