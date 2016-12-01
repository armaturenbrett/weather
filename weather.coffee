App.widget_data = App.cable.subscriptions.create channel: 'WidgetDataChannel', widget: 'weather',
  connected: ->
    console.log('weather connected')

  disconnected: ->
    console.log('weather disconnected')
    window.weatherWidget.resetTemplate()

  received: (data) ->
    console.log('weather received data:', data)
    window.weatherWidget.renderData(data)

class WeatherWidget
  _this = undefined

  constructor: ->
    _this = this

    this.$widget = $('.widget .weather')
    this.template = this.$widget[0].innerHTML

    @fitInSvg()
    $(window).on 'resize', @fitInSvg

    this.renderData(this.$widget.data('data'))

  fitInSvg: ->
    this.$widget = $('.widget .weather')
    $('svg', this.$widget).css('width', this.$widget.width()).css('height', this.$widget.height())

  resetTemplate: ->
    this.render(this.template, {})

  renderData: (data) ->
    this.render(this.template, data)

  render: (template, data) ->
    renderedTemplate = Mustache.render(template, data)
    this.$widget.html(renderedTemplate)
    this.fitInSvg()

$(document).ready ->
  window.weatherWidget = new WeatherWidget()
