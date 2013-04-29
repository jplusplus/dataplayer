# Dependencies
#= require vendor/jquery-ui.min.js
#= require vendor/codemirror.js
#= require vendor/codemirror-javascript.js
#= require vendor/jquery.hotkeys.js
#= require vendor/notify-osd.min.js
#= require vendor/ZeroClipboard.js

class @Editor
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
        content = JSON.parse @myCodeMirror.getValue()
        # Edit positions into the object
        content.steps[step].spots[spot].left = left
        content.steps[step].spots[spot].top = top
        @updateJsonEditor(content)


    updateJsonEditor:(content)=>        
        if typeof content == "string"
            value = content
        else
            # stringify the object
            value =  JSON.stringify content, null, 4
        # Add the new configuration file to the editor
        @myCodeMirror.setValue value if @myCodeMirror.getValue() != value
        
    updateScreen:(text)=>         
        # Update workspace content
        $("#workspace").html $(text).filter("#workspace").html()
        # Update embed code
        $("#editor-embed").html $(text).find("textarea#editor-embed").val()      
        # Get the JSON
        content = JSON.parse @myCodeMirror.getValue()
        # Update the theme by changing the body class
        bodyClass = "editor-mode theme-" + (content.theme || "default")
        $("body").attr("class", bodyClass)
        # Update the app title
        $("head title").text(content.title)
        $("#editor .screen-title").text(content.title)
        # Create a player according the selected layout
        switch content.layout
            when "horizontal-tabs", "vertical-tabs"
                klass = window.Tabs
            when "book"
                klass = window.Book
            else
                klass = window.Interactive
        window.interactive = new klass()  


    updateContent:() =>   
        unless $("body").hasClass("js-loading") or $("#editor .btn-save").hasClass("disabled")
            $("body").addClass("js-loading")            
            $("#editor .btn").addClass("disabled")
            content = @myCodeMirror.getValue()
            $.ajax
                url: "/#{@page}/content"
                type: "POST"
                data: { content: content, token: @token }
                success: @loadContent
                error: @updateError             
        return false

    loadContent:(content) =>        
        @updateJsonEditor(content)
        $.get "/#{@page}?edit=#{@token}", (xml)=>            
            @updateScreen(xml)
            $("#editor .btn").removeClass("disabled")

    updateDraft:() =>
        unless $("body").hasClass("js-loading") or $("#editor .btn-save").hasClass("disabled")
            $("body").addClass("js-loading")            
            $("#editor .btn").addClass("disabled")
            content = @myCodeMirror.getValue()
            $.ajax
                url: "/#{@page}/draft"
                type: "POST"
                data: { content: content, token: @token }
                success: @loadDraft
                error: @updateError                               
        return false

    loadDraft:(content) =>        
        @updateJsonEditor(content)
        $.get "/#{@page}?edit=#{@token}&preview=1", (text)=>                                      
            @updateScreen(text)
            $("#editor .btn-save").removeClass("disabled")

    updateError:(xhr) =>   
        $("#editor .btn").removeClass("disabled")
        $("body").removeClass("js-loading")
        $.notify_osd.create
            text    : xhr.responseText                     
            timeout : 5

    setSpotDraggable:(event) =>
        $spot = $(event.target).parents(".spot")
        unless $spot.is(':data(draggable)')
            $spot.draggable            
                handle: ".handle"
                containment: "#container"
                scroll: false
                stop: (event, ui) =>              
                    @recordSpotPosition event.target

    createClipboardCopiers:=>
        # Options with the path to the flash fallback
        options = { moviePath: "/swf/ZeroClipboard.swf" }
        # For each clipboard button
        $(".clipboard-copier").each (i, c)=> 
            # Create the button
            clip = new ZeroClipboard(c, options)
            # Enabled the clip button
            clip.on "load", -> $(".clipboard-copier").removeClass "disabled"            

    constructor: ->        
        @token = $("body").data "given-token"
        @page  = $("body").data "page"

        @createClipboardCopiers()

        # Bind a "CodeMirror" editor on editor text area
        @myCodeMirror = CodeMirror.fromTextArea(
            $("#editor-json textarea")[0],
            {
                indentUnit: 4,
                indentWithTabs: false,                
            }
        )

        # Activate save/preview buttons
        @myCodeMirror.on "change", -> $("#editor .btn").removeClass("disabled")

        # Save the screen
        $("#editor").on("click", ".btn-save", @updateContent);
        $(document).bind('keydown', 'Ctrl+s meta+s', @updateContent);
        $("textarea,input").bind('keydown', 'Ctrl+s meta+s', @updateContent);
        # Save the draft
        $("#editor").on("click", ".btn-preview", @updateDraft);
        $(document).bind('keydown', 'Ctrl+p meta+p', @updateDraft);  
        $("textarea,input").bind('keydown', 'Ctrl+p meta+p', @updateDraft);  

        # Toggle the editor
        $("#editor").on "click", ".heading, .editor-toggler", -> $("body").toggleClass "editor-toggled" 
        # Resize editor
        $("#editor").resizable({        
            handles: "e",
            ghost: true,
            minWidth: 300
        }).on "resizestop", -> 
            $("#workspace").css "left", $("#editor").outerWidth()
            setTimeout window.interactive.resize, 1000

        # Select embed code
        $("#editor-embed").on "click", -> this.select()

        # Tabs switch
        $("#editor .tabs-bar").on "click", "a", (event)->
            event.preventDefault()
            # Toggle the right tab link
            $("#editor .tabs-bar li").removeClass("active")
            $(this).parents("li").addClass("active")
            panId = $(this).attr("href") 
            # Hide pan
            $("#editor .tabs-pan").removeClass("active")
            $(panId).addClass("active")

        # Set delegated draggable 
        $(window).delegate(".spot", "mouseenter", @setSpotDraggable)   