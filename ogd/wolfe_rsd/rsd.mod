# Common
set N;
set A within ( N cross N );
set O within N;
set D within N;
set OD := ( O cross D );        # Origin-Destination Pairs
set DxO { o in O } :=           # Set of Destinations for each Origin
    setof { (i, j) in OD : o = i } j; 

param XC {N};                   # Node X Coordinate
param YC {N};                   # Node Y Coordinate

param G {OD} > 0;               # Required flow
param C { (i, j) in A } :=
  95 + (XC[i] - XC[j])^2 + 8*(YC[i] - YC[j])^2;
param S {A};                   # Link Cost
param DELTA;
param CONGESTION;
param T { i in N, k in O } :=
    if i in DxO[k] then -CONGESTION * G[k, i]
    else if i = k then sum {j in DxO[k]} CONGESTION * G[k, j] 
    else 0;

# SubProblem
node I {i in N, k in O}: net_out = T[i, k];

arc f { (i, j) in A, k in O } >= 0,
    from I[i, k], to I[j, k] ;

var tf {A};

subject to total_flux { (i, j) in A }:
    tf[i, j] = sum { k in O } f[i, j, k];

minimize Gradient_F: sum { (i, j) in A } tf[i, j] * S[i, j];


# Master Problem
param RHO;
param W {0..RHO, A} default 0;
param USED_INDICES {0..RHO};

var alpha {0..RHO} >= 0;
var x {A} >= 0;

subject to used_indices_alpha {r in 0..RHO}:
    alpha[r] <= USED_INDICES[r];

subject to unit_alpha_sum:
    sum {r in 0..RHO} alpha[r] = 1;

subject to convex_hull_alpha {(i, j) in A}:
    x[i, j] = sum {r in 0..RHO} alpha[r] * W[r, i, j];

minimize F: sum{(i, j) in A} (C[i,j] * x[i,j] + 0.5 * DELTA * x[i, j]^2);
