# Dependencies
#= require vendor/jquery-ui.min.js
#= require vendor/codemirror.js
#= require vendor/codemirror-javascript.js
#= require vendor/jquery.hotkeys.js
#= require vendor/notify-osd.min.js

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
        updateJsonEditor(content)


    updateJsonEditor:(content)=>        
        if typeof content == "string"
            value = content
        else
            # stringify the object
            value =  JSON.stringify content, null, 4
        # Add the new configuration file to the editor
        @myCodeMirror.setValue value if @myCodeMirror.getValue() != value
        
    updateScreen:()=>        
        # Get the JSON
        content = JSON.parse @myCodeMirror.getValue()
        # Update the theme by changing the body class
        bodyClass = "editor-mode theme-" + (content.theme || "default")
        $("body").attr("class", bodyClass)
        # Update the app title
        $("head title").text(content.title)
        $("#editor .screen-title").text(content.title)
        # Update the container navigation
        navigation = content.navigation || "horizontal"
        $("#overflow")
            .css("width", content.width)
            .css("margin-left", content.width/-2)
            .css("height", content.height)
            .css("margin-top", content.height/-2)
            .removeClass("horizontal vertical")
            .addClass(navigation)
            .data("navigation", navigation);


    updateContent:() =>
        unless $("body").hasClass("js-loading") or $("#editor .btn-save").hasClass("disabled")
            $("body").addClass("js-loading")            
            $("#editor .btn").addClass("disabled")
            content = @myCodeMirror.getValue()
            token   = $("body").data("given-token");
            page    = $("body").data("page")
            $.ajax
                url: "/#{page}/content"
                type: "POST"
                data: { content: content, token: token }
                success: @loadContent
                error: @updateError             
        return false

    loadContent:(content) =>        
        page = $("body").data("page")
        @updateJsonEditor(content)
        $("#overflow").load "/#{page} #overflow > *", ()=>                                      
            @updateScreen()
            window.interactive = new window.Interactive()

    updateDraft:() =>
        unless $("body").hasClass("js-loading") or $("#editor .btn-save").hasClass("disabled")
            $("body").addClass("js-loading")            
            $("#editor .btn").addClass("disabled")
            content = @myCodeMirror.getValue()
            token   = $("body").data("given-token");
            page    = $("body").data("page")
            $.ajax
                url: "/#{page}/draft"
                type: "POST"
                data: { content: content, token: token }
                success: @loadDraft
                error: @updateError                               
        return false

    loadDraft:(content) =>        
        page = $("body").data("page")
        @updateJsonEditor(content)
        $("#overflow").load "/#{page}?preview=1 #overflow > *", ()=>                                      
            @updateScreen()
            window.interactive = new window.Interactive()
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


    constructor: ->
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
        $(document).bind('keydown', 'Ctrl+s', @updateContent);
        $("textarea,input").bind('keydown', 'Ctrl+s', @updateContent);
        # Save the draft
        $("#editor").on("click", ".btn-preview", @updateDraft);
        $(document).bind('keydown', 'Ctrl+p', @updateDraft);  
        $("textarea,input").bind('keydown', 'Ctrl+p', @updateDraft);  

        # Toggle the editor
        $("#editor").on "click", ".editor-toggler", -> $("body").toggleClass "editor-toggled" 
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
        $("#overflow").delegate(".spot", "mouseenter", @setSpotDraggable)   

        # Select the whole content of the URL
             


$(window).load -> window.editor = new window.Editor()