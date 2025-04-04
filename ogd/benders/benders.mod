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

# Benders Parameters
param yb {(i,j) in Ahat}; 
param Niter; # Current Iteration
param nCUT;  # Number of cuts
param restric {(i,j) in Ahat, l in O,k in 1..nCUT};
param ybk {(i,j) in Ahat,k in 1..nCUT}; # Arc constructed in iteration k

# Flow restrictions
node I {i in N, l in O}: net_out=t[i,l];
arc xl {(i,j) in AA, l in O}>=0: from I [i,l], to I [j,l];

var y{(i,j) in Ahat} binary; # Whether arc is built or not


# Subproblem
minimize zd: sum{l in O} (sum {(i,j) in AA} c[i,j,l] * xl[i,j,l]);

subject to caps {(i,j) in Ahat, l in O}:
    xl[i,j,l] <= rho * yb[i,j];

# Master problem (yb)
param u {i in N, l in O, k in 1..nCUT}<=0;
var zmp3;

minimize ZMP3: zmp3;

subject to Bcut {k in 1..nCUT}:
    zmp3 >=
    sum {(i,j) in Ahat} (f[i,j] * y[i,j])
    + 
    sum {l in O} (
        sum {i in N} t[i, l] * u[i,l,k]
        - rho * sum{(i,j) in Ahat: ybk[i,j,k] = 0} restric[i,j,l,k] * y[i,j]
    )
;