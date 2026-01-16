import itertools
import json
import shutil
from math import floor

import cplex
import matplotlib.pyplot as plt
import networkx as nx
import pandas as pd
from amplpy import AMPL


class Chars:
    def __init__(self):
        super().__init__()
        self.char = "A"

    def __call__(self) -> str:
        l = self.char
        self.char = chr(ord(self.char) + 1)
        return l


num_cuts = 0

Arc = tuple[int, int]
ArcsAssignation = dict[Arc, float]


def solve_relaxation() -> tuple[ArcsAssignation, float]:
    ampl = AMPL()
    ampl.read("./lower_bounds/model.mod")
    ampl.read("./lower_bounds/cuts.mod")
    ampl.read_data("./lower_bounds/data.dat")
    ampl.solve(solver="cplex")

    x = ampl.get_variable("x")
    n = 23

    return {
        (i, j): x[i, j].value() for i in range(1, n + 1) for j in range(i + 1, n + 1)
    }, ampl.get_objective("Total_Cost").value()


def solve_ilp() -> tuple[ArcsAssignation, float]:
    ampl = AMPL()
    ampl.read("./lower_bounds/model_ilp.mod")
    ampl.read("./lower_bounds/cuts.mod")
    ampl.read_data("./lower_bounds/data.dat")
    ampl.solve(solver="cplex")

    x = ampl.get_variable("x")
    n = 23

    return {
        (i, j): x[i, j].value() for i in range(1, n + 1) for j in range(i + 1, n + 1)
    }, ampl.get_objective("Total_Cost").value()


def is_circuit(arcs: ArcsAssignation) -> bool:
    if any(not v.is_integer() for v in arcs.values()):
        return False

    return connected_components(arcs) == 1


def connected_components(arcs: ArcsAssignation) -> int:
    visited = set()
    non_visited = set(range(1, 24))
    stack = []
    cc = 0

    while len(non_visited) > 0:
        stack.append(next(iter(non_visited)))
        while stack:
            curr = stack.pop()
            if curr not in visited:
                visited.add(curr)
                non_visited.remove(curr)
                connected = [
                    i for (i, j), cost in arcs.items() if cost > 0 and j == curr
                ] + [j for (i, j), cost in arcs.items() if cost > 0 and i == curr]
                stack.extend(connected)
        cc += 1

    return cc


def sec_identification(original_arcs: ArcsAssignation) -> str | None:
    arcs = original_arcs.copy()
    nodes: set[str | int] = set(range(1, 24))
    node_map = {i: {i} for i in nodes}
    next_key = Chars()
    while True:
        if any(arc > 1 for arc in arcs.values()):
            # SEC found
            break
        if len(nodes) == 1 or all(arc < 1 for arc in arcs.values()):
            # No SEC can be found
            print("No SEC can be found")
            return None

        i, j = next(arc for arc, cost in arcs.items() if cost == 1)
        node_id = next_key()

        print(
            f"Merging node {i} ({node_map[i]}) and node {j} ({node_map[j]}) into node {node_id}"
        )

        node_map[node_id] = node_map[i] | node_map[j]

        nodes.remove(i)
        nodes.remove(j)
        nodes.add(node_id)

        new_arcs = {
            (node, node_id): arcs.get((i, node), 0)
            + arcs.get((node, i), 0)
            + arcs.get((j, node), 0)
            + arcs.get((node, j), 0)
            for node in nodes
        }
        arcs = new_arcs | {
            arc: cost for arc, cost in arcs.items() if i not in arc and j not in arc
        }

    i, j = next(arc for arc, cost in arcs.items() if cost > 1)

    sec_nodes = node_map[i] | node_map[j]
    print(f"Subtour found between nodes {sec_nodes}")
    sec_arcs = {
        arc: cost
        for arc, cost in original_arcs.items()
        if cost > 0 and arc[0] in sec_nodes and arc[1] in sec_nodes
    }

    print(
        " + ".join(f"x[{i}, {j}]" for i, j in sec_arcs.keys()),
        "=",
        sum(sec_arcs.values()),
        f"!<= {len(sec_nodes) - 1}",
    )

    constraint_sum = " + ".join(f"x[{i}, {j}]" for i, j in sec_arcs.keys())
    constraint = f"{constraint_sum} <= {len(sec_nodes) - 1};"
    return constraint


