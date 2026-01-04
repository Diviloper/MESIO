from amplpy import AMPL
import itertools


class Chars:
    def __init__(self):
        super().__init__()
        self.char = "A"

    def __call__(self) -> str:
        l = self.char
        self.char = chr(ord(self.char) + 1)
        return l


def solve_relaxation(
    n: int,
) -> tuple[dict[tuple[int, int], float], dict[tuple[int, int], str]]:
    ampl = AMPL()
    ampl.read("./lower_bounds/model.mod")
    ampl.read_data("./lower_bounds/data.dat")
    ampl.solve(solver="cplex")

    ampl.option["presolve"] = 0
    x = ampl.get_variable("x")

    return (
        {(i, j): x[i + 1, j + 1].value() for i in range(n) for j in range(i + 1, n)},
        {(i, j): x[i + 1, j + 1].sstatus() for i in range(n) for j in range(i + 1, n)},
    )


def sec_identification(original_arcs: dict[tuple[int, int], float]) -> str | None:
    arcs = original_arcs.copy()
    nodes: set[str | int] = set(range(23))
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
    sec_arcs = {
        arc: cost
        for arc, cost in original_arcs.items()
        if cost > 0 and arc[0] in sec_nodes and arc[1] in sec_nodes
    }

    print(
        " + ".join(f"x[{i}][{j}]" for i, j in sec_arcs.keys()),
        "=",
        sum(sec_arcs.values()),
        f"!<= {len(sec_nodes) - 1}",
    )

    constraint_sum = " + ".join(f"x[{i}][{j}]" for i, j in sec_arcs.keys())
    constraint = f"constraint {constraint_sum} <= {len(sec_nodes) - 1};"
    return constraint


def find_2match(arcs: dict[tuple[int, int], float]) -> str | None:
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
                    constraint_H = " + ".join(f"x[{i}][{j}]" for i, j in H_arcs.keys())
                    constraint_T = " + ".join(f"x[{i}][{j}]" for i, j in teeth)
                    constraint = f"constraint ({constraint_H}) + {constraint_T} <= 4;"
                    print(f"({constraint_H}) + {constraint_T} = {lhs} !<= {rhs}")
                    return constraint


def gomory_cut(arcs: dict[tuple[int, int], float], base_status: dict[tuple[int, int], str]) -> str | None:
    arc, cost = next((arc, cost) for arc, cost in arcs.items() if 0 < cost < 1 and base_status[arc] == "bas")
    print(f"Selected basic variable {arc} with cost {cost}")
    basic_arcs = {arc for arc, status in base_status.items() if status == "bas"}
    non_basic_arcs = {arc for arc, status in base_status.items() if status != "bas"}
    print(f"Basic arcs ({len(basic_arcs)}): {basic_arcs}")


if __name__ == "__main__":
    result, status = solve_relaxation(23)
    gomory_cut(result, status)
