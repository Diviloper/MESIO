set nusos;
set centr within nusos;
set links within ( nusos cross nusos );
set origens within centr;
set destins within centr;
set odpair within ( origens cross destins );
set destperorig { i in origens } :=
setof { (i1, j1) in odpair : i = i1 } j1;

param g{odpair} >0;
param t0{links};
param c{links};
param cap{links};
param Tdreta { i in nusos, k in origens }:=
if i in destperorig[k] then -1.0*g[k, i]
else
if i = k then sum {j in destperorig[k]} g[k, j] else 0;

node N {i in nusos, k in origens}: net_out = Tdreta[i, k];

arc v_k { (i, j) in links, k in origens } >= 0,
from N[i, k], to N[j, k] ;

var v { (i, j) in links };

subject to flux_total { (i, j) in links }:
v[i, j] = sum { k in origens } v_k[i, j, k];

minimize Vg: sum { (i, j) in links } v[i, j]*t0[i, j];
minimize Vnl: ; # COMPLETE