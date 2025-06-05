#import "@preview/cetz:0.3.2"
#import "@preview/cetz-plot:0.1.1": plot, chart

#let plot_log(size, data, x_index, y_index, x_label, y_label) = {
  cetz.canvas({
    let x = data.map(x => int(x.at(x_index)))
    let y = data.map(x => calc.log(float(x.at(y_index))))

    let axes = ("x", "y")
    let x2_label = none
    if y.sum() < 0 {
      axes = ("x2", "y")
      x2_label = x_label
      x_label = none
    }
    
    plot.plot(
      size: size,
      y-label: y_label,
      y-break: true,
      y-decimals: 4,
      x-label: x_label,
      x2-label: x2_label,
      {
        plot.add(axes: axes, x.zip(y))
      }
    )
  })
}
