set N;                      # Nodes
set FN;                     # Fake Nodes
set O within N;             # Origins
set A within N cross N;     # Existing Arcs
param MC;                   # Default maximum arc capacity
param Y {A} default MC;     # Maximum arc capacity

param XC {N};               # Node X Coordinate
param YC {N};               # Node Y Coordinate
param T {i in N, l in O};   # Out Flow (unnecessary, added to reuse cutting_plane.dat)
param C {(i, j) in A} :=    # Exploitation Cost
    95 
    + (XC[i] - XC[j])^2 
    + 8 * (YC[i] - YC[j])^2;

param NCUTS;                          # Number of Cuts
set CUTS = {1..NCUTS};                # Cut Set
param FLOW {A, CUTS} default 0;       # Flows of cut n
param AFO {FN, O, CUTS} default 0;    # Artificial flows of cut n (from origins)
param AFD {FN, N, O, CUTS} default 0; # Artificial flows of cut n (to nodes)
param BIGM > 0;                       # Big-M Multiplier for artificial costs

var alpha {CUTS} >= 0;


minimize z:
    sum {k in CUTS} alpha[k] * (
        sum {(i, j) in A} C[i, j] * FLOW[i, j, k]
        + BIGM * sum{f in FN, l in O} AFO[f, l, k]
        + BIGM * sum{f in FN, i in N, l in O} AFD[f, i, l, k]
    );

subject to gx {(i,j) in A}:
    sum {k in CUTS} alpha[k] * (-FLOW[i, j, k] + Y[i, j]) >= 0;

subject to sum_unit:
    sum {k in CUTS} alpha[k] = 1;