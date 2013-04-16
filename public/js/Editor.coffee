# Dependencies
#= require vendor/jquery-ui.min.js
#= require vendor/codemirror.js
#= require vendor/codemirror-javascript.js
#= require vendor/jquery.hotkeys.js
#= require vendor/notify-osd.min.js

class @Editor
    recordSpotPosition:(spot)=>
        # Shortcuts
        $this = $(spot)
        $step = $this.parents(".step")

        # Data
        step = $this.data("step")
        spot = $this.data("spot")
        page = $("body").data("page")
        left = parseInt($this.css("left")) / ($step.width() / 100)
        top = parseInt($this.css("top")) / ($step.height() / 100)

        # Round the values at 4 decimals
        left = (~~(left * 10000) / 10000) + "%"
        top = (~~(top * 10000) / 10000) + "%"

        # Send the value to update the json
        $.getJSON "/#{page}/#{step}/#{spot}",
          left: left
          top: top

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

    loadContent:() =>        
        page = $("body").data("page")
        $("#overflow").load "/#{page} #overflow > *", (data)->                                      
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

    loadDraft:() =>        
        page = $("body").data("page")
        $("#overflow").load "/#{page}?preview=1 #overflow > *", (data)->                                      
            window.interactive = new window.Interactive()
            $("#editor .btn-save").removeClass("disabled")

    updateError:(xhr) =>   
        $("#editor .btn").removeClass("disabled")
        $("body").removeClass("js-loading")
        $.notify_osd.create
            text    : xhr.responseText                     
            timeout : 5

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
        $("input,textarea", "#editor").bind('keydown', 'ctrl+s', @updateContent);
        # Save the draft
        $("#editor").on("click", ".btn-preview", @updateDraft);
        $("input,textarea", "#editor").bind('keydown', 'ctrl+p', @updateDraft);  

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

        $(".spot").draggable stop: (event, ui) ->
            @recordSpotPosition(this)

        # Add a focus class to the spot where we click
        $(".spot").on "click", (e) ->
            $(".spot").not(this).removeClass("focus")
            $(this).toggleClass("focus")

        # Disable other key events
        $(window).off("keyup keydown").on "keyup", (e)->        
            $div = $ '.js-current .spot.focus'
            if $div.length
                switch e.which
                    # left arrow key
                    when 37 then $div.css "left", '-=1%'                                
                    # up arrow key                
                    when 38 then $div.css "top", '-=1%'                                
                    # right arrow key                
                    when 39 then $div.css "left", '+=1%'                                
                    # bottom arrow key                
                    when 40 then $div.css "top", '+=1%'
                    # Or stop here
                    else return

                # Record the div position
                @recordSpotPosition $div


$(window).load -> window.editor = new window.Editor()