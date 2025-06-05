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
param DELTA;
param CONGESTION;
param T { i in N, k in O } :=
    if i in DxO[k] then -CONGESTION * G[k, i]
    else if i = k then sum {j in DxO[k]} CONGESTION * G[k, j] 
    else 0;

node I {i in N, k in O}: net_out = T[i, k];

arc f { (i, j) in A, k in O } >= 0,
    from I[i, k], to I[j, k] ;

var tf { (i, j) in A };

subject to flux_total { (i, j) in A }:
    tf[i, j] = sum { k in O } f[i, j, k];

minimize F: sum{(i, j) in A} (C[i,j] * tf[i,j] + 0.5 * DELTA * tf[i, j]^2);