def find_2match(arcs: ArcsAssignation) -> str | None:
    nodes = {i for i, j in arcs.keys()} | {j for i, j in arcs.keys()}
    for H in itertools.combinations(nodes, 3):
        H_set = set(H)
        possible_teeth: list[tuple[int, int]] = []
        for u, v in arcs.keys():
            if (u in H_set) != (v in H_set):
                possible_teeth.append((u, v))

        for teeth in itertools.combinations(possible_teeth, 3):
            if len({n for tooth in teeth for n in tooth}) == 6:
                # Found a valid set of Handle and Teeth
                edges_in_H = [tuple(e) for e in itertools.combinations(H, 2)]
                sum_H = sum(arcs.get(e, 0.0) for e in edges_in_H)

                sum_T = sum(arcs.get(t, 0.0) for t in teeth)

                lhs = sum_H + sum_T
                rhs = 4

                if lhs > rhs + 1e-6:
                    H_arcs = {
                        arc: cost
                        for arc, cost in arcs.items()
                        if arc[0] in H and arc[1] in H
                    }
                    constraint_H = " + ".join(f"x[{i}, {j}]" for i, j in H_arcs.keys())
                    constraint_T = " + ".join(f"x[{i}, {j}]" for i, j in teeth)
                    constraint = f"({constraint_H}) + {constraint_T} <= 4;"
                    print(f"({constraint_H}) + {constraint_T} = {lhs} !<= {rhs}")
                    return constraint


def ampl_to_cplex(out_path: str = "./lower_bounds/cplex_model.mps") -> None:
    print("Reading AMPL model")
    ampl = AMPL()
    ampl.read("./lower_bounds/model.mod")
    ampl.read("./lower_bounds/cuts.mod")
    ampl.read_data("./lower_bounds/data.dat")
    print("Exporting AMPL model")
    try:
        ampl.eval("write mmodel.lp;")
    except:
        pass
    shutil.move("model.lp.mps", out_path)


def find_gomory_cut() -> list[str]:
    ampl_to_cplex()
    print("Loading model in CPLEX")
    prob = cplex.Cplex("./lower_bounds/cplex_model.mps")
    prob.solve()

    r = iter(range(1, 400))
    var_map = {
        f"C{next(r):04d}": f"x[{i}, {j}]"
        for i in range(1, 24)
        for j in range(i + 1, 24)
    }

    sol_values = prob.solution.get_values()
    var_names = prob.variables.get_names()

    basic = prob.solution.basis.status.basic
    status = prob.solution.basis.get_basis()[0]

    header: list[tuple[int, float]] = list(zip(*prob.solution.basis.get_header()))

    print("\n".join(f"{var_map[var_names[var]]},{val}" for var, val in header))

    cuts = []

    for tableau_row_idx, (basic_variable, base_value) in enumerate(header):
        if basic_variable < 0:
            print("Ignoring basic slack variable")
            continue
        if base_value.is_integer():
            print("Ignoring integer basic variable")
            continue

        print(
            f"Selected variable {var_map[var_names[basic_variable]]} {var_names[basic_variable]} (tableau index {tableau_row_idx}) with value {sol_values[basic_variable]})"
        )

        tableau_row = prob.solution.advanced.binvarow(tableau_row_idx)
        print(f"Tableau row lenght: {len(tableau_row)}")

        rhs = floor(sol_values[basic_variable])
        cut_indices = [basic_variable]
        cut_coeffs = [1]
        for i, coeff in enumerate(tableau_row):
            if status[i] != basic and floor(coeff) != 0:
                cut_indices.append(i)
                cut_coeffs.append(floor(coeff))
        lhs = sum(c * sol_values[i] for i, c in zip(cut_indices, cut_coeffs))

        if lhs <= rhs:
            print(f"Gomory cut invalid ({lhs} <= {rhs}). Moving to next basic variable")
            continue

        constraint_sum = (
            " + ".join(
                f"{c}*{var_map[var_names[i]]}" for i, c in zip(cut_indices, cut_coeffs)
            )
            .replace("+ -", "- ")
            .replace("1*", "")
        )
        constraint = f"{constraint_sum} <= {rhs};"
        print(constraint)
        print(f"Unsatisfied for current solution: {lhs} !<= {rhs}")
        cuts.append(constraint)

    if len(cuts) == 0:
        print("No valid cut was found")
    return cuts


