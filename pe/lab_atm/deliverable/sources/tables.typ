#let result_table(deposit, shortage, total) = {
  show table.cell.where(y: 0): strong
  set table(align: (x, y) => if x == 0 or y == 0 { center } else { right })

  
  table(
    columns: (auto, auto),
    row-gutter: (2.2pt, auto, 2.2pt),
    table.header([Cost], [Value]),
    [Deposit], deposit,
    [Shortage], shortage,
    [Total], total,   
    )
}

#let variables_table(x, y) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(x: 0): strong
  set table(align: (x, y) => if x == 0 or y == 0 { center } else { right })
  
  table(
    columns: 2 + y.len(),
    row-gutter: (2.2pt, auto),
    column-gutter: (2.2pt, 2.2pt, auto),
    [Variable], [$x$], ..array.range(1, y.len() + 1).map(i => [$y_#i$]),
    [Value], [#x],
    ..y.map((v) => [#v]),
  )
}

#let evolution_table(iters) = {
  show table.cell.where(y: 0): strong
  show table.cell.where(x: 0): strong

  table(
    columns: 6,
    row-gutter: (2.2pt, auto),
    column-gutter: (2.2pt, auto, 2.2pt, auto),
    [Iteration], [Dual Cost], [Gap], [Total Cost], [$z$], [$x$],
    ..iters.map(x => if x.len() == 1 {return "Hey"} else {return x}).flatten()
    
  )
}