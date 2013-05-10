class window.UserMenu
  constructor:->
    @ui = $("#user-menu")
    @uis =
      foldable: @ui.find(".foldable")
      foldHandle: @ui.find(".foldable .handle")

    @bindUI()

  bindUI:=>
    @uis.foldHandle.on "click", @openFoldable

  openFoldable:(ev)=>
    $foldable = $(ev.currentTarget).parents(".foldable")
    # Folds every other foldables
    @uis.foldable.not( $foldable ).addClass "fold"
    # Unfold the current one
    $foldable.removeClass "fold"