# ---------------------------------------------------
# Model for the Multicommodity Network Flow Problem
# Dantizg's Cutting Plane Version
# ---------------------------------------------------

# Common
set N;                      # Nodes
set FN;                     # Fake Nodes
set O within N;             # Origins
set A within N cross N;     # Existing Arcs
param MC;                   # Default maximum arc capacity
param Y {A} default MC;     # Maximum arc capacity

param XC {N};               # Node X Coordinate
param YC {N};               # Node Y Coordinate
param T {i in N, l in O};   # Out Flow
param C {(i, j) in A} :=    # Exploitation Cost
    95 
    + (XC[i] - XC[j])^2 
    + 8 * (YC[i] - YC[j])^2;


param BIGM > 0;              # Big-M Multiplier for artificial costs

# SubProblem
param MU {(i, j) in A}       # Lagrange Multipliers
    >= 0, default 0; 

var tf {A};                  # Total Flow
node I {i in N, l in O}:     # Real nodes
    net_out = T[i, l];
node AI {o in FN, l in O}:   # Artificial nodes
    net_out = 0;

arc flow {(i, j) in A, l in O} >= 0:     # Flow of normal arcs
    from I [i, l], to I [j, l];
arc afo {o in FN, l in O} >= 0:          # Flow of articial arcs (from origins)
    from I [l, l], to AI [o, l];
arc afd {o in FN, i in N, l in O} >= 0:  # Flow of articial arcs (to destinations)
    from AI [o, l], to I [i, l];


minimize w: 
    sum {(i, j) in A} C[i, j] * tf[i, j] +
    sum {(i, j) in A} MU[i, j] * (tf[i, j] - Y[i, j]) +
    BIGM * sum {o in FN, l in O} afo[o, l] +
    BIGM * sum {o in FN, i in N, l in O} afd[o, i, l];

subject to total_flow {(i, j) in A}: tf[i, j] = sum {l in O} flow[i, j, l];
subject to caps {(i, j) in A}: tf[i, j] <= Y[i, j];

# Master Problem
param NCUTS;                                 # Number of Cuts
param FLOW {A, {1..NCUTS}} default 0;        # Flows of cut n
param AFO {FN, O, {1..NCUTS}} default 0;     # Artificial flows of cut n (from origins)
param AFD {FN, N, O, {1..NCUTS}} default 0;  # Artificial flows of cut n (to destinations)

var z;
var mu {A} >= 0;

maximize Z: z;

subject to cuts{k in {1..NCUTS}}: z <= 
    sum {(i, j) in A} C[i, j] * FLOW[i, j, k] +
    sum {(i, j) in A} mu[i, j] * (FLOW[i, j, k] - Y[i, j]) +
    BIGM * sum {o in FN, l in O} AFO[o, l, k] +
    BIGM * sum {o in FN, i in N, l in O} AFD[o, i, l, k];
