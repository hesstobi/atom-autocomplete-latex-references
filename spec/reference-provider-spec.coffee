describe "Latex Referemces Autocompletions", ->
  [editor, provider] = []

  getCompletions = ->
    cursor = editor.getLastCursor()
    bufferPosition = cursor.getBufferPosition()
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    # https://github.com/atom/autocomplete-plus/blob/9506a5c5fafca29003c59566cfc2b3ac37080973/lib/autocomplete-manager.js#L57
    prefix = /(\b|['"~`!@#$%^&*(){}[\]=+,/?>])((\w+[\w-]*)|([.:;[{(< ]+))$/.exec(line)?[2] ? ''
    request =
      editor: editor
      bufferPosition: bufferPosition
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    provider.getSuggestions(request)

  checkSuggestion = (text = 'fig:figure') ->
    waitsForPromise ->
      getCompletions().then (values) ->
        expect(values.length).toBeGreaterThan 0
        expect(values[0].text).toEqual text

  beforeEach ->

    atom.packages.triggerActivationHook('language-latex:grammar-used')
    atom.packages.triggerDeferredActivationHooks()
    atom.project.setPaths([__dirname])

    waitsForPromise -> atom.packages.activatePackage('autocomplete-latex-references')
    waitsForPromise -> atom.workspace.open('test.tex')

    runs ->
      provider = atom.packages.getActivePackage('autocomplete-latex-references').mainModule.provide()
      editor = atom.workspace.getActiveTextEditor()

    waitsFor -> Object.keys(provider.manager.database).length > 0


  it "returns no completions when not at the start of a tag", ->
    editor.setText('')
    expect(getCompletions()).not.toBeDefined()

    editor.setText('d')
    editor.setCursorBufferPosition([0, 0])
    expect(getCompletions()).not.toBeDefined()
    editor.setCursorBufferPosition([0, 1])
    expect(getCompletions()).not.toBeDefined()

  it "has no completions for prefix without first letter", ->
    editor.setText('\\ref{')
    expect(getCompletions()).not.toBeDefined()

  it "has completions for prefix starting with the first letter", ->
    editor.setText('\\ref{fig:fi')
    checkSuggestion()

  it "has completions for the pageref command", ->
    editor.setText('\\pageref{fig:fi')
    checkSuggestion()

  it "has completions for the autoref command", ->
    editor.setText('\\autoref{fig:fi')
    checkSuggestion()

  it "has completions for the nameref command", ->
    editor.setText('\\nameref{fig:fi')
    checkSuggestion()

  it "has completions for the vref command", ->
    editor.setText('\\vref{fig:fi')
    checkSuggestion()

  it "has completions for the eqref command", ->
    editor.setText('\\eqref{eq:eq')
    checkSuggestion('eq:equation')

  it "has has only equations for eqref", ->
    editor.setText('\\eqref{s')
    checkSuggestion('eq:section')

  it "it supports multiple arguments", ->
    editor.setText('\\ref{tab:table,fig:fi')
    checkSuggestion()

  it "has completions for stared versions of the commands", ->
    editor.setText('\\cref*{fig:fi')
    checkSuggestion()
