int: n;
set of int: N = 1..n; % Nodes

array[N, N] of int: c; % Arc cost

array[N, N] of var 0.0..1.0: x; % Arc used

constraint forall(i in N) (x[i, i] = 0); % Don't use fake self arcs

constraint forall(i in N) (
  sum(j in N) (x[i, j]) = 1
);

solve minimize sum(i, j in N) (c[i, j] * x[i, j]);

output [
    "Pairs where x[i,j] > 0:\n"
] ++ 
[
    "(" ++ show(i) ++ "," ++ show(j) ++ ")\t= " ++ show(x[i,j]) ++ "\n"
    | i, j in N 
    where fix(x[i,j]) > 0.0
] ++ [
    "Total Cost: " ++ show(sum(i, j in N) (c[i, j] * x[i, j])) ++ "\n"
];