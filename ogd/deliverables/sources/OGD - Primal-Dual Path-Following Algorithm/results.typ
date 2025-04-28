#let problem_dimensions(values) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(y: 1): strong
  set table(align: (x, y) => if x == 0 or y < 2 { center + horizon } else { right })
  
  table(
    columns: 10,
    row-gutter: (auto, 2.2pt, auto),
    column-gutter: (2.2pt, auto, auto, auto, 2.2pt, auto),
    table.cell(rowspan: 2, [Problem]),
    table.cell(colspan: 4, [Dimensions]),
    table.cell(colspan: 5, [Standardized Dimensions]),
    [N], [M], [Size], [NZ],
    [SEF], [SN], [SM], [SSize], [SNZ],
    ..values.flatten(),
  )
  
}

#let step_comparison(values) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(y: 1): strong
  set table(align: (x, y) => if x == 0 or y < 2 { center + horizon } else { right })
  
  table(
    columns: 7,
    row-gutter: (auto, 2.2pt, auto),
    column-gutter: (2.2pt, auto, auto, 2.2pt, auto),
    table.cell(rowspan: 2, [Problem]),
    table.cell(colspan: 3, [Newton]),
    table.cell(colspan: 3, [Mehrotra]),
    [Base], [Augmented], [Normal],
    [Base], [Augmented], [Normal],
    ..values.flatten(),
  )
}

#let solver_comparison(values) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(y: 1): strong
  set table(align: (x, y) => if x == 0 or y < 2 { center + horizon } else { right })
  
  table(
    columns: 10,
    row-gutter: (auto, 2.2pt, auto),
    column-gutter: (2.2pt, auto, auto, 2.2pt, auto, auto, 2.2pt, auto),
    table.cell(rowspan: 2, [Problem]),
    table.cell(colspan: 3, [PDPF]),
    table.cell(colspan: 3, [Tulip]),
    table.cell(colspan: 3, [HiGHS]),
    [Iter], [Cost], [Time],
    [Iter], [Cost], [Time],
    [Iter], [Cost], [Time],
    ..values.map(row => {
      row.remove(12)
      row.remove(8)
      row.remove(4)
      return row
    }).flatten(),
  )
}