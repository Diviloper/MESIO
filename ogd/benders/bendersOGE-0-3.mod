set N;
set O within N;
set A within N cross N; #arcos fijos
set Ahat within N cross N; #arcos añadibles
set AA:=A union Ahat; #todos los arcos

param xc {N};
param yc {N};
param t {i in N,l in O};
param c {(i,j) in AA, l in O} :=expresion;
param f {(i,j) in Ahat} := expresion;
param yb {(i,j) in Ahat};
param rho>0;
param Niter;
param nCUT;
param restric {(i,j) in Ahat, l in O,k in 1..nCUT};
param ybk {(i,j) in Ahat,k in 1..nCUT};

node I {i in N, l in O}: net_out=t[i,l]; # si positivo ==> inyección, 
                                         # si negativo extracción
arc xl {(i,j) in AA, l in O}>=0: from I [i,l], to I [j,l];

var y{(i,j) in Ahat} binary;

#Problema original
minimize z: 
   sum {(i,j) in Ahat} f[i,j]*y[i,j]+
   sum{l in O} (sum {(i,j) in AA} c[i,j,l]*xl[i,j,l]);

subject to caps1 {(i,j) in Ahat, l in O}:
    xl[i,j,l]<=rho*y[i,j];

#Subproblema 
minimize zd: sum{l in O} (sum {(i,j) in AA} c[i,j,l]*xl[i,j,l]);

subject to caps {(i,j) in Ahat, l in O}:
    xl[i,j,l]<=rho*yb[i,j];

#Master problem (yb)
param u {i in N, l in O,k in 1..nCUT}<=0;
var zmp;

minimize ZMP3:zmp3;

#
subject to Bcut {k in 1..nCUT}:
zmp3>=(sum {(i,j) in Ahat} f[i,j]*y[i,j])+  COMPLETE;      # COMPLETE