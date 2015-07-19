{View} = require 'atom-space-pen-views'

module.exports =
class FriendRequestView extends View
  @content: (params) ->
    @div         class: 'block atox-friendRequestRoot', =>
      @h1        "Received a friend request"
      @div       class: 'form block', =>
        @div     class: 'block', =>
          @h2    "Friend ID:"
          @label params.id
        @div     class: 'block', =>
          @h2    "Message:"
          @label params.msg
      @div       class: 'block btn-group btn-group-lg btns', =>
        @div     class: 'btn btn-success icon icon-check', outlet: 'accept',  "Accept"
        @div     class: 'btn btn-error   icon icon-x',     outlet: 'decline', "Decline"

  initialize: (params) ->
    @aTox = params.aTox

    @accept.click =>
      @panel.destroy()
      params.accept()

    @decline.click =>
      @panel.destroy()
      params.decline()

    @panel = atom.workspace.addModalPanel "item": this, "visible": true
