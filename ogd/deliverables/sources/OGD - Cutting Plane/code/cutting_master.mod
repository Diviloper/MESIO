# Master Problem Model
param NCUTS;                          # Number of Cuts
set CUTS = {1..NCUTS};                # Cut Set
param FLOW {A, CUTS} default 0;       # Flows of cut n
param AFO {FN, O, CUTS} default 0;    # Artificial flows of cut n (from origins)
param AFD {FN, N, O, CUTS} default 0; # Artificial flows of cut n (to nodes)

var z;
var mu {A} >= 0;

maximize Z: z;

subject to cuts {k in CUTS}: z <= 
    sum {(i, j) in A} C[i, j] * FLOW[i, j, k] +
    sum {(i, j) in A} mu[i, j] * (FLOW[i, j, k] - Y[i, j]) +
    BIGM * sum {o in FN, l in O} AFO[o, l, k] +
    BIGM * sum {o in FN, i in N, l in O} AFD[o, i, l, k];
