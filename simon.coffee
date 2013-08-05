class Event
  constructor: (@name) ->
    @listeners = []

  subscribe: (callback) ->
    @listeners.push(callback)

  fire: ->
    for listener in @listeners
      listener()


class Simon
  constructor: (@btnCount) ->
    @wrongButton = new Event('wrongButton')
    @correctButton = new Event('correctButton')
    @patternComplete = new Event('patternComplete')
    @pattern = []
    @userPattern = []

  start: ->
    @pattern = []
    @userPattern = []
    @next()

  next: ->
    @userPattern = []
    @pattern.push(parseInt(Math.random() * @btnCount))

  handleButtonPress: (btnId) ->
    @userPattern.push(btnId)
    if @userPattern[@userPattern.length-1] is @pattern[@userPattern.length-1]
      if @userPattern.length == @pattern.length
        @next()
        @patternComplete.fire()
      else
        @correctButton.fire()
    else
      @wrongButton.fire()


class SimonUI
  constructor: (@buttons, @game) ->
    for button, idx in @buttons
      $(button).data('button-id', idx)
    @._initListeners()

  _initListeners: ->
    self = this

    @buttons.on 'click', (evt) ->
      evt.preventDefault()
      btnId = $(this).data('button-id')
      self.game.handleButtonPress(btnId)

    @game.wrongButton.subscribe ->
      self.handleWrongButton()

    @game.patternComplete.subscribe ->
      self.handlePatternComplete()

  start: ->
    @game.start()
    @demoPattern(@game.pattern)

  handleButtonPress: (btnNum) ->
    @game.handleButtonPress(btnNum)

  handleWrongButton: ->
    console.log 'wrong button'

  handleCorrectButton: ->
    console.log 'correct'

  handlePatternComplete: ->
    console.log 'pattern complete'
    @demoPattern(@game.pattern)

  demoPattern: (pattern) ->
    console.log "next pattern is #{pattern}"


$(->
  simon = new Simon 4
  simonUI = new SimonUI $('.simon-button'), simon
  simonUI.start()
)



# UI -> Game user pressed a button
# Game -> UI last button pressed was correct/wrong (game over)
# Game -> Here's the next pattern