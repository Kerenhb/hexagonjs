import { select, div } from 'utils/selection'
import { fixed } from 'utils/format'
import { clamp, isObject, merge } from 'utils/utils'
import { EventEmitter } from 'utils/event-emitter'
import { Map as HMap } from 'utils/map'

posToValue = (unit) ->
  if @_.isDiscrete then posToDiscrete.call this, unit
  else (unit * (@options.max - @options.min)) + @options.min

discreteToPos = (discrete) -> @_.discreteValues.get(discrete)

posToDiscrete = (pos) ->
  _ = @_
  space = _.discreteSpacing / 2
  for [k, v] in _.discreteValues.entries()
    if pos >= (v - space) and pos < (v + space)
      return k
  return pos

# Slide handles all the value updating, including working out which control
# is being dragged.
slide = (e) ->
  _ = @_
  _.mouseDown = true

  _.pointerMoveHandler = (e) => slide.call this, e
  _.pointerUpHandler = (e) => slideEnd.call this, e

  select(document).on 'pointermove', 'hx.slider', _.pointerMoveHandler
  select(document).on 'pointerup', 'hx.slider', _.pointerUpHandler

  _.slidableWidth = if @options.type is 'range'
    _.container.width() - _.controlWidth
  else _.container.width()

  e.event.preventDefault()

  pos = clamp(0, _.container.width(), (e.x - _.container.box().left)) / _.slidableWidth

  val = {}

  if @options.type is 'range'
    start = if _.isDiscrete then discreteToPos.call this, @values.start else @values.start
    end = if _.isDiscrete then discreteToPos.call this, @values.end else @values.end

    start = (start - @options.min) / (@options.max - @options.min)
    end = (end - @options.min) / (@options.max - @options.min)

    diff = (end - start) / 2

    offset = (_.controlWidth / _.slidableWidth)

    isEnd = (pos - offset / 2) >= (end - diff)

    if _.dragging is 'end' or (isEnd and _.dragging isnt 'start')
      _.dragging = 'end'
      pos -= offset
      pos = clamp(start, 1, pos)
      val.end = posToValue.call this, pos
    else
      _.dragging = 'start'
      pos = clamp(0, end, pos)
      val.start = posToValue.call this, pos
  else
    _.dragging = 'value'
    val.value = posToValue.call this, pos

  prevValue = @value()
  @value(val)
  if prevValue isnt @value()
    @emit 'change', @value()
  return

slideEnd = (e) ->
  _ = @_
  if _.mouseDown
    select(document).off 'pointermove', 'hx.slider', _.pointerMoveHandler
    select(document).off 'pointerup', 'hx.slider', _.pointerUpHandler
    _.mouseDown = false
    _.dragging = undefined
    node = _.range.select('.hx-slider-active')
    node.morph()
      .with('delay', 100)
      .then('fadeout', 200)
      .then ->
        node.classed('hx-slider-active', false)
        _.valueVis = false
      .go(true)

  @emit 'slideend', @value()

# Render values handles the updates to the slider itself.
renderValues = ->
  _ = @_

  points = _.container.selectAll('.hx-slider-point')
  if not points.empty()
    height = points.nodes[0].offsetHeight
    points.forEach (d) ->
      d.style('width', height + 'px')
        .style('margin-left', - height / 2 + 'px')

  if @options.type is 'range'
    startValue = if _.isDiscrete then discreteToPos.call this, @values.start else @values.start
    endValue = if _.isDiscrete then discreteToPos.call this, @values.end else @values.end
  else
    startValue = @options.min
    endValue = if _.isDiscrete then discreteToPos.call this, @values.value else @values.value

  if not _.isDiscrete
    startValue = (startValue - @options.min) / (@options.max - @options.min)
    endValue = (endValue - @options.min) / (@options.max - @options.min)

  _.range.style('left', startValue * 100 + '%')
    .style('width', (endValue - startValue) * 100 + '%')

  if _.dragging is 'start'
    node = _.valueL
    val = @values.start
  else if _.dragging?
    node = _.valueR
    val = if _.dragging is 'end' then @values.end else @values.value

  if node? and val?
    if not _.valueVis
      _.valueVis = true
      node.classed('hx-slider-active', true)
        .classed('hx-slider-under', false)

      # Check if the value box will go off the screen, we must do an extra render here
      # to get the correct height for the label
      @options.renderer(this, node.node(), val)
      box = node.box()
      node.classed('hx-slider-under', box.top - box.height < 0)

      node.morph()
        .with('fadein', 30)
        .go(true)

    @options.renderer(this, node.node(), val)
  return


