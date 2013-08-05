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

  checkReady: ->
    if @filesToLoad is @filesLoaded
      if readyCallback
        readyCallback()
        readyCallback = null

  ready: (callback) ->
    readyCallback = callback
    @checkReady()


delay = (ms, func) -> setTimeout func, ms


$.fn.tclick = (onclick) ->
  @.bind "touchstart", (e) ->
    onclick.call this, e
    e.stopPropagation()
    e.preventDefault()
  @.bind "click", (e) ->
    onclick.call this, e
  return this


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
      @start()


class SimonUI
  constructor: (@buttons, @game) ->
    for button, idx in @buttons
      $(button).data('button-num', idx)
    @._initListeners()
    @._loadAudio()

  _initListeners: ->
    self = this

    eventNames = {
      click: 'click',
      mouseDown: 'mousedown',
      mouseUp: 'mouseup'
    }
    if $('html').hasClass('mobile')
      eventNames = {
        click: 'click',
        mouseDown: 'touchstart',
        mouseUp: 'touchend'
      }

    @buttons.on eventNames.click, (evt) ->
      evt.preventDefault()
      btnNum = $(this).data('button-num')
      self.game.handleButtonPress(btnNum)

    @buttons.on eventNames.mouseDown, ->
      $(this).addClass('active');
      btnNum = $(this).data('button-num')
      self.playSound(btnNum)

    @buttons.on eventNames.mouseUp, ->
      $('.active').removeClass('active')
      btnNum = $(this).data('button-num')
      self.stopSound()

    @game.wrongButton.subscribe ->
      self.handleWrongButton()

    @game.patternComplete.subscribe ->
      self.handlePatternComplete()

  _loadAudio: ->
    @audioLoader = new AudioLoader()
    for button, btnNum in @buttons
      @audioLoader.load(@_getSoundUri(btnNum))
    @audioLoader.load(@_getSoundUri('wrong'))

  _getSoundUri: (name) ->
    "sounds/#{name}.wav"

  start: ->
    @game.start()
    @demoPattern(@game.pattern)

  handleButtonPress: (btnNum) ->
    @game.handleButtonPress(btnNum)

  handleWrongButton: ->
    @stopSound()
    @playSound('wrong')
    @currentAudio = null # prevent stopping the sound
    delay 200, ->
      alert('Game Over')

  handlePatternComplete: ->
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

  simulateButton: (btnNum, callback) ->
    $btn = $(@buttons[btnNum])
    $btn.addClass('active')
    @playSound(btnNum)
    delay 500, ->
      $btn.removeClass('active')
      callback()

  playSound: (btnNum) ->
    if @currentAudio
      @currentAudio.pause()
    @currentAudio = new Audio(@_getSoundUri(btnNum))
    @currentAudio.play()

  stopSound: ->
    if @currentAudio
      @currentAudio.pause()
    @currentAudio = null


$(->
  $('.simon-buttons').css('height', window.innerHeight + 'px');

  $buttons = $('.simon-button')
  simon = new Simon $buttons.length
  simonUI = new SimonUI $buttons, simon
  simonUI.start()
)