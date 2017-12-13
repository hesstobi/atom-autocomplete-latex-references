LabelManager = require('./label-manager')

module.exports =
class ReferenceProvider
  selector: '.meta.reference.latex'
  inclusionPriority: 2
  suggestionPriority: 3
  excludeLowerPriority: true


  constructor: ->
    @manager = new LabelManager()
    @manager.initialize()

  getSuggestions: ({editor, bufferPosition}) ->
    [prefix, cmd] = @getPrefix(editor, bufferPosition)
    return unless prefix?.length
    new Promise (resolve) =>
      results = @manager.searchForPrefixInDatabase(prefix)
      if cmd is 'eqref'
        # Filter results to see only equation
        results = results.filter( (obj) ->
          return obj.type == 'eq'
        )
      suggestions = []
      for result in results
        suggestion = @suggestionForResult(result, prefix)
        suggestions.push suggestion
      resolve(suggestions)

  suggestionForResult: (result, prefix) ->
    suggestion =
      text: result.label
      replacementPrefix: prefix
      type: result.type
      description: result.description if result.description?
      iconHTML: '<i class="icon-bookmark"></i>'

  onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->

  dispose: ->
    @manager = []

  getPrefix: (editor, bufferPosition) ->

    regex = ///
            \\(\w+) # group for commands
            \*? # Stared version of the commands
            { # Start of the argument
            (?:[\w-:]+,\s?)* # allow multiple references
            ([\w-:]+)$ # matching the prefix
            ///

    # Get the text for the line up to the triggered buffer position
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

    # Match the regex to the line, and return the match
    match = line.match(regex)
    prefix = match?[2] or ''
    cmd = match?[1] or ''

    return [prefix, cmd]
