#FindDeclarationView = require './find-declaration-view'
{CompositeDisposable} = require 'atom'

module.exports = FindDeclaration =
  subscriptions: null
  find: null

  activate: (state) ->
    if not atom.packages.isPackageActive('find-and-replace')
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'find-and-replace:toggle')
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'find-and-replace:toggle')

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'find-declaration:goto': => @goto()

    path = require 'path'
    packagePath = atom.packages.resolvePackagePath('find-and-replace')
    @find = require path.join(packagePath, 'lib', 'find')

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
    # nope

  openFile: (filename, line) ->
      atom.open({'pathsToOpen': [filename + ':' + line], 'newWindow': false})

  goto: ->
    console.log 'gotoDeclaration'

    return if not @find

    editor = atom.workspace.getActiveTextEditor()
    editor?.selectWordsContainingCursors()
    currentSymbol = editor?.getSelectedText()
    return if not currentSymbol?.length
    originalSymbol = '' + currentSymbol
    currentSymbol = '' + currentSymbol + '[^a-zA-Z0-9,."\']'

    @find.createViews()
    @find.findPanel.hide()
    @find.projectFindPanel.hide()

    @find.findOptions.set({'useRegex': true, 'caseSensitive': true})
    @find.projectFindView.findEditor.setText(currentSymbol)
    resultsModel = @find.resultsModel
    openFile = @openFile
    @find.projectFindView.search().then () ->
        count = resultsModel.getMatchCount()
        console.log(count)
        console.log(resultsModel)
        if count is 1
            filename = resultsModel.paths[0]
            matches = resultsModel.results[filename].matches
            openFile filename, matches[0].range[0][0]
        else
            funcRegex = new RegExp('\\s*function\\s+' + originalSymbol)
            func2Regex = new RegExp(originalSymbol + '\\s+=\\s+function')
            for filename in resultsModel.paths
                for match in resultsModel.results[filename].matches
                    if match.lineText.match(funcRegex) || match.lineText.match(func2Regex)
                        openFile filename, match.range[0][0]
