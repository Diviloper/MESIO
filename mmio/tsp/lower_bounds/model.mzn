int: n;
set of int: N = 1..n;       % Nodes

array[N, N] of int: c; % Arc cost

array[N, N] of var 0.0..1.0: x; % Arc used

constraint forall(i, j in N where i >= j) (x[i, j] = 0); % Don't use all arcs (only upper triangle without diagonal)

constraint forall(i in N) (
  sum(j in N) (x[i, j] + x[j, i]) = 2
);

solve minimize sum(i, j in N) (c[i, j] * x[i, j]);
