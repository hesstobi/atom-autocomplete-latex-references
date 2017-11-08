LabelManager = require('./label-manager')

Array::where = (query, matcher = (a,b) -> a is b) ->
  return [] if typeof query isnt "object"
  hit = Object.keys(query).length
  @filter (item) ->
    match = 0
    for key, val of query
      match += 1 if matcher(item[key], val)
    if match is hit then true else false


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
        results = results.where type:'eq'
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
