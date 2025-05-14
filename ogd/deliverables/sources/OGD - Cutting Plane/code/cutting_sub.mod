# SubProblem Model
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
arc afd {o in FN, i in N, l in O} >= 0:  # Flow of articial arcs (to nodes)
    from AI [o, l], to I [i, l];

minimize w: 
    sum {(i, j) in A} C[i, j] * tf[i, j] +
    sum {(i, j) in A} MU[i, j] * (tf[i, j] - Y[i, j]) +
    BIGM * sum {o in FN, l in O} afo[o, l] +
    BIGM * sum {o in FN, i in N, l in O} afd[o, i, l];

subject to total_flow {(i, j) in A}: tf[i, j] = sum {l in O} flow[i, j, l];
subject to caps {(i, j) in A}: tf[i, j] <= Y[i, j];