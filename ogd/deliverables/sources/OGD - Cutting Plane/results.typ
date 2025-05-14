#let arc_costs_table(arcs) = {
  show table.cell.where(y: 0): strong
  
  table(
      columns: (auto, auto),
      row-gutter: (2.2pt, auto),
      [Arc], [Cost],

      ..arcs.map(
        a => (
          [#a.at(0) #sym.arrow #a.at(1)], 
          [#a.at(2)],
        )
      ).flatten()
    )
}

#let result_table(total) = {
  show table.cell.where(x: 0): strong
  set table(align: (x, y) => if x == 0 or y == 0 { center } else { right })

  
  table(
    columns: 2,
    [Total Cost], total
  )
}

#let result_iters_table(total, num_iterations) = {
  show table.cell.where(x: 0): strong
  set table(align: (x, y) => if x == 0 or y == 0 { center } else { right })

  
  table(
    columns: 2,
    [Total Cost], total,
    [Iterations], num_iterations
  )
}

#let new_caps_table(title, caps) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(y: 1): strong
  show table: set text(size: 0.9em)
  
  table(
    columns: 3,
    row-gutter: (2.2pt, auto),
    table.cell(colspan: 3, title),
    [Arc], [Total Flow], [Max Capacity],

    ..caps.map(a => (
      [#a.at(0) #sym.arrow #a.at(1)], 
      [#a.at(2)], [#a.at(3)]
    )).flatten() 
  )
}

#let arc_flows_table(title, arcs) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(y: 1): strong
  set table(fill: (x, y) => if y >= 2 and arcs.at(y - 2).at(4) == "true" {rgb("#fcb98b")} else {white})
  show table: set text(size: 0.9em)
  
  table(
    columns: (auto, auto),
    row-gutter: (2.2pt, auto),
    table.cell(colspan: 2, title),
    [Arc], [Flow],

    ..arcs.map(a => (
      [#a.at(0) #sym.arrow #a.at(1)], 
      [#a.at(3)]
    )).flatten() 
  )
}

#let iterations_table(iterations, height) = {
  show table.cell : c => {
    if c.y == 0 {return text(0.8em, c)}
    else {return text(0.65em, font: "JetBrains Mono", c)}
  }
  show table.cell.where(y: 0): strong
  set table(align: (x, y) => if x == 0 or y == 0 or x == 5 { center } else { right })
  block(
    height: height,
    width: 110%,
    breakable: true,
    columns(
      2,
      gutter: 4pt,
      table(
        columns: 6,
        row-gutter: (2.2pt, auto),
        column-gutter: (2.2pt, auto),
        table.header([Iter], [$z$], [$w$], [Gap], [Cost], [Feas]),
        ..iterations.map(row => (
          row.at(0),
          row.at(1),
          row.at(2),
          row.at(3),
          row.at(4),
          {if row.at(5) == "TRUE" [$checkmark$] else [$crossmark$]},
        )).flatten()
      )
    )
  )
}

#let dual_table(duals, title: "Dual Variables") = {
  show table.cell.where(x: 0): strong
  
  let cols = duals.len()
  table(
      columns: cols + 1,
      row-gutter: (2.2pt, auto),
      table.cell(colspan: cols + 1, title),
      [Cut], ..duals.map(r => r.at(0)),
      [$mu$], ..duals.map(r => r.at(1)),
      
    )
}