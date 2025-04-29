# Model original
set N;
set O within N;
set A within N cross N; #arcos fijos

param M >0;
param y{A} default M;
param xc {N};
param yc {N};
param t {i in N,l in O};
param c {(i,j) in A, l in O} :=150+(((xc[i]-xc[j])^2)+((yc[i]-yc[j])^2));
param rho>0;

var xx{A};
node I {i in N, l in O}: net_out=t[i,l]; #si positivo ==> inyección, si negativo extracción
arc xl {(i,j) in A, l in O}>=0: from I [i,l], to I [j,l];

subject to total_flow {(i,j) in A}: xx[i,j] = sum{l in O} xl[i,j,l];
minimize COST: sum{l in O} (sum {(i,j) in A} c[i,j,l]*xl[i,j,l]);

subject to caps {(i,j) in A}: xx[i,j]<=y[i,j];

