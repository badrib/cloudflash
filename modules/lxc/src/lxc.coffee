
fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
validate = require('json-schema').validate
url = require("url")
uuid = require('node-uuid')
webreq = require 'request'

dblxc =
    main: require('dirty') '/tmp/lxc.db'

module.exports = class lxc
  constructor: (@request, @body, @params) ->
    console.log "initialized lxc"

  sample: ->
    console.log "sample function"
    return "true"

  # createlxcContainer: creates a linux container, the container name will be randomly created service id 
  createlxcContainer: () ->
    console.log "in createlxcContainer"
    service = { }
    service.id = uuid.v4()
    service.description = desc = @body
    service.description.id ?= uuid.v4()

    # check if the ID already exists in DB, if so, we reject       
    return new Error "Duplicate service ID detected!" if dblxc.main.get service.id

    console.log "checking if lxc package is installed"
    lxcpath = "/usr/bin/lxc"
    if path.existsSync lxcpath
      console.log "lxc installed"
      name = service.id
      console.log "create lxc by name: #{name}"
      # create lxc clone from coffeeCN master container which has cloudflash installed
      exec "sudo lxc-clone -o cloudCN -n #{name}", (error, stdout, stderr) =>
        unless error
           console.log " start error: #{error}"
           console.log " start stdout: #{stdout}"
           # verify lxc container created from stdout
           if stdout.match /created/
               result = { result: true }
               service.status = { created: true }
               dblxc.main.set service.id, service, =>
                  console.log service
                  return result
           else
               return new Error "Failed to create lxc #{name}!"
        else
           return new Error "lxc-clone command failed: " + error
    else
      return new Error "Unable to find lxc!"

     
  # serviceHandler: Main function of this module which gets called by external applications to 
  # route lxc API endpoints.
  # On Error, returns error message. On Successful handling, sends appropriate JSON object with success.
  serviceHandler:  ->
    pathname = url.parse(@request.url).pathname
    console.log "pathname in lxc: " + pathname
    console.log "req method in lxc: " + @request.method
    reqMethod = @request.method
    
    switch reqMethod
      when "POST"
        switch pathname
          when "/services/#{@params.id}/lxc"
            console.log "creating a lxc container"
            res = @createlxcContainer()
            console.log res
            return res
 
          when "/services/#{@params.id}/lxc/start"
            console.log 'starting the lxc container'
    
          when "/services/#{@params.id}/lxc/stop"
            console.log 'stopping the lxc container'

