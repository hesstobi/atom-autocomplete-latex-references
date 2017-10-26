{ CompositeDisposable } = require 'atom'

configSchema = require './config'

module.exports =
  config: configSchema
  provider: null
  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable()

    # Add command to Atom
    this.subscriptions.add(atom.commands.add('atom-workspace',
      {'autocomplete-latex-references:show-database-info': () => @showDatabaseInfo()}))


  # Get Database Informations
  showDatabaseInfo: ->
    message = "Autocomplete Latex References Database Info"
    options = {
      'dismissable': true
      'icon': 'database'
    }

    if @provider?
      db = @provider.manager.database

      if Object.keys(db).length
        num = Object.keys(db).length
        groups = {}
        for k,v of db
          if !(v.type of groups)
            groups[v.type] = 0
          groups[v.type] = groups[v.type]+1
        numGroups = Object.keys(groups).length

        list = ''
        for k,v of groups
          list += "* #{k}: `#{v}`\n"

        options['description'] = """
          There are `#{num}` references defined with `#{numGroups}`
          different types:

          #{list}
        """
      else
        options['description'] = '''
          There are no references found. Did you defined some with
          `\\label{}`?
        '''
    else
      options['description'] = "Provider not initialized."

    atom.notifications.addInfo(message,options)

  deactivate: ->
    @provider = null
    @subscriptions.dispose()

  provide: ->
    unless @provider?
      ReferenceProvider = require('./reference-provider')
      @provider = new ReferenceProvider()

    @provider