def export_arcs_to_csv(
    arcs: ArcsAssignation, out_path: str, include_empty_arcs: bool = True
) -> None:
    data = [
        f"{i},{j},{cost}"
        for (i, j), cost in arcs.items()
        if include_empty_arcs or cost > 0
    ]
    with open(out_path, "w+", encoding="utf8") as f:
        f.write("i,j,cost\n")
        f.write("\n".join(data))


def arcs_as_dataframe(arcs: ArcsAssignation) -> pd.DataFrame:
    data = [(i, j, cost) for (i, j), cost in arcs.items()]
    return pd.DataFrame(data=data, columns=["i", "j", "value"])


def clear_cuts() -> None:
    global num_cuts
    num_cuts = 0
    with open("./lower_bounds/cuts.mod", "w+") as f:
        pass


def add_cut(cut: str, cut_type: str) -> None:
    global num_cuts
    num_cuts += 1
    with open("./lower_bounds/cuts.mod", "a+", encoding="utf8") as f:
        f.write(f"# ---------- {cut_type} cut ----------\n")
        f.write(f"subject to Cut_{cut_type}_{num_cuts}: {cut}\n\n")


def paint_graph(
    arcs: ArcsAssignation,
    personalized_arcs: dict[Arc, dict] | None = None,
    personalized_nodes: dict[int, dict] | None = None,
    axes: plt.Axes | None = None,
):
    personalized_arcs = personalized_arcs or {}
    personalized_nodes = personalized_nodes or {}
    axes = axes or plt.gca()

    with open("lower_bounds/locations.json", "r", encoding="utf8") as f:
        locations = json.load(f)
        locations = {i + 1: loc for i, loc in enumerate(locations)}

    graph = nx.Graph()

    for arc, arc_value in arcs.items():
        graph.add_edge(*arc)

    nodes = [n for n in range(1, 24) if n not in personalized_nodes]

    full_arcs = [
        arc
        for arc, value in arcs.items()
        if value == 1 and arc not in personalized_arcs
    ]
    half_arcs = [
        arc
        for arc, value in arcs.items()
        if value == 0.5 and arc not in personalized_arcs
    ]
    quarter_arcs = [
        arc
        for arc, value in arcs.items()
        if value == 0.25 and arc not in personalized_arcs
    ]
    three_quarters_arcs = [
        arc
        for arc, value in arcs.items()
        if value == 0.75 and arc not in personalized_arcs
    ]

    nx.draw_networkx_nodes(
        graph, locations, nodelist=nodes, node_size=500, node_color="lightblue", ax=axes
    )
    for node, config in personalized_nodes.items():
        nx.draw_networkx_nodes(
            graph, locations, nodelist=[node], node_size=500, **config, ax=axes
        )
    nx.draw_networkx_labels(graph, locations, font_size=10, ax=axes)
    nx.draw_networkx_edges(
        graph, locations, edgelist=full_arcs, width=2, edge_color="black", ax=axes
    )
    nx.draw_networkx_edges(
        graph,
        locations,
        edgelist=half_arcs,
        width=2,
        edge_color="black",
        style="dashed",
        ax=axes,
    )
    nx.draw_networkx_edges(
        graph,
        locations,
        edgelist=quarter_arcs,
        width=2,
        edge_color="black",
        style="dotted",
        ax=axes,
    )
    nx.draw_networkx_edges(
        graph,
        locations,
        edgelist=three_quarters_arcs,
        width=2,
        edge_color="black",
        style="dashdot",
        ax=axes,
    )
    for arc, config in personalized_arcs.items():
        nx.draw_networkx_edges(
            graph, locations, edgelist=[arc], width=2, **config, ax=axes
        )

    axes.axis("off")


if __name__ == "__main__":
    result = solve_relaxation()
