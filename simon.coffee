class Event
  constructor: (@name) ->
    @listeners = []

  subscribe: (callback) ->
    @listeners.push(callback)

  fire: (obj) ->
    for listener in @listeners
      listener(obj)


class AudioManager
  readyCallback = null

  constructor: ->
    @buffers = {}
    @waitingToLoadCount = 0
    @playing = []
    window.AudioContext = window.AudioContext || window.webkitAudioContext
    if AudioContext
      @supported = true
      @context = new AudioContext()
    else
      @support = false
      @context = null
      alert "Audio for this game is not supported on your device."

  load: (uri, name) ->
    if not @supported
      return
    self = this
    @waitingToLoadCount++
    request = new XMLHttpRequest()
    request.open 'GET', uri, true
    request.responseType = 'arraybuffer'
    request.onload = ->
      self.context.decodeAudioData request.response, (buffer) ->
        self.buffers[name] = buffer
        self.waitingToLoadCount--
        self.checkReady()
    request.send()

  play: (name) ->
    if not @supported
      return
    source = @context.createBufferSource()
    source.buffer = @buffers[name]
    source.connect @context.destination
    if source.start
      source.start 0
    else
      source.noteOn 0
    @playing.push([name, source])

  stopAll: ->
    if not @supported
      return
    for info in @playing
      [name, source] = info
      source.disconnect(0)
    @playing = []

  stopMatch: (pattern) ->
    if not @supported
      return
    newPlaying = []
    for info in @playing
      [name, source] = info
      if pattern.test(name)
        source.disconnect(0)
      else
        newPlaying.push(info)
    @playing = newPlaying

  checkReady: ->
    if not @supported
      return
    if @waitingToLoadCount is 0
      if readyCallback
        readyCallback()
        readyCallback = null

  ready: (callback) ->
    if not @supported
      callback()
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
      @wrongButton.fire(@pattern.length-1)
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
        click: 'touchstart',
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

    @game.wrongButton.subscribe (numRounds) ->
      self.handleWrongButton numRounds

    @game.patternComplete.subscribe ->
      self.handlePatternComplete()

  _loadAudio: ->
    @audioManager = new AudioManager()
    for button, btnNum in @buttons
      @audioManager.load(@_getSoundUri(btnNum), btnNum)
    @audioManager.load(@_getSoundUri('wrong'), 'wrong')

  _getSoundUri: (name) ->
    "sounds/#{name}.wav"

  start: ->
    self = this
    @audioManager.ready ->
      self.game.start()
      self.demoPattern(self.game.pattern)

  handleButtonPress: (btnNum) ->
    @game.handleButtonPress(btnNum)

  handleWrongButton: (numRounds) ->
    @stopSound()
    @playSound('wrong')
    delay 200, ->
      $('.num-rounds').html(numRounds)
      $('.game-over').show()

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
    @audioManager.play(btnNum)

  stopSound: ->
    self = this
    delay 100, ->
      self.audioManager.stopMatch(/\d/)

$(->
  $('.simon-buttons').css('height', window.innerHeight + 'px');

  $buttons = $('.simon-button')
  simon = new Simon $buttons.length
  simonUI = new SimonUI $buttons, simon

  $('.start').on 'click', ->
    $(this).closest('.dialog').hide();
    simonUI.start()
)