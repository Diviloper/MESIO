param n;
set N = 1..n;
set E within N cross N;

# Arc costs
param c {E};

# Decision variables: Arc used (binary-like restricted to 0..1)
var x {E} binary;

# Objective: Minimize total cost
minimize Total_Cost:
    sum {(i, j) in E} c[i, j] * x[i, j];


# Constraint 2: Degree of each node must be 2
subject to Degree_Constraint {i in N}:
    sum {j in N: (i, j) in E} x[i, j] + 
    sum {j in N: (j, i) in E} x[j, i] = 2;