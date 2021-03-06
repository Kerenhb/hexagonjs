import { userFacingText } from 'utils/user-facing-text'
import { mergeDefined } from 'utils/utils'
import { select, div } from 'utils/selection'

# Swaps out poor validation messages for more descriptive ones.
getValidationMessage = (message, type) ->
  switch message.toLowerCase()
    when 'value missing'
      if type is 'radio'
        userFacingText('form', 'missingRadioValue')
      else
        userFacingText('form', 'missingValue')
    when 'type mismatch'
      userFacingText('form', 'typeMismatch')
    else
      message

export validateForm = (formSelector, options) ->
  selection = select(formSelector)

  featureFlagMode = selection.classed('hx-flag-form')

  form = select(formSelector).node()

  defaultOptions = {
    showMessage: true
  }
  options = mergeDefined(defaultOptions, options)

  select(formSelector).selectAll('.hx-form-error').remove()

  errors = []

  focusedElement = document.activeElement

  for idx in [0...form.children.length]
    # Loop through all direct child divs of form element ()
    if form.children[idx].nodeName.toLowerCase() is 'div'
      element = form.children[idx].children[1]

      # Don't check the validity of hidden or undefined elements
      if element and element.offsetParent isnt null
        # Deal with standard label/input pairs
        if element.nodeName.toLowerCase() is 'input' or element.nodeName.toLowerCase() is 'textarea'
          if not element.checkValidity()
            type = select(element).attr('type')
            errors.push {
              message: getValidationMessage element.validationMessage, type
              node: element
              validity: element.validity
              focused: focusedElement is element
            }
        else
          # Deal with radio groups and other similar structured elements
          input = select(element).select('input').node()
          type  = select(element).select('input').attr('type')
          if input and not input.checkValidity()
            errors.push {
              message: getValidationMessage input.validationMessage, type
              node: element
              validity: input.validity
              focused: focusedElement is input
            }

  if options.showMessage and errors.length > 0
    if featureFlagMode
      selection.selectAll('.hx-form-message').remove()
      errors.forEach (error) ->
        select(error.node)
          .insertAfter(div('hx-form-message hx-form-message-wrap').text(error.message))

        select(error.node).on 'click', 'hx.form-error', (e) ->
          next = select(error.node.nextElementSibling)
          if next.classed('hx-form-message')
            next.remove()
          select(error.node).off('click', 'hx.form-error')
    else
      # Show the error for the focused element (if there is one) or the first error in the form
      error = errors.filter((error) -> error.focused)[0] or errors[0]

      # XXX: This structure lets us jump out of the forced table layout. If we change
      # to match the full-width aeris forms, this will need changing.
      select(error.node.parentNode)
        .insertAfter('div')
        .class('hx-form-error')
        .append('div')
        .insertAfter('div')
        .class('hx-form-error-text-container')
        .append('div')
        .class('hx-form-error-text')
        .text(error.message)

      select(error.node).on 'click', 'hx.form', (e) ->
        next = select(error.node.parentNode.nextElementSibling)
        if next.classed('hx-form-error')
          next.remove()
        select(error.node).off('click', 'hx.form')

  # Return the errors so we can still check how many there are.
  return {
    valid: errors.length is 0,
    errors: errors
  }
