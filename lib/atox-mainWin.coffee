{View, jQuery, $, $$, $$$} = require 'space-pen'

class MainWindow extends View
   @content: ->
      @div =>
         @h1 "Main Window"
