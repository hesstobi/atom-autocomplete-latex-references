describe "Autocomplete Latex References Package", ->
  {workspaceElement} = []

  beforeEach ->

    atom.packages.triggerActivationHook('language-latex:grammar-used')
    atom.packages.triggerDeferredActivationHooks()

    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise -> atom.packages.activatePackage('autocomplete-latex-references')

   describe 'when the autocomplete-latex-references:show-database-info event is triggered', ->
     it 'shows a notification', ->
       atom.commands.dispatch(workspaceElement, 'autocomplete-latex-references:show-database-info')
       noti = atom.notifications.getNotifications()
       expect(noti).toHaveLength 1
       expect(noti[0].message).toEqual "Autocomplete Latex References Database Info"
       expect(noti[0].type).toEqual "info"
