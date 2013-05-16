# Dependencies
# Well, it's jQuery! 
#= require vendor/jquery-1.7.1.min.js

# Improve the touch experience by removing the tap delay
#= require vendor/fastclick.js

# Helper to bind the hash change event
#= require vendor/jquery-hashchange.js

# Allow jQuery to animate 2D transformations
#= require vendor/jquery.transform2d.js

# Imrpove the jQuery animate method by using CSS3 transitions when possible
#= require vendor/jquery.animate-enhanced.min.js

# Add the scrollTo method to jQuery
#= require vendor/jquery.scrollTo.min.js

# Add a better support for background position within the CSS method
#= require vendor/bgpos.js

# Patch the requestAnimationFrame function for better compatibility
#= require vendor/rAF.js

# Cross-browser mousewheel support
#= require vendor/jquery.mousewheel.js

# Add easing function
#= require vendor/jquery.easing.1.3.js

# Local pan on touch screen
#= require vendor/iscroll-lite.js

# Monitor scroll
#= require vendor/waypoints.js

class window.Interactive

  ###*
   * Initializrs the page 
  ###
  constructor: -> 
    # Prepare the lazyloading before everything
    @prepareLazyloading()
    # Event trigeered when the window is ready
    ev = "interactive:ready"
    # Disable existing handlers
    $(this).off(ev).on ev, @ready
    # Trigger the event if the window is already loaded
    if window.loaded then $(window).trigger ev 
    # Or trigger this event when the windows is loaded
    else $(window).on "load", => $(this).trigger ev

  ready: =>   
    # Remeber that the window is now loaded 
    window.loaded = true
    # Initial step
    @currentStep  = 0
    # Cached attributes
    @cache        = 
      scrollDuration          : 700  
      scrollEasing            : 'easeOutCubic'
      defaultEntranceDuration : 600 
      hasWaypoint             : false
      navigation              : "horizontal"

    @buildUI()
    @setCache()
    @buildAnimations()  
    @containerPosition()  
    @stepsPosition()
    @spotsSize()
    @spotsPosition()
    @bindUI()    
    @deactivateOtherSteps(-1)

    # Remove loading overlay
    $("body").removeClass "js-loading"    
    # Read the step from the hash
    @readStepFromHash() or @goToStep 0
    # Activate fast click to avoid tap delay on touch screen
    new FastClick(document.body)

  ###*
   * Set cache attributes
   * @return {Object} cache object 
  ###
  setCache: =>    
    # Record options
    @cache.hasWaypoint    = @uis.overflow.hasClass "scroll-allowed"
    @cache.navigation     = @uis.overflow.data("navigation")      or @cache.navigation
    @cache.scrollDuration = @uis.overflow.data("scroll-duration") or @cache.scrollDuration
    @cache.scrollEasing   = @uis.overflow.data("scroll-easing")   or @cache.scrollEasing
    @cache

  ###*
   * Gets every jquery shortcuts
   * @return {Object} Main page container
  ###
  buildUI: =>
    @ui = $("#container")
    @uis =
      steps      : @ui.find(".step")
      spots      : @ui.find(".spot")
      iframes    : @ui.find("iframe")   
      parallaxes : @ui.find("[data-parallax]")
      overflow   : $("#overflow")
      navitem    : $("#overflow .to-step")
      previous   : $("#overflow .previous") 
      next       : $("#overflow .next")

    return @ui

  ###*
   * Bind javascript event on page elements
   * @return {Object} jQuest window object
  ###
  bindUI: =>
    @uis.steps.on "click", ".spot", @showSpot
    @uis.previous.on "click", @previousStep
    @uis.next.on "click", @nextStep

    # Update element with parallax
    @ui.off("scroll").on("scroll", @updateParallaxes)
    # Update the container position when we resize the window
    $(window).off("resize").on("resize", @resize)
    # Bind the hashchange to change the current step
    $(window).off("hashchange").hashchange @readStepFromHash
    # Add an event to activate a step
    @uis.steps.on "step:activate", (ev) => @changeStepHash $(ev.currentTarget).data("step"), true
    # Step-pictures positioning
    @ui.find(".step-picture img").one("load", @positionStepPicture).each(-> $(this).load() if this.complete)
    # Is the scroll activated on the content ?
    if @cache.hasWaypoint
      # Waypoint helps us to know when the container scroll reach a step
      waypointOptions =  
        # Monitor @ui as scroll space
        context: @ui
        # Activate or not the horizontal mode
        horizontal: @cache.navigation == "horizontal"
      # Bind the mousewheel event
      @uis.steps.waypoint @scrollReachStep, waypointOptions     

    # Deactivates this shortcuts in editor mode
    $(window).off("keydown").keydown @keyboardNav unless $("body").hasClass("editor-mode")
    # Open links begining by http in a new window
    $("a[href^='http://']").attr "target", "_blank"

  ###*
   * Refresh the container position and steps size when we resize the window   
  ###
  resize: =>
    @containerPosition()
    @stepsPosition()

  ###*
   * Builds the animations array dynamicly to allow relative computation 
   * @return {Array} List of animations
  ###
  buildAnimations: =>
    # Entrance animations patterns
    @entrance =
      fadeIn:
        from: { opacity: '0' }
        to:   { opacity: '1' }

      up:
        from: { top: @ui.width(), left: 0 }
        to:   { top: 0 }

      down:
        from: { top: -1 * @ui.width(), left: 0 }
        to:   { top: 0 }

      left:
        from: { left: @ui.width(), top: 0  }
        to:   { left: 0 }

      right:
        from: { left: -1 * @ui.width(), top: 0 }
        to:   { left: 0 }

      stepUp:
        from: { top: 100, left: 0}
        to:   { top: 0 }

      stepDown:
        from: { top: -100, left: 0}
        to:   { top: 0 }

      stepLeft:
        from: { left: 100, top: 0}
        to:   { left: 0 }

      stepRight:
        from: { left: -100, top: 0}
        to:   { left: 0 }

      zoomIn:
        from: { transform: "scale(0)" }
        to:   { transform: "scale(1)" }

      zoomOut:
        from: { transform: "scale(2)" }
        to:   { transform: "scale(1)" }

      clockWise:
        from: { transform: "rotate(0deg)" }
        to:   { transform: "rotate(360deg)" }

      counterClockWise:
        from: { transform: "rotate(0deg)" }
        to:   { transform: "rotate(-360deg)" }

  ###*
   * Adjust the margin of the container to fit to the widnow   
  ###
  containerPosition: =>
    windowHeight = $(window).height()
    containerHeight = @uis.overflow.outerHeight()
    if windowHeight <= containerHeight
      top = 0
    else
      top = (windowHeight-containerHeight)/2    
    # Sets the new offset
    @uis.overflow.css "top", top

  ###*
   * * Position the given picture at the center of its step by adding negative margins
   * @param  {Object} e Received event
   * @return {Object}   Current picture
  ###
  positionStepPicture: (e)->
    $pic = $(this)
    $pic.css
      marginLeft: $pic.width() / -2
      marginTop:  $pic.height()/ -2

  ###*
   * Static method to "unload" iframes before lazyloading
   * @return {Array} Iframes list
  ###
  prepareLazyloading: ()->
    # For each iframe (static way)
    $("#container iframe").each (i, iframe)->
      $iframe = $(iframe)
      # Remeber its src
      $iframe.data "src", $iframe.attr("src")
      # Removes the src attribute
      $iframe.removeAttr "src"

  ###*
   * Position every steps in the container
   * @return {Array} Steps list
  ###
  stepsPosition: ->
    @uis.steps.each (i, step) =>
      $step = $(step)      
      # Do not position the first step according the previous one
      if i == 0        
        $step.css
          top  :  if @cache.hasWaypoint and @cache.navigation == "vertical"   then 1 else 0
          left :  if @cache.hasWaypoint and @cache.navigation == "horizontal" then 1 else 0
      else
        $previousStep = @uis.steps.eq(i - 1)   
        switch @cache.navigation
          when "vertical"     
            $step.css "top", $previousStep.position().top + $previousStep.height()
          else
            $step.css "left", $previousStep.position().left + $previousStep.width()

  ###*
   * Resize every spots according its wrapper
   * @return {Array} Spots list
  ###
  spotsSize: =>    
    @uis.spots.each (i, spot) ->
      $spot = $(this)
      $spot.css "width",  $spot.find("js-animation-wrapper").outerWidth()
      $spot.css "height", $spot.find("js-animation-wrapper").outerHeight()


  ###*
   * Position every spots in each steps
   * @return {Array} Spots list
  ###
  spotsPosition: =>    
    # Add a negative margin on each spot
    # (position the spot from its center)
    @uis.spots.each (i, spot) ->
      $spot = $(spot)
      if $spot.data("origin") == "center" 
        $spot.css "margin-left", $spot.outerWidth() / -2
        $spot.css "margin-top", $spot.outerHeight() / -2

  ###*
   * Update the parallaxes positions
   * @return {[type]} [description]
  ###
  updateParallaxes:()=>   
    # According the navigation type...
    switch @cache.navigation

      when "horizontal" 
        # ...extract the property to change
        offset  = "left"
        prop    = "translateX"

      when "vertical" 
        # ...extract the property to change
        offset  = "top"
        prop    = "translateY"

    # Distance from the top of the window
    refDist = @ui.offset()[offset]      
    # Apply a function to each parallax element
    @uis.parallaxes.each (i, parallax)=>
      $parallax = $(parallax)
      # The step containing the parallax      
      $step = $parallax.closest('.step')
      # Distance of the parent step from the top of the container
      delta = $step.offset()[offset] - refDist
      # Speed of the movement 
      speed = 1 * ( $parallax.data("parallax") or 0.5 )
      # Transform the position using the right property
      $parallax.css "transform", "#{prop}(#{speed*delta}px)"


  ###*
   * TODO: open a contextual popin when clicking on a spot
   * @param  {Object} event Click event
   * @return {[type]}       [description]
  ###
  showSpot: (event) =>
    $this = $(this)


  ###*
   * Update the hashbang when we reach a step
   * @param  {String} direction Scroll direction
  ###
  scrollReachStep: ()->
    # Activate the current step
    $(this).trigger("step:activate")

  ###*
   * Bind the keyboard keydown event to navigate through the page
   * @param  {Object} event Keydown event
   * @return {Object}       Keydown event
  ###
  keyboardNav: (event) =>
    switch event.keyCode      
      # Left and up
      when 37, 38 then @previousStep()      
      # Right and down
      when 39, 40 then @nextStep()      
      # Stop here for the other keys
      else return event
    event.preventDefault()

  ###*
   * Go to the previous step
   * @return {Number} New current step number
  ###
  previousStep: =>
    @changeStepHash 1 * @currentStep - 1

  ###*
   * Go to the next step
   * @return {Number} New current step number
  ###
  nextStep: =>
    @changeStepHash 1 * @currentStep + 1

  ###*
   * Change the URL hash to fit to the given step
   * @param  {Number} step Target step
   * @return {String}      New location hash
  ###
  changeStepHash: (step=@currentStep, noEvent=false) =>    
    # If the step is different
    if not @getHashParams().hasOwnProperty("step") or @getHashParams().step != @currentStep      
      # If we ask explicitly to not scroll once when the hashchange
      @cache.skipHashChange = true if noEvent
      # Change the hash
      location.hash = "#step=" + step  if step >= 0 and step < @uis.steps.length

  ###*
   * Just go to step directcly
   * @return {Number} New step number
  ###
  readStepFromHash: =>   
    if @getHashParams().hasOwnProperty("step")
      # Get the step number from hash
      step = @getHashParams().step      
      # Skip the scroll
      if @cache.skipHashChange
        # Reactivate scroll to a step
        @cache.skipHashChange = false
        # and active the step
        @activeStep step
      # Or scroll to the step before...
      else
        @goToStep step


  ###*
   * Slide to the given step
   * @param  {Number} step New current step number
   * @return {Number}      New current step number
  ###
  goToStep: (step=@currentStep) =>          
    if step >= 0 and step < @uis.steps.length      
      # Update the current step id
      @currentStep = 1 * step     
      # Prevent scroll queing
      jQuery.scrollTo.window().queue([]).stop() 
      # Disable waypoint temporary
      @uis.steps.waypoint "disable" if @cache.hasWaypoint  
      # And scroll to the current step
      @ui.scrollTo(
        @uis.steps.eq(@currentStep), 
        { 
          # Default scroll duration
          duration: @cache.scrollDuration, 
          # Add the default easing
          easing: @cache.scrollEasing, 
          # Active the given step
          onAfter: => @activeStep @currentStep 
        }
      )   

    return @currentStep

  ###*
   * Activate the given step
   * @param  {Number} step New current step number
   * @return {Number}      New current step number
  ###
  activeStep: (step=@currentStep) =>
    # Update the current step id
    @currentStep = 1 * step
    # Remove current class
    @uis.steps.removeClass("js-current").eq(@currentStep).addClass "js-current"       
    # Deactivate other steps
    @deactivateOtherSteps @currentStep
    # Start reanable step waypoint
    @uis.steps.waypoint "enable" if @cache.hasWaypoint
    # Add a class to the body
    $body = $("body")      
    # Is this the first step ?
    $body.toggleClass "js-first", @currentStep is 0   
    # Is this the last step ?
    $body.toggleClass "js-last", @currentStep is @uis.steps.length - 1
    # Update the menu
    @uis.navitem.removeClass("active").filter("[data-step=#{@currentStep}]").addClass "active"
    # Load the awainting iframes
    @uis.steps.eq(@currentStep).find("iframe").each (i, iframe)-> 
      if $(iframe).data("src")?
        # Update the src attribute onlu if the data value exists
        $(iframe).attr "src", $(iframe).data("src")
        # Then remove it
        $(iframe).removeData("src")

    # Clear all spot animations
    @clearSpotAnimations()      
    # Add the entrance animation after the scroll
    setTimeout @doEntranceAnimations, @cache.scrollDuration
    # Trigger an event
    @ui.trigger "step:change", [@currentStep]    

    return @currentStep

  ###*
   * Deactivate steps exept the given one
   * @param  {Number} step Step number to exept
  ###
  deactivateOtherSteps: (step=@currentStep) =>    
    # Get the other steps
    $others = @uis.steps.not ".js-current"
    # Process each step one by one
    $others.each (i, s)->
      # Select animated spots
      $spots = $(s).find(".spot[data-entrance]:not([data-entrance=''])")
      # Hide animation wrappers
      $spots.find(".js-animation-wrapper").addClass "hidden"


  ###*
   * Set step animations
  ###
  doEntranceAnimations: =>    
    # Launch hotspot background animations
    @doSpotAnimations()    
    # Find the current step
    $step = @uis.steps.filter(".js-current")    
    # Number of element behind before animate the entrance
    queue = 0    
    # Find spots with animated entrance
    $step.find(".spot[data-entrance]:not([data-entrance=''])").each (i, elem) =>          
      $elem = $(elem)            
      # Get tge data from the element
      data = $elem.data()
      # Works on an animation wrapper
      $wrapper = $elem.find(".js-animation-wrapper")      
      # Get the animation keys of the given element
      animationKeys = data.entrance.split(" ")
      # Clear existing timeout
      clearTimeout $wrapper.t  if $wrapper.t  
      # Initial layout
      from = to = {}
      # For each animation key
      $.each animationKeys, (i, animationKey)=>                
        # Get the animation (and create a clone object)
        animation = $.extend true, {}, @entrance[animationKey]      
        # If the animation exist
        if animation?
          # Merge the layout object recursively
          from = $.extend true, animation.from, from
          to   = $.extend true, animation.to, to
          
      # Stop every current animations and show the element
      # Also, set the original style if needed
      $wrapper.stop().css(from).removeClass "hidden" 
      # Only if a "to" layout exists
      if to?     
        # If there is a queue
        queue++  if $elem.data("queue")?
        # Take the element entrance duration 
        # or default duration
        duration = data.entranceDuration or @cache.defaultEntranceDuration  

        # explicite duration
        if $elem.data("queue") > 1
          entranceDelay = $elem.data("queue")
        else
          # calculate the entrance duration according the number of element before   
          entranceDelay = duration * queue

        # Wait a duration...
        $wrapper.t = setTimeout( 
          # Closure function to transmit "to"
          (
            (to)->->          
                # ...before animate the wrapper
                $wrapper.animate to, duration       
          )(to)
        # ...and increase the queue
        , entranceDelay)


  ###*
   * Clear every spots animations
   * @return {Array} Spots list
  ###
  clearSpotAnimations: =>
    @uis.spots.each (i, spot) ->
      $spot = $(spot)
      if $spot.d
        window.cancelAnimationFrame $spot.d
        delete ($spot.d)

  ###*
   * Trigger spots background animations in the current step
   * @return {Array} List of the spots
  ###
  doSpotAnimations: =>    
    # Find the current step
    $step = @uis.steps.filter(".js-current")    
    # Find its spots
    $spots = $step.find(".spot")
    
    # On each spot, create an animation
    $spots.each (i, spot) ->
      data = $(spot).data()
      requestField = "d"
      
      # Is there a background and an animation on it
      if data["background"] and data["backgroundDirection"] isnt `undefined`          
        # Reset background position
        $(spot).find(".js-animation-wrapper").css "background-position", "0 0"        
        # Clear existing request animation frame
        window.cancelAnimationFrame spot[requestField]  if spot[requestField]
        requestParams = @closureAnimation(spot, requestField, @renderSpotAnimation)        
        # Add animation frame with a closure function
        spot[requestField] = window.requestAnimationFrame(requestParams)

  ###*
   * Process spot rendering
   * @param  {Object} spot Spot html element
   * @return {Array}       Directions array
  ###
  renderSpotAnimation: (spot) =>    
    $spot = $(spot)
    $wrapper = $spot.find ".js-animation-wrapper"  
    data = $spot.data()
    directions = ("" + data.backgroundDirection).split(" ")
    speed = data.backgroundSpeed or 3
    lastRAF = spot.lastRAF or 0
    
    # Skip this render if its too early
    return false if new Date().getTime() - lastRAF < (data.backgroundFrequency or 0)

    # Set the time of the last animation
    spot.lastRAF = new Date().getTime()

    # Allow several animation
    $(directions).each (i, direction) ->
      switch direction
        when "left"
          $wrapper.css "backgroundPositionX", "-=" + speed
        when "right"
          $wrapper.css "backgroundPositionX", "+=" + speed
        when "top"
          $wrapper.css "backgroundPositionY", "-=" + speed
        when "bottom"
          $wrapper.css "backgroundPositionY", "+=" + speed
        else          
          # We receive a number,
          # we interpret it as a direction degree
          unless isNaN(direction)
            radian = direction * Math.PI / 180.0
            x0 = $wrapper.css("backgroundPositionX")
            y0 = $wrapper.css("backgroundPositionY")
            x = speed * Math.cos(radian)
            y = speed * Math.sin(radian)
            $wrapper.css "backgroundPositionX", "+=" + x
            $wrapper.css "backgroundPositionY", "+=" + y

  ###*
   * Closure function to execute the given function within the receive element
   * @param  {Object}   elem         HTML element
   * @param  {String}   requestField Name of the field into elem where record the animation frame 
   * @param  {Function} func         Callback function of the animation
  ###
  closureAnimation: (elem, requestField, func) =>
    ->
      # Continue to the next frame                  
      # Add animation frame with a closure function
      elem[requestField] = window.requestAnimationFrame(@closureAnimation(elem, requestField, func))  if elem[requestField]      
      # Apply the animation render
      func elem


  ###*
   * Read the parameters into the location hash using the following format:
   * /#foo=2&bar=3
   * @copyright http://stackoverflow.com/questions/4197591/parsing-url-hash-fragment-identifier-with-javascript#comment10274416_7486972
   * @return {Object} Data object]
  ###
  getHashParams: =>
    hashParams = {}
    e = undefined
    a = /\+/g # Regex for replacing addition symbol with a space
    r = /([^&;=]+)=?([^&;]*)/g
    d = (s) ->
      decodeURIComponent s.replace(a, " ")

    q = window.location.hash.substring(1)
    hashParams[d(e[1])] = d(e[2])  while e = r.exec(q)
    hashParams