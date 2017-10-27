LabelManager = require('./label-manager')

module.exports =
class ReferenceProvider
  selector: '.text.tex.latex'
  disableForSelector: '.comment'
  inclusionPriority: 2
  suggestionPriority: 3
  excludeLowerPriority: false

  constructor: ->
    @manager = new LabelManager()
    @manager.initialize()

  getSuggestions: ({editor, bufferPosition}) ->
    prefix = @getPrefix(editor, bufferPosition)
    return unless prefix?.length
    new Promise (resolve) =>
      results = @manager.searchForPrefixInDatabase(prefix)
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
            \\(ref|pageref|autoref|nameref|vref|eqref) # group for commands
            {([\w-:]+)$ # macthing the prefix
            ///

    # Get the text for the line up to the triggered buffer position
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

    # Match the regex to the line, and return the match
    line.match(regex)?[2] or ''
