{View, $, $$} = require 'atom-space-pen-views'



module.exports =
class Button extends View
  @content: (name, type) ->
    num = parseInt ( Math.random() * 100000000 ), 10

    @div id: "aTox-Button-#{num}-#{type}", class: "aTox-Button-#{type}", => @raw "#{name}"
