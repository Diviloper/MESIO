# Parameters
set N;                                # Nodes
set O within N;                       # Origins
set A within N cross N;               # Existing Arcs
set Ahat within N cross N;            # Potential new Arcs
set AA := A union Ahat;               # All Arcs

param XC {N};                         # Node X Coordinate
param YC {N};                         # Node Y Coordinate
param T {i in N,l in O};              # Out Flow
param C {(i,j) in AA, l in O} :=      # Exploitation Cost
    95 + (XC[i] - XC[j])^2 
    + 8 * (YC[i] - YC[j])^2;
param F {(i,j) in Ahat} :=            # Investment Cost
    10 * abs(XC[i] - XC[j]) + 
    60 * abs(YC[i] - YC[j]); 
param RHO > 0;                        # Maximum arc capacity

# Variables
var y {(i,j) in Ahat} binary;         # Whether arc is built or not

# Flow variables and constraints
node I {i in N, l in O}: 
    net_out = T[i,l];
arc xl {(i,j) in AA, l in O} >= 0: 
    from I [i,l], 
    to I [j,l];

# Model
# Total cost
minimize Total_Cost:
   sum {(i,j) in Ahat} F[i,j] * y[i,j] +            # Construction Cost
   sum {l in O, (i,j) in AA} C[i,j,l] * xl[i,j,l];  # Usage cost

# Build-to-use Constraint
subject to Capacity {(i,j) in Ahat, l in O}:
    xl[i,j,l] <= RHO * y[i,j];