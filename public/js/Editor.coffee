# Dependencies
#= require vendor/jquery-ui.js
#= require vendor/jquery.hotkeys.js
#= require vendor/notify-osd.min.js
#= require vendor/ZeroClipboard.js
#= require vendor/fullscreen.js
#= require vendor/bootstrap.js
#= require vendor/ace.js
#= require vendor/mode-json.js
#= require vendor/theme-idle_fingers.js

class @Editor

    ###*
    * Initializes the editor 
    ###
    constructor: ->       
        # Build the @uis object that contains ui shortcuts    
        @buildUI()
        # Create the clipboard copiers buttons
        @createClipboardCopiers()
        # Editor helper
        @token = @uis.body.data "given-token"
        @page  = @uis.body.data "page"
        # Create the ACE edtior
        @editor = ace.edit @uis.ace.attr("id")
        # Set the idle fingers theme
        @editor.setTheme("ace/theme/idle_fingers")
        # Activate wordwrap
        @editor.getSession().setUseWrapMode(true)
        # Define the language
        @editor.getSession().setMode("ace/mode/json")
        # Remove print margin
        @editor.setShowPrintMargin(false)
        # The text size must be change manualy with ACE
        @uis.ace.css "font-size", 16
        # Bing the event to the user elements           
        @bindUI()  

    ###*
    * Gets every jquery shortcuts
    * @return {Object} Editor container
    ###
    buildUI: =>
        @ui = $("#editor")
        @uis =
            workspace : $("#workspace")
            copiers   : @ui.find(".clipboard-copier")
            title     : @ui.find(".screen-title")
            embed     : $("#editor-embed")
            body      : $("body") 
            json      : $("#editor-json")
            ace       : $("#editor-json-text")

        return @ui

    ###*
    * Bind javascript event on page elements
    * @return {Object} jQuest window object
    ###
    bindUI:=>
        # Save the screen
        @ui.on("click", ".btn-save", @updateContent);
        $(document).bind('keydown', 'Ctrl+s meta+s', @updateContent);
        $("textarea, input").bind('keydown', 'Ctrl+s meta+s', @updateContent);

        # Save the draft
        @ui.on("click", ".btn-preview", @updateDraft);
        $(document).bind('keydown', 'Ctrl+p meta+p', @updateDraft);  
        $("textarea, input").bind('keydown', 'Ctrl+p meta+p', @updateDraft);  

        # Toggle the editor
        @ui.on("click", ".heading, .editor-toggler", => @uis.body.toggleClass "editor-toggled")
        # Resize editor
        @ui.resizable({        
            handles: "e",
            ghost: true,
            minWidth: 300
        }).on "resizestop", @afterEditorResize

        # Select embed code
        @uis.embed.on "click", -> this.select()

        # Toggle fullscreen mode
        @ui.find(".editor-size").on "click", "button", @updateEditorSize

        # Tabs switch
        @ui.find(".tabs-bar").on("click", "a", (event)=>
            event.preventDefault()
            # Toggle the right tab link
            @ui.find(".tabs-bar li").removeClass("active")
            $(event.currentTarget).parents("li").addClass("active")
            panId = $(event.currentTarget).attr("href") 
            # Hide pan
            @ui.find(".tabs-pan").removeClass("active")
            $(panId).addClass("active")
        )

        # Set delegated draggable 
        $(window).delegate(".spot", "mouseenter", @setSpotDraggable)   

    ###*
     * Records the position of a spot after the user moved it
     * @param  {Object} spot Spot moved
    ###
    recordSpotPosition:(spot)=>
        # Shortcuts
        $spot = $(spot)
        $step = $spot.parents(".step")

        # Step key
        step = $spot.data("step")
        # Spot key
        spot = $spot.data("spot")        
        # Spot positions
        left = parseInt($spot.css("left")) / ($step.width() / 100)
        top = parseInt($spot.css("top")) / ($step.height() / 100)
        # Round the values at 4 decimals
        left = (~~(left * 100) / 100) + "%"
        top = (~~(top * 100) / 100) + "%"
        
        # Get the JSON to edit
        content = JSON.parse @editor.getValue()
        # Edit positions into the object
        content.steps[step].spots[spot].left = left
        content.steps[step].spots[spot].top = top
        @updateJsonEditor(content)

    ###*
     * Update the JSON editor with the given value
     * @param  {Object|String} content New value of the editor
    ###
    updateJsonEditor:(content)=>        
        if typeof content == "string"
            value = content
        else
            # stringify the object
            value =  JSON.stringify content, null, 4
        # Add the new configuration file to the editor
        @editor.setValue value if @editor.getValue() != value
        
    ###*
     * Update the screen with the received data
     * @param  {String} text Data to parse
    ###
    updateScreen:(text)=>         
        # Update workspace content
        @uis.workspace.html $(text).filter("#workspace").html()
        # Update embed code
        @uis.embed.html $(text).find("textarea#editor-embed").val()      
        # Get the JSON
        content = JSON.parse @editor.getValue()
        # Update the theme by changing the body class
        bodyClass = "editor-mode theme-" + (content.theme || "default")
        @uis.body.attr("class", bodyClass)
        # Update the app title
        $("head title").text(content.name)
        @uis.title.text(content.name)
        # Create a player according the selected layout
        switch content.layout
            when "horizontal-tabs", "vertical-tabs"
                klass = window.Tabs
            when "book"
                klass = window.Book
            else
                klass = window.Interactive
        window.interactive = new klass()  

    ###*
     * Update the JSON editor and load the screen
     * @param  {String} content   JSON content
     * @param  {Number} preview=0 Activate the preview mode
    ###
    loadScreen:(content, preview=0) =>        
        @updateJsonEditor(content)
        $.get "/#{@page}?edit=#{@token}&preview=#{preview}", @updateScreen

    ###*
     * Send the new screen and load the screen
    ###
    updateContent:() =>   
        # Checks that we aren't in loading mode
        unless @uis.body.hasClass("js-loading")
            # Activate loading mode
            @uis.body.addClass("js-loading")   
            # Get the new JSON         
            content = @editor.getValue()
            $.ajax
                url: "/#{@page}/content"
                type: "POST"
                data: { content: content, token: @token }
                success: (d)=> @loadScreen(d)
                error: @updateError             
        return false

    ###*
     * Send the draft and load the screen
    ###
    updateDraft:() =>
        # Checks that we aren't in loading mode
        unless @uis.body.hasClass("js-loading")
            # Activate loading mode
            @uis.body.addClass("js-loading")  
            # Get the new JSON                
            content = @editor.getValue()
            $.ajax
                url: "/#{@page}/draft"
                type: "POST"
                data: { content: content, token: @token }
                success: (d)=> @loadScreen(d, 1)
                error: @updateError                               
        return false

    ###*
     * Somethinh wrong happens
     * @param  {Object} xhr Cross HTTP Request Object
    ###
    updateError:(xhr) =>   
        @uis.body.removeClass("js-loading")
        $.notify_osd.create
            text    : xhr.responseText                     
            timeout : 5

    ###*
     * Activate draggability when entering into a spot's handler
     * @param {Object} event Received event
    ###
    setSpotDraggable:(event) =>
        $spot = $(event.target).parents(".spot")
        unless $spot.is(':data(draggable)')
            $spot.draggable            
                handle: ".handle"
                containment: "#container"
                scroll: false
                stop: (event, ui) =>              
                    @recordSpotPosition event.target

    ###*
     * Create the clipboard copiers buttons
     * @return {Object} Copiers buttons
    ###
    createClipboardCopiers:=>
        # Options with the path to the flash fallback
        options = { moviePath: "/swf/ZeroClipboard.swf" }
        # For each clipboard button
        @uis.copiers.each (i, c)=> 
            # Create the button
            clip = new ZeroClipboard(c, options)
            # Enabled the clip buttons
            clip.on "load", => @uis.copiers.removeClass "disabled"            

    ###*
     * Toggle the fullscreen mode for the editor
    ###
    toggleFullscreenEditor:=>        
        # Is the fullscreen api supported ?
        if fullScreenApi.supportsFullScreen
            # Is the fullscreen already activated ?
            if fullScreenApi.isFullScreen()
                # Close it
                fullScreenApi.cancelFullScreen()
            else
                # Open fullscreen mode
                @ui.requestFullScreen()
    ###*
     * Change the editor width for the given parameter
     * @param  {Number} width=null Editor with
    ###
    changeEditorSize:(width=null)=>        
         # Is the fullscreen already activated ?
        if fullScreenApi.isFullScreen()
            # Close it
            fullScreenApi.cancelFullScreen()
        # Update the editor size
        @ui.css "width", width
        # Update the workspace
        @afterEditorResize()


    ###*
     * Event handler to change the editor size
     * @param  {Object} event Received event
    ###
    updateEditorSize:(event)=>
        # Get the clicked button
        $button = $(event.currentTarget)                
        # Determines what to do accorind the data-toggle attribut
        switch $button.data("toggle")
            when "fullscreen" then @toggleFullscreenEditor() 
            when "default" then @changeEditorSize ""                   
            when "big" then @changeEditorSize $(window).width()*0.8

    ###*
     * Adjust the editor after a resizing
    ###
    afterEditorResize:=>    
        @editor.resize()
        @uis.json.find(".editor-size .active").removeClass("active")
        @uis.workspace.css "left", $("#editor").outerWidth()
        setTimeout window.interactive.resize, 700
