#let fw_results_table(path, height) = {
  let cells = csv(path).flatten();
  show table.cell.where(y: 0): strong
  set table(align: (x, y) => if y == 0 { center + horizon } else { right })
  show table.cell : c => {
    if c.y == 0 {return text(0.8em, c)}
    else {return text(0.7em, font: "JetBrains Mono", c)}
  }
  block(
    breakable: true,
    width: 100%,
    height: height,
    columns(
      2,
      gutter: 16pt,
      table(
        columns: 4,
        row-gutter: (2.2pt, auto),
        column-gutter: (2.2pt, auto),
        table.header([I], [Obj. Fun.], [Rel. Gap], [Step ($alpha$)]),
        ..cells
      )
    )
  )
}

#let rsd_results_table(path, height) = {
  let cells = csv(path).flatten();
  show table.cell.where(y: 0): strong
  set table(align: (x, y) => if y == 0 { center + horizon } else { right })
  show table.cell : c => {
    if c.y == 0 {return text(0.8em, c)}
    else {return text(0.7em, font: "JetBrains Mono", c)}
  }
      table(
        columns: 9,
        row-gutter: (2.2pt, auto),
        column-gutter: (2.2pt, auto, 2.2pt, auto),
        table.header(
          [I],
          [Obj. Fun.],
          [Rel. Gap],
          [\#V],
          [$alpha_0$],
          [$alpha_1$],
          [$alpha_2$],
          [$alpha_3$],
          [$alpha_4$],
        ),
        ..cells.map(x => if x != "-" and float(x) < 1e-8 {"-"} else {x})
  )
}