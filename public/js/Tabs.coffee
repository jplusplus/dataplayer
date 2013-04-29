#= require Interactive.coffee

class window.Tabs extends window.Interactive

    constructor:->
        super
        @buildTabs()


    buildTabs: =>
        @uis.tabs = $("#overflow .tabs .steps")        
        @tabWrapperWidth()
        # Activate this shortcut on touch screens
        if Modernizr.touch and @uis.tabs.length
            # Create a new iScroll instance
            @uis.iscroll = new iScroll @uis.tabs[0]
        # Or bind the mousewheel
        else
            @uis.tabs.on "mousewheel", @wheelOnTabs
        # Bind the step change
        @ui.on "step:change", @updateTabsScroll

    ###*
    * Resize the tab wrapper within horizontal layout
    * @return {Object} Tabs wrapper
    ###
    tabWrapperWidth: =>        
        if @uis.overflow.hasClass("horizontal-tabs")
            # Calculates the wrapper size
            wrapperWith = 0 
            # By extracting the size of every step
            @uis.tabs.find(".wrapper > li").each (i, tab)=>
                # And mades a right reduction using there with
                wrapperWith += $(tab).outerWidth()
            # Then apply the width to the wrapper
            @uis.tabs.find(".wrapper").css("width", wrapperWith)

    ###*
    * Activate mousewheel within the tabs area
    * @param  {Object} event  Mouse wheel event
    * @param  {Number} delta  Distance across
    * @param  {Number} deltaX Distance across on X
    * @param  {Number} deltaY Distance across on Y
    ###
    wheelOnTabs: (ev, delta, deltaX, deltaY) =>
        $this = $(ev.currentTarget)            
        if @uis.overflow.hasClass("vertical-tabs")      
            scrollTop = $this.scrollTop()
            $this.scrollTop(scrollTop-Math.round(deltaY*20))      
        else
            scrollLeft = $this.scrollLeft()
            $this.scrollLeft(scrollLeft-Math.round(-deltaX*20))          


    updateTabsScroll: (event, step) => 
        # Tab target (where to scroll to)
        $tabTarget = @uis.navitem.filter("[data-step=#{@currentStep}]")            
        # Activate this shortcut on touch screens
        if Modernizr.touch and @uis.tabs.length
            @uis.iscroll.scrollToElement $tabTarget[0], @scrollDuration
        else
            # Update the menu
            @uis.tabs.scrollTo $tabTarget, @scrollDuration  