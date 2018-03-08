
colors = hx.theme.plot.colors

xLabels = 'ABCDEFGH'.split('')

createData = ->
  for label in xLabels
    x: label
    y: Math.random()*0.5+0.05

graph = new hx.Graph('#stacked-grouped-bar-chart')
axis = graph.addAxis({
  x:
    title: 'category'
    scaleType: 'discrete'
    formatter: (d) -> d
    discreteLabels: xLabels
  y:
    title: 'value'
    scalePaddingMax: 0.1
    min: 0
})

for i in [0..2]
  series = axis.addSeries('bar', {
    title: 'Stacked Bar Series ' + (i+1)
    data: createData()
    fillColor: hx.cycle(colors, i)
    group: 'group-1'
  })

for i in [0..2]
  series = axis.addSeries('bar', {
    title: 'Stacked Bar Series ' + (i+4)
    data: createData()
    fillColor: hx.cycle(colors, i+3)
    group: 'group-2'
  })

graph.render()
