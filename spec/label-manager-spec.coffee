LabelManager = require '../lib/label-manager'

describe "When the LabelManger gets initialized", ->
  manager = null

  beforeEach ->
    atom.project.setPaths([__dirname])
    manager = new LabelManager()
    waitsForPromise ->
      manager.initialize()

  it "is not null", ->
    expect(manager).not.toEqual(null)

  it "add the project dir to the databaseFiles", ->
    expect(manager.databaseFiles.size).toEqual(1)
    expect(manager.databaseFiles.has(__dirname))

  it "parses the tex files in the project dir", ->
    expect(Object.keys(manager.database).length).toEqual(14)
    expect(manager.database['fig:figure'].description).toEqual('Test Figure Label')
    expect(manager.database['fig:figure'].label).toEqual('fig:figure')
    expect(manager.database['fig:figure'].type).toEqual('fig')

  it "can search with prefixes in the database", ->
    result  = manager.searchForPrefixInDatabase('fig:fi')
    expect(result[0].label).toEqual('fig:figure')
