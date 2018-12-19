hx.userFacingText({
  paginator: {
    paginatorAria: 'Pagination navigation',
    currentPageAria: 'Current page, page $page',
    gotoPageAria: 'Goto page $page',
    prevPageAria: 'Goto previous page, page $page',
    nextPageAria: 'Goto next page, page $page',
    prev: 'Prev',
    next: 'Next',
  }
})

getRange = (obj) ->
  start = Math.max(1, obj.page - Math.floor(obj.visibleCount / 2))
  end = Math.min(start + obj.visibleCount, obj.pageCount + 1)
  start = Math.max(1, end - obj.visibleCount)
  {start: start, end: end}

makeItem = (page, currentPage) ->
  "#{page}#{if currentPage == page then '~' else ''}"

makeRange = (first, last) ->
  Array(last - first + 1).fill(0).map((_, index) -> index + first)

getPageItems = (currentPage = 1, pageCount, padding) ->
  items = if pageCount
    maxPadding = (padding * 2) + 1

    distanceFromStart = currentPage - maxPadding
    distanceFromEnd = -(currentPage + maxPadding - pageCount)

    # Calculate the contiguous page number links range tht includes the currentPage page
    [minPage, maxPage] =
      if distanceFromEnd >= distanceFromStart and distanceFromStart <= 0
        [1, Math.min(maxPadding, pageCount)]
      else if distanceFromEnd < 0
        [Math.max(pageCount - maxPadding + 1, 1), pageCount]
      else
        [Math.max(currentPage - padding, 1), Math.min(currentPage + padding, pageCount)]

    minPage = if minPage <= 3 then 1 else minPage;
    maxPage = if maxPage >= pageCount - 2 then pageCount else maxPage;

    [
      currentPage isnt 1 and 'prev'
      minPage > 1 and makeItem(1, currentPage)
      minPage > 2 and '...'
      makeRange(minPage, maxPage).map((p) -> makeItem(p, currentPage))...
      maxPage < pageCount - 1 and '...'
      maxPage < pageCount and makeItem(pageCount, currentPage)
      currentPage isnt pageCount and 'next'
    ]
  else
    [
      currentPage isnt 1 and 'prev',
      makeItem(currentPage, currentPage),
      'next'
    ]
  return items.filter((x) -> x)

