fs = require 'fs'
path = require 'path'
exec = require('child_process').exec

class fileops
    createFile: (filename, callback) ->
        try
            dir = path.dirname filename
            unless path.existsSync dir
                console.log 'no path exists'
                exec "mkdir -p #{dir}", (error, stdout, stderr) =>
                    unless error
                        console.log 'created path'
                        exec "touch #{filename}"
            else
                console.log 'path exists'
                exec "touch #{filename}", (error, stdout, stderr) =>
                    callback(error) if error
                    callback(true)
        catch err
            console.log  "Unable to create file #{filename}"
            callback (err)

    removeFile: (filename, callback) ->
        fs.unlink filename, (error)->
            callback(error)

    updateFile: (filename, config) ->
        fs.writeFileSync filename, config

    fileExists: (filename, callback) ->
        stats = fs.existsSync filename
        if stats.isFile
            callback({result:true})
        else
            console.log 'File does not exist'
            error = new Error "File does not exist"
            callback(true)

    readFile: (filename, callback) ->
        @fileExists filename, (result) ->
            if result instanceof Error
                callback(result)
            else
                buf = fs.readFileSync filename, 'utf-8'
                callback(buf)

       
module.exports = new fileops