class Slider extends EventEmitter
  constructor: (@selector, options = {}) ->
    super()

    @options = merge({
      type: 'slider'
      discreteValues: undefined
      # XXX Breaking: Renderer
      renderer: (slider, elem, value) -> select(elem).text(fixed(value))
      min: 0
      max: 1
      step: undefined
      disabled: false
    }, options)

    @_ = _ = {}

    _.isDiscrete = @options.discreteValues?.length > 0 or @options.step?

    self = this
    _.container = select(@selector)
      .classed('hx-slider', true)
      .api('slider', this)
      .api(this)
      .append('div').classed('hx-slider-inner', true)
      .classed('hx-slider-double', @options.type is 'range')
      .classed('hx-slider-discrete', _.isDiscrete)
      .on 'pointerdown', 'hx.slider', (e) =>
        if not _.disabled
          @emit 'slidestart', @value()
          slide.call this, e

    _.range = _.container.append('div').class('hx-slider-range')

    _.controlWidth ?= Number(window.getComputedStyle(_.range.node(), ':after').width.replace('px', ''))

    _.valueL = _.range.append('div').class('hx-slider-value').style('left', 0)
    _.valueR = _.range.append('div').class('hx-slider-value').style('left', '100%')

    _.slidableWidth = if @options.type is 'range'
      _.container.width() - _.controlWidth
    else _.container.width()

    if @options.step?
      steps = []
      curr = @options.min
      while curr <= @options.max
        steps.push(curr)
        curr += @options.step
      @options.max = 1
      @options.min = 0
      @discreteValues(steps, false)
    else if _.isDiscrete
      @discreteValues(@options.discreteValues, false)

    inc = (@options.max - @options.min)
    min = (0.25 * inc) + @options.min
    mid = (0.5 * inc) + @options.min
    max = (0.75 * inc) + @options.min

    if @options.type is 'range'
      start = if @options.start? then @options.start
      else if _.isDiscrete then posToDiscrete.call this, min
      else min

      end = if @options.end? then @options.end
      else if _.isDiscrete then posToDiscrete.call this, max
      else max

      @values =
        start: start
        end: end
    else
      value = if @options.end? then @options.end
      else if _.isDiscrete then posToDiscrete.call this, mid
      else mid

      @values =
        value: value

    if @values.value
      @value(@values.value)
    else
      @value({start: @values.start, end: @values.end})

    if @options.disabled then @disabled(@options.disabled)


  discreteValues: (array, render = true) ->
    if array?
      @options.discreteValues = array
      _ = @_
      _.isDiscrete = @options.discreteValues?.length > 0 or @options.step?
      _.discreteValues = new HMap()
      _.discreteSpacing = (1 / (array.length - 1))

      _.container.selectAll('.hx-slider-point').remove()

      for i in [0...array.length]
        pos = i * _.discreteSpacing
        _.discreteValues.set(array[i], pos)
        if @options.type is 'range' or i > 0
          point = _.range.insertBefore('div').class('hx-slider-point')
            .style('left', pos * 100 + '%')

      if render
        renderValues.call this
      this
    else
      @options.discreteValues

  max: (max) ->
    if arguments.length > 0
      @options.max = max
      renderValues.call this
      this
    else
      @options.max

  step: (step) ->
    if arguments.length > 0
      @options.step = step
      renderValues.call this
      this
    else
      @options.step

  min: (min) ->
    if arguments.length > 0
      @options.min = min
      renderValues.call this
      this
    else
      @options.min

  value: (value) ->
    if arguments.length > 0
      clampValue = (val) =>
        if @_.isDiscrete then val else clamp(@options.min, @options.max, val)

      if @options.type is 'range'
        if value.start? then @values.start = clampValue(value.start)
        if value.end? then @values.end = clampValue(value.end)
      else
        if isObject(value)
          if value.value? then @values.value = clampValue(value.value)
        else
          if value? then @values.value = clampValue(value)

      renderValues.call this
      this
    else
      if @options.type is 'range'
        {
          start: @values.start
          end: @values.end
        }
      else
        @values.value

  renderer: (f) ->
    if f?
      @options.renderer = f
      this
    else
      @options.renderer

  disabled: (disable) ->
    if disable?
      @_.disabled = disable
      select(@selector).classed('hx-disabled', disable)
    else
      !!@_.disabled

slider = (options) ->
  selection = div()
  new Slider(selection.node(), options)
  selection

export {
  slider,
  Slider
}