class Paginator extends hx.EventEmitter
  constructor: (selector, options) ->
    super

    hx.component.register(selector, this)
    @container = hx.select(selector).classed('hx-paginator', true)

    @_ = hx.merge({
      page: 1,
      pageCount: 10,
      visibleCount: 10,
      updatePageOnSelect: true,
      v2Features: {
        padding: 2,
        useAccessibleRendering: false,
        dontRenderOnResize: false,
      },
      paginatorAria: hx.userFacingText('paginator', 'paginatorAria'),
      currentPageAria: hx.userFacingText('paginator', 'currentPageAria'),
      gotoPageAria: hx.userFacingText('paginator', 'gotoPageAria'),
      prevPageAria: hx.userFacingText('paginator', 'prevPageAria'),
      nextPageAria: hx.userFacingText('paginator', 'nextPageAria'),
      prevText: hx.userFacingText('paginator', 'prev'),
      nextText: hx.userFacingText('paginator', 'next'),
    }, options)

    @_.selector = selector

    if @_.v2Features.useAccessibleRendering
      # 2.x
      navItemEnter = () ->
        navItem = hx.detached('li')
          .class('hx-paginator-button-container')
          .add(hx.detached('a')
            .class('hx-paginator-button'))
        this.append(navItem).node()

      navItemUpdate = ({ text, aria, selected, disabled, isEllipsis, onClick }, element) ->
        navItem = hx.select(element)
          .classed('hx-paginator-selected-container', selected)
          .classed('hx-paginator-ellipsis-container', isEllipsis)

        link = navItem.select('a')
          .classed('hx-paginator-selected', selected)
          .attr('aria-current', if selected then true else undefined)
          .classed('hx-paginator-ellipsis', isEllipsis)
          .attr('aria-hidden', if isEllipsis then true else undefined)

        link.text(text)
        link.attr('aria-label', aria)
        link.off()
        if onClick
          link.on('click', 'hx.paginator', onClick)
          link.on('keypress', 'hx.paginator', (e) -> if e.which is 13 then onClick())

      links = hx.detached('ul')

      @view = links.view('li')
        .enter(navItemEnter)
        .update(navItemUpdate)

      nav = hx.detached('nav')
        .class('hx-paginator-nav')
        .attr('role', 'navigation')
        .attr('aria-label', @_.paginatorAria)
        .add(links)
        .attr('tabindex', '0')
        .on 'keydown', (e) =>
          currentPage = @page()
          currentPageCount = @pageCount()
          switch e.which
            when 37 # Left
              if currentPage isnt 1 then selectPage.call(this, 'user', currentPage - 1)
            when 39 # Right
              if currentPage isnt currentPageCount then selectPage.call(this, 'user', currentPage + 1)

      @container.add(nav)
    else
      # 1.x
      # go-to-start button
      self = this
      @container.append('button')
        .attr('type', 'button')
        .class('hx-btn ' + hx.theme.paginator.arrowButton)
          .add(hx.detached('i').class('hx-icon hx-icon-step-backward'))
          .on 'click', 'hx.paginator', ->
            if self._.pageCount is undefined
              selectPage.call(self, 'user', self._.page - 1)
            else
              selectPage.call(self, 'user', 0)

      pageButtons = @container.append('span').class('hx-input-group')
      @view = pageButtons.view('.hx-btn', 'button').update (d, e, i) ->
        @text(d.value)
          .attr('type', 'button')
          .classed('hx-paginator-three-digits', d.dataLength is 3)
          .classed('hx-paginator-more-digits', d.dataLength > 3)
          .classed(hx.theme.paginator.defaultButton, not d.selected)
          .classed(hx.theme.paginator.selectedButton, d.selected)
          .classed('hx-no-border', true)
          .on 'click', 'hx.paginator', -> selectPage.call(self, 'user', d.value)

      # go-to-end button
      @container.append('button')
        .attr('type', 'button')
        .class('hx-btn ' + hx.theme.paginator.arrowButton)
          .add(hx.detached('i').class('hx-icon hx-icon-step-forward'))
          .on 'click', 'hx.paginator', ->
            if self._.pageCount is undefined
              selectPage.call(self, 'user', self._.page + 1)
            else
              selectPage.call(self, 'user', self._.pageCount)

    if not @_.v2Features.dontRenderOnResize
      @container.on 'resize', 'hx.paginator', => @render()

    @render()

  setterGetter = (key, onChange) ->
    (val) ->
      # Set
      if arguments.length > 0
        this._[key] = val
        @render()
        return this
      # Get
      else
        return this._[key]

  pageCount: setterGetter('pageCount')
  visibleCount: setterGetter('visibleCount')
  updatePageOnSelect: setterGetter('updatePageOnSelect')
  paginatorAria: setterGetter('paginatorAria')
  currentPageAria: setterGetter('currentPageAria')
  gotoPageAria: setterGetter('gotoPageAria')
  prevPageAria: setterGetter('prevPageAria')
  nextPageAria: setterGetter('nextPageAria')
  prevText: setterGetter('prevText')
  nextText: setterGetter('nextText')

  selectPage = (cause, value = 1) ->
    currentPageCount = @pageCount()
    currentPage = @page()
    newPage = if currentPageCount is undefined
      Math.max(value, 1)
    else
      hx.clamp(1, currentPageCount, value)

    if newPage isnt currentPage
      if cause is 'api' or @updatePageOnSelect()
        this._.page = newPage
        @render()

      # DEPRECATED: 'selected' is deprecated in the event
      @emit('change', { cause, value, selected: value })

  page: (value) ->
    # Set
    if arguments.length > 0
      selectPage.call(this, 'api', value, true)
      return this
    # Get
    else
      return this._.page or 1

  render: () ->
    currentPage = @page()
    currentPageCount = @pageCount()
    data = if @_.v2Features.useAccessibleRendering
      getPageItems(currentPage, currentPageCount, this._.v2Features.padding).map (item) =>
        if item is 'prev'
          return {
            text: @prevText(),
            aria: @prevPageAria().replace('$page', currentPage - 1),
            onClick: () => selectPage.call(this, 'user', currentPage - 1),
          }
        if item is 'next'
          return {
            text: @nextText(),
            aria: @nextPageAria().replace('$page', currentPage + 1),
            onClick: () => selectPage.call(this, 'user', currentPage + 1),
          }
        if item is '...'
          return {
            isEllipsis: true,
          }

        selected = item.indexOf('~') > -1
        numericItem = parseInt(item)
        aria = if selected then @currentPageAria() else @gotoPageAria()
        return {
          text: numericItem,
          aria: aria.replace('$page', numericItem),
          selected: selected,
          onClick: () => selectPage.call(this, 'user', numericItem)
        }
    else
      if currentPageCount is undefined
        [{
          value: currentPage
          selected: true
          dataLength: currentPage.toString().length
        }]
      else
        {start, end} = getRange(this._)

        maxLength = Math.max(start.toString().length, (end - 1).toString().length)
        buttonSize = 30 + (5 * Math.max(0, maxLength - 2))

        # 85 is the width of the back/forward buttons which never changes
        buttonSpace = this.container.width() - 81
        maxButtons = Math.floor(buttonSpace / buttonSize)
        visibleCount = Math.min(maxButtons, this._.visibleCount)
        visibleCount = Math.max(visibleCount, 1)

        # XXX: Probably shouldn't run this twice every time
        {start, end} = getRange(this._)

        hx.range(end - start).map (i) =>
          {
            value: start + i
            selected: this._.page == start + i
            dataLength: maxLength
          }

    this.view.apply(data)

hx.paginator = (options) ->
  selection = hx.detached('div')
  new Paginator(selection.node(), options)
  selection

hx.Paginator = Paginator

hx._.paginator = {
  getPageItems
}
