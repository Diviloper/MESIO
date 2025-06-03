# Input Data
param NPOINTS;
param P {A};                   # Point
param POINTS { 1..NPOINTS, A}; # Extreme Points

var lambda {1..NPOINTS} >= 0;  # Barycentric Coordinates

# Constraints

subject to convex_combination {(i, j) in A}:
    sum {r in 1..NPOINTS} lambda[r] * POINTS[r, i, j] = P[i, j];

subject to unit_lambda_sum:
    sum {r in 1..NPOINTS} lambda[r] = 1;

minimize Minimize_Active_Points: sum {r in 1..NPOINTS} (if lambda[r] > 0 then 1 else 0);
# minimize DummyObjective: 0;
