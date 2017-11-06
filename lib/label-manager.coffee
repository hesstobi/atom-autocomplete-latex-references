{watchPath} =  require 'atom'
{CompositeDisposable} = require 'atom'
promisify = require "promisify-node"
fs = promisify('fs')
Fuse = require 'fuse.js'
glob = require 'glob'
path = require 'path'

module.exports =
class LabelManager
  labelTragetsCommandList: [
    "caption"
    "subcaption"
    "part"
    "chapter"
    "section"
    "subsection"
    "subsubsection"
    "paragraph"
    "subparagraph"
    "minisec"
  ]
  fuseOptions =
    shouldSort: true,
    threshold: 0.6,
    location: 0,
    distance: 100,
    maxPatternLength: 32,
    minMatchCharLength: 1,
    keys: ["label","description"]

  destroy: () ->
    @disposables.dispose()

  constructor: ->
    @disposables = new CompositeDisposable
    @databaseFiles = new Set()
    @database = {}
    @fuse = new Fuse(Object.values(@database),fuseOptions)

  initialize: ->
    return new Promise( (resolve, reject) =>
      @addDatabaseFiles()
      @registerForDatabaseChanges()
      @updateDatabase().then( (db) ->
        resolve()
        ).catch((error) ->
          console.log(error)
          reject(error)
        )
    )

  addDatabaseFiles: ->
    for ppath in atom.project.getPaths()
      # Add all files latex files in the project path to the watched files
      files = glob.sync(path.join(ppath, '**/*.tex'))
      for file in files
        @databaseFiles.add(path.normalize(file))

  searchForPrefixInDatabase: (prefix) ->
    @fuse.search(prefix)

  updateFileInDatabase: (path) ->

    targetList = @labelTragetsCommandList.join '|'

    regex = ///
      (\\ # latex command begin
      (#{targetList}) # caption or sections commands #2
      \*? # optimal star commands
      (\[.+?\])? # optional paramter #3
      {(.+?)} # arg of captions #4
      \s* # some white space
      )? # this is not nessary #1
      \\label # labels have to be defined with label
      {(((\w+):)?.+?)} # label #5 type #7
      ///g

    return new Promise((resolve, reject) =>
      fs.readFile(path, 'utf8').then( (data) =>
        match = regex.exec data
        while match
          entry =
            label: match[5]
            type: match[7] or 'undefined'
            description: match[4]
            path: path
          @database[match[5]] = entry
          match =  regex.exec data
        @fuse = new Fuse(Object.values(@database),fuseOptions)
        resolve(@database)
      ).catch( (error) ->
        reject(error)
      )
    )


  deleteFileInDatabase: (path) ->
    for key,value of @database
      if value.path is path
        delete @database[key]
    @fuse = new Fuse(Object.values(@database),fuseOptions)


  updateDatabase: ->
    # Return a Promise with updated Database
    return new Promise((resolve, reject) =>
      # Get Promise for each File in the Database
      promises = []
      @databaseFiles.forEach (file) =>
        promises.push(@updateFileInDatabase(file))
      # Parse the Data and resolve the Promise when all files
      # are parsed
      Promise.all(promises).then( (dataArray) =>
        resolve(@database)
      ).catch( (error) ->
        reject(error)
      )
    )

  registerForDatabaseChanges: ->
    watcher = atom.project.onDidChangeFiles  (events) =>
      events = events.filter (e) -> /tex$/.test(e["path"])
      for e in events
        switch e.action
          when "modified"
            @updateFileInDatabase(e.path)
          when "created"
            @databaseFiles.add(e.path)
            @updateFileInDatabase(e.path)
          when "deleted"
            @databaseFiles.delete(e.path)
            @deleteFileInDatabase(e.path)
    @disposables.add watcher
