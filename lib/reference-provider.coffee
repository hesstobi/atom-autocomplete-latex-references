LabelManager = require('./label-manager')

module.exports =
class ReferenceProvider
  selector: '.text.tex.latex'
  disableForSelector: '.comment'
  inclusionPriority: 2
  suggestionPriority: 3
  excludeLowerPriority: false
  refCommandList: [
    "ref"
    "pageref"
    "autoref"
    "nameref"
    "vref"
    "eqref"
  ]


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

    cmdprefixes = @refCommandList.join '|'

    regex = ///
            \\(#{cmdprefixes}) # group for commands
            {([\w-:]+)$ # macthing the prefix
            ///

    # Get the text for the line up to the triggered buffer position
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

    # Match the regex to the line, and return the match
    prefix = line.match(regex)?[2] or ''
    cmd = line.match(regex)?[1] or ''

    return [prefix, cmd]
