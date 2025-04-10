# ---------------------------------------------
# Benders' Decomposition Models for 
# the Network Distribution Problem
# ---------------------------------------------

# Common Parameters
set N;                     # Nodes
set O within N;            # Origins
set A within N cross N;    # Existing Arcs
set Ahat within N cross N; # Potential new Arcs
set AA:=A union Ahat;      # All Arcs

param XC {N}; # Node X Coordinate
param YC {N}; # Node Y Coordinate
param T {i in N,l in O}; # Out Flow
param RHO > 0; # Maximum arc capacity

# --------------------
# Subproblem
# --------------------
param C {(i,j) in AA, l in O} := 95 + (XC[i] - XC[j])^2 + 8*(YC[i] - YC[j])^2; # Exploitation Cost
param Y {(i,j) in Ahat}; 

# Flow restrictions and variables
node Node_Constraints {i in N, l in O}: net_out = T[i,l];
arc xl {(i,j) in AA, l in O} >= 0: from Node_Constraints [i,l], to Node_Constraints [j,l];

minimize SubProblem_Cost: sum {l in O, (i,j) in AA} C[i,j,l] * xl[i,j,l];

subject to Build_To_Use_Constraints {(i,j) in Ahat, l in O}:
    xl[i,j,l] <= RHO * Y[i,j];


# --------------------
# Master problem
# --------------------

param F {(i,j) in Ahat} := 10 * (abs(XC[i] - XC[j]) + 6 * abs(YC[i] - YC[j])); # Fixed Cost

param NCuts;  # Number of cuts
param YK {(i,j) in Ahat, k in 1..NCuts}; # Arc constructed in iteration k
param Cut {(i,j) in Ahat, l in O,k in 1..NCuts};
param U {i in N, l in O, k in 1..NCuts};

var y {(i,j) in Ahat} binary; # Whether arc is built or not
var z >= 0; # Usage cost

minimize Total_Cost:  sum {(i, j) in Ahat} (F[i, j] * y[i, j]) + z;

subject to Cuts {k in 1..NCuts}:
    z >= 
    sum {l in O} (
        sum {i in N} T[i, l] * U[i, l, k]
        - RHO * sum {(i, j) in Ahat: YK[i, j, k] = 0} Cut[i, j, l, k] * y[i, j]
    )
;