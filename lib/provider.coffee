$ = require('jquery')
path = require 'path'
util = require './util'
XQUtils = require './xquery-helper'
InScopeVariables = require './var-visitor'

MIN_LENGTH = 3

module.exports =
    class Provider
        selector: '.source.xq, .source.xql, .source.xquery, .source.xqm'
        inclusionPriority: 1
        excludeLowerPriority: true
        config: undefined

        constructor: (@config) ->
            require('atom-package-deps').install().then(
                () ->
                    console.log("Initializing provider")
            )

        getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
            prefix = @getPrefix(editor, bufferPosition)

            if prefix.indexOf('$') != 0 and prefix.length < MIN_LENGTH then return []

            params = util.modules(@config, editor)
            params.push("prefix=" + prefix)
            console.log("getting suggestions for %s", prefix)
            self = this
            return new Promise (resolve) ->
                $.ajax
                    url: self.config.getConfig(editor).server +
                        "/apps/atom-editor/atom-autocomplete.xql?" +
                            params.join("&")
                    username: self.config.getConfig(editor).user
                    password: self.config.getConfig(editor).password
                    success: (data) ->
                        localFuncs = self.getLocalSuggestions(editor, prefix)
                        variables = self.getInScopeVariables(editor, prefix)
                        resolve(variables.concat(localFuncs).concat(data))

        getPrefix: (editor, bufferPosition) ->
            # Whatever your prefix regex might be
            regex = /\$?[:\w0-9_-]+$/

            # Get the text for the line up to the triggered buffer position
            line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

            # Match the regex to the line, and return the match
            line.match(regex)?[0] or ''

        getLocalSuggestions: (editor, prefix) ->
            regex = new RegExp("^" + prefix)
            localFuncs = []
            for fn in util.parseLocalFunctions(editor) when regex.test(fn.name)
                text: fn.signature
                type: fn.type
                snippet: fn.snippet
                replacementPrefix: prefix
                localFuncs.push(fn)
            localFuncs

        getInScopeVariables: (editor, prefix) ->
            ast = editor.getBuffer()._ast
            return [] unless ast?
            pos = editor.getCursorBufferPosition()
            node = XQUtils.findNode(ast, { line: pos.row, col: pos.column - 1})
            prefix = prefix.substring(1)
            if node?
                parent = node.getParent
                if parent.name == "VarRef" or parent.name == "VarName"
                    visitor = new InScopeVariables(ast, parent)
                    vars = visitor.getStack()
                    if vars?
                        regex = new RegExp("^" + prefix)
                        variables = []
                        for v in vars.sort() when regex.test(v)
                            def =
                                text: "$" + v
                                type: "variable"
                                snippet: v
                                replacementPrefix: prefix
                            variables.push(def)
                        return variables
            return []