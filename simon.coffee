class Event
  constructor: (@name) ->
    @listeners = []

  subscribe: (callback) ->
    @listeners.push(callback)

  fire: ->
    for listener in @listeners
      listener()


class AudioLoader
  readyCallback = null

  constructor: ->
    @filesToLoad = 0
    @filesLoaded = 0
    @audios = {}

  load: (uri) ->
    self = this
    audio = new Audio()
    callback = ->
      self.filesLoaded++
      self.checkReady()
    audio.addEventListener 'canplaythrough', callback, false
    audio.src = uri
    @audios[uri] = audio

  get: (uri) ->
    return @audios[uri]

  checkReady: ->
    if @filesToLoad is @filesLoaded
      if readyCallback
        readyCallback()
        readyCallback = null

  ready: (callback) ->
    readyCallback = callback
    @checkReady()


delay = (ms, func) -> setTimeout func, ms


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

  handleButtonPress: (btnNum) ->
    @userPattern.push(btnNum)
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
      $(button).data('button-num', idx)
    @._initListeners()
    @._loadAudio()

  _initListeners: ->
    self = this

    @buttons.on 'click', (evt) ->
      evt.preventDefault()
      btnNum = $(this).data('button-num')
      self.game.handleButtonPress(btnNum)

    @buttons.on 'mousedown', ->
      btnNum = $(this).data('button-num')
      self.playButtonSound(btnNum)

    @buttons.on 'mouseup', ->
      btnNum = $(this).data('button-num')
      self.stopButtonSound(btnNum)

    @game.wrongButton.subscribe ->
      self.handleWrongButton()

    @game.patternComplete.subscribe ->
      self.handlePatternComplete()

  _loadAudio: ->
    @audioLoader = new AudioLoader()
    for button, btnNum in @buttons
      @audioLoader.load(@_getButtonSoundUri(btnNum))

  _getButtonSoundUri: (btnNum) ->
    "sounds/btn#{btnNum+1}.wav"

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
    self = this

    doIt = (patternCopy) ->
      self.simulateButton patternCopy.shift(), ->
        if patternCopy.length
          delay 200, ->
            doIt patternCopy

    delay 1000, ->
      doIt pattern.slice 0

    console.log "next pattern is #{pattern}"

  simulateButton: (btnNum, callback) ->
    $btn = $(@buttons[btnNum])
    $btn.addClass('hover')
    @playButtonSound(btnNum)
    delay 500, ->
      $btn.removeClass('hover')
      callback()

  playButtonSound: (btnNum) ->
    audio = @audioLoader.get(@_getButtonSoundUri(btnNum))
    audio.currentTime = 0
    audio.play()

  stopButtonSound: (btnNum) ->
    audio = @audioLoader.get(@_getButtonSoundUri(btnNum))
    delay 200, ->
      audio.pause()


$(->
  $buttons = $('.simon-button')
  simon = new Simon $buttons.length
  simonUI = new SimonUI $buttons, simon
  simonUI.start()
)