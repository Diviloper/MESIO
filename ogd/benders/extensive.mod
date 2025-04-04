set N;                     # Nodes
set O within N;            # Origins
set A within N cross N;    # Existing Arcs
set Ahat within N cross N; # Potential new Arcs
set AA:=A union Ahat;      # All Arcs

param xc {N}; # Node X Coordinate
param yc {N}; # Node Y Coordinate
param t {i in N,l in O}; # Out Flow
param c {(i,j) in AA, l in O} := 95 + (xc[i] - xc[j])^2 + 8*(yc[i] - yc[j])^2; # Exploitation Cost
param f {(i,j) in Ahat} := 10 * (abs(xc[i] - xc[j]) + 6 * abs(yc[i] - yc[j])); # Fixed Cost
param rho>0; # Maximum arc capacity

# Flow constraints
node I {i in N, l in O}: net_out = t[i,l];
arc xl {(i,j) in AA, l in O} >= 0: from I [i,l], to I [j,l];

var y{(i,j) in Ahat} binary; # Whether arc is built or not

minimize z: 
   sum {(i,j) in Ahat} f[i,j] * y[i,j] +
   sum {l in O} (sum {(i,j) in AA} c[i,j,l] * xl[i,j,l]);

# Maximum capacity constraint
subject to caps1 {(i,j) in Ahat, l in O}:
    xl[i,j,l] <= rho * y[i,j];

# subject to no_new {(i, j) in Ahat}: y[i, j] = 0;