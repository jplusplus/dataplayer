class window.UserMenu
  constructor:->
    @ui = $("#user-menu")
    @uis =
      foldable    : @ui.find(".foldable")
      foldHandle  : @ui.find(".foldable .handle")
      logIn       : $("[data-action=logIn]")
      signUp      : $("[data-action=signUp]")

    @bindUI()

  bindUI:=>
    @uis.foldHandle.on "click", @openFoldable
    @uis.logIn.on "click", @logIn
    @uis.signUp.on "click", @signUp
    @ui.on "mouseleave", @close

  openFoldable:(ev)=>
    $foldable = $(ev.currentTarget).parents(".foldable")
    # Folds every other foldables
    @uis.foldable.not( $foldable ).addClass "fold"
    # Unfold the current one
    $foldable.removeClass "fold"

  open:=> @ui.addClass "open"
  
  close:=> @ui.removeClass "open"

  logIn:=>    
    # Open the menu
    @open()
    # Folds every other foldables
    @uis.foldable.addClass "fold"
    # Unfold the log in one
    @uis.foldable.filter(".logIn").removeClass "fold"

  signUp:=>
    # Open the menu
    @open()
    # Folds every other foldables
    @uis.foldable.addClass "fold"
    # Unfold the log in one
    @uis.foldable.filter(".signUp").removeClass "fold"


