class Dashing.Table extends Dashing.Widget

  ready: ->
    @table = $(@node).find('table')[0]
    console.log(@table)

  onData: (data) ->
    console.log(@table)

