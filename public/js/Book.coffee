# Colors manipulation
#= require vendor/tinycolor.js

# Parent classe
#= require Interactive.coffee

class window.Book extends window.Interactive

  ###*
   * Set cache attributes
   * @return {Object} cache object 
  ###
  setCache: =>    
    super
    # Record options
    @cache.hasWaypoint = false
    @cache
    

  stepsPosition:->
    count = @uis.steps.length
    unless count == 0
      zIndex = @uis.steps.eq(0).css("z-index")
      zIndex = if isNaN(zIndex) then 100 else zIndex
      width = @ui.outerWidth()/2
      
      @ui.find(".page").each (i,page) =>
        $(page).css
          width: width
          height: @ui.outerHeight()
          zIndex: zIndex + (count-i)

      @uis.steps.css "width", @ui.outerWidth()/2

  ###*
   * Override goToStep method
   * @param  {Number} step New current step number
   * @return {Number}      New current step number
  ###
  goToStep:(step=@currentStep)=> 
    if step >= 0 and step < @uis.steps.length                  
      @currentStep = step
      # Active the step
      setTimeout @activeStep, 600
      # Turn each page      
      $.each @flips, (i, flip) =>  
        # The target (or direction) is not the same 
        # for backward and forward flip
        if i < step
          flip.target = -1
        else
          flip.target = 1          
        # Drap the current flip
        @drawFlip flip

  ###*
   * Gets every jquery shortcuts
   * @return {Object} Main page container
  ###
  buildUI: => 
    super    
    # Dimensions of the whole book
    @BOOK_WIDTH  = @ui.outerWidth()
    @BOOK_HEIGHT = @ui.outerHeight()    
    # Dimensions of one page in the book
    @PAGE_WIDTH  = @BOOK_WIDTH/2
    @PAGE_HEIGHT = @BOOK_HEIGHT   
    @PAGE_BG     = @uis.steps.eq(0).css("background-color")
    @PAGE_SHW_A  = tinycolor.darken(@PAGE_BG, 1)
    @PAGE_SHW_B  = tinycolor.darken(@PAGE_BG, 2)
    # Vertical spacing between the top edge of the book and the papers
    @PAGE_Y      = (@BOOK_HEIGHT - @PAGE_HEIGHT) / 2
    # The canvas size equals to the book dimensions + this padding
    @CVS_PADDING = 30

    
    @canvas           = document.getElementById("page-flip")    
    @context         = @canvas.getContext("2d")
    @uis.canvas      = $(@canvas)    
    @cache.zIndexOn  = $(@canvas).css("z-index")
    @cache.zIndexOff = 100
    @mouse           = x: 0, y: 0
    @flips           = []    
    # Organize the depth of our pages and create the flip definitions
    @ui.find(".page").each (i, page)=>
      @flips.push        
        # Current progress of the flip (left -1 to right +1)
        progress: 1        
        # The target value towards which progress is always moving
        target: 1
        # The page DOM element related to this flip
        page: page
        # True while the page is being dragged
        dragging: false
    
    # Resize the canvas to match the book size
    @canvas.width = @BOOK_WIDTH + (@CVS_PADDING * 2)
    @canvas.height = @BOOK_HEIGHT + (@CVS_PADDING * 2)    
    
    

  ###*
   * Bind javascript event on page elements
   * @return {Object} jQuest window object
  ###
  bindUI: =>
    super
    # Start moving a page    
    @ui.on "mousedown touchstart", "a.corner", @mouseDownHandler     
    @uis.canvas.on "mousedown touchstart", @mouseDownHandler     
    # Record mouse position within the book 
    $(document).on "mousemove touchmove", @mouseMoveHandler
    # Drop a page
    $(document).on "mouseup touchend",   @mouseUpHandler
    # Render the page flip every animation frame
    window.requestAnimationFrame @render

  mouseMoveHandler: (e) =>   
    ref = if e.type == "mousemove" then e else event.touches[0]
    # Offset mouse position so that the top of the book spine is 0,0
    @mouse.x = ref.clientX - @ui.offset().left - (@BOOK_WIDTH / 2)
    @mouse.y = ref.clientY - @ui.offset().top    

  mouseDownHandler: (e) =>   
    # Make sure the mouse pointer is inside of the book
    if Math.abs(@mouse.x) < @PAGE_WIDTH
      if @mouse.x < 0 and @currentStep - 1 >= 0        
        # We are on the left side, drag the previous page
        @flips[@currentStep - 1].dragging = true      
      # We are on the right side, drag the current page
      else if @mouse.x > 0 and @currentStep + 1 < @flips.length     
        @flips[@currentStep].dragging = true         
  
    # Prevents the text selection
    e.preventDefault()

  mouseUpHandler: (e) =>
    $.each @flips, (i, flip) =>                 
      # If this flip was being dragged, animate to its destination
      if flip.dragging        
        # Figure out which page we should navigate to
        if @mouse.x < 0
          flip.target = -1
          @currentStep = Math.min(@currentStep + 1, @flips.length)
        else
          flip.target = 1
          @currentStep = Math.max(@currentStep - 1, 0)
        # Update the current page
        @changeStepHash @currentStep, true        
      # Disable dragging on that flip
      flip.dragging = false
      # Do not interupt the lopp
      return true

  render:(repeat=true) =>    
    # Bind the next request animation frame
    window.requestAnimationFrame @render if repeat
    # Reset all pixels in the canvas
    @context.clearRect 0, 0, @canvas.width, @canvas.height
    # Hide the canvas
    @uis.canvas.css "z-index", @cache.zIndexOff

    $.each @flips, (i, flip)=>               
      flip.target = Math.max( Math.min(@mouse.x / @PAGE_WIDTH, 1), -1) if flip.dragging 
      # Ease progress towards the target value 
      flip.progress += (flip.target - flip.progress) * 0.2  
      # If the flip is being dragged or is somewhere in the middle of the book, render it
      @drawFlip flip if flip.dragging or Math.abs(flip.progress) < 0.997
      # Do not interupt the lopp
      return true
        
  drawFlip: (flip) =>    
    # Show the canvas
    @uis.canvas.css "z-index", @cache.zIndexOn
    # Strength of the fold is strongest in the middle of the book
    strength = 1 - ( ~~( Math.abs(flip.progress)*1000) )/1000
    # How far the page should outdent vertically due to perspective
    verticalOutdent = 20 * strength
    
    # Width of the folded paper
    foldWidth = ~~(@PAGE_WIDTH * 0.5) * (1 - flip.progress)    
    # X position of the folded paper
    foldX = @PAGE_WIDTH * flip.progress + foldWidth
    
    # The maximum width of the left and right side shadows
    paperShadowWidth = (@PAGE_WIDTH * 0.5) * Math.max(Math.min(1 - flip.progress, 0.5), 0)
    rightShadowWidth = (@PAGE_WIDTH * 0.5) * Math.max(Math.min(strength, 0.5), 0)
    leftShadowWidth  = (@PAGE_WIDTH * 0.5) * Math.max(Math.min(strength, 0.5), 0)
    
    # Change page element width to match the x position of the fold
    flip.page.style.width = Math.max(foldX, 0) + "px"
    @context.save()
    @context.translate @CVS_PADDING + (@BOOK_WIDTH / 2), @PAGE_Y + @CVS_PADDING
    
    # Draw a sharp shadow on the left side of the page
    @context.strokeStyle = "rgba(0,0,0," + (0.05 * strength) + ")"
    @context.lineWidth = 30 * strength
    @context.beginPath()
    @context.moveTo foldX - foldWidth, - verticalOutdent * 0.5
    @context.lineTo foldX - foldWidth, @PAGE_HEIGHT + (verticalOutdent * 0.5)
    @context.stroke()

    # Right side drop shadow    
    rightShadowGradient = @context.createLinearGradient(foldX, 0, foldX + rightShadowWidth, 0)
    rightShadowGradient.addColorStop 0, "rgba(0,0,0," + Math.abs(strength * 0.2) + ")"
    rightShadowGradient.addColorStop 0.8, "rgba(0,0,0,0.0)"
    @context.fillStyle = rightShadowGradient
    @context.beginPath()
    @context.moveTo foldX, 0
    @context.lineTo foldX + rightShadowWidth, 0
    @context.lineTo foldX + rightShadowWidth, @PAGE_HEIGHT
    @context.lineTo foldX, @PAGE_HEIGHT
    @context.fill()
    
    # Left side drop shadow
    leftShadowGradient = @context.createLinearGradient(foldX - foldWidth - leftShadowWidth, 0, foldX - foldWidth, 0)
    leftShadowGradient.addColorStop 0, "rgba(0,0,0,0.0)"
    leftShadowGradient.addColorStop 1, "rgba(0,0,0," + Math.abs(strength * 0.15) + ")"
    @context.fillStyle = leftShadowGradient
    @context.beginPath()
    @context.moveTo foldX - foldWidth - leftShadowWidth, 0
    @context.lineTo foldX - foldWidth, 0
    @context.lineTo foldX - foldWidth, @PAGE_HEIGHT
    @context.lineTo foldX - foldWidth - leftShadowWidth, @PAGE_HEIGHT
    @context.fill()
    
    # Gradient applied to the folded paper (highlights & shadows)
    foldGradient = @context.createLinearGradient(foldX - paperShadowWidth, 0, foldX, 0)
    foldGradient.addColorStop 0.35, @PAGE_BG
    foldGradient.addColorStop 0.73, @PAGE_SHW_B
    foldGradient.addColorStop 0.9, @PAGE_BG
    foldGradient.addColorStop 1.0, @PAGE_SHW_A
    @context.fillStyle = foldGradient
    @context.strokeStyle = "rgba(0,0,0,0.06)"
    @context.lineWidth = 0.5
    
    # Draw the folded piece of paper
    @context.beginPath()
    @context.moveTo foldX, 0
    @context.lineTo foldX, @PAGE_HEIGHT
    @context.quadraticCurveTo foldX, @PAGE_HEIGHT + (verticalOutdent * 2), foldX - foldWidth, @PAGE_HEIGHT + verticalOutdent
    @context.lineTo foldX - foldWidth, -verticalOutdent
    @context.quadraticCurveTo foldX, -verticalOutdent * 2, foldX, 0
    @context.fill()
    @context.stroke()
    @context.restore()