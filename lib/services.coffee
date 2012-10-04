# validation is used by other modules
validate = require('json-schema').validate

@db = db = require('dirty') '/tmp/cloudflash.db'

db.on 'load', ->
    console.log 'loaded cloudflash.db'
    db.forEach (key,val) ->
        console.log 'found ' + key

@lookup = lookup = (id) ->
    console.log "looking up service ID: #{id}"
    entry = db.get id
    if entry

        if schema?
            console.log 'performing schema validation on retrieved service entry'
            result = validate entry, schema
            console.log result
            return new Error "Invalid service retrieved: #{result.errors}" unless result.valid

        return entry
    else
        return new Error "No such service ID: #{id}"

@schema = schema =
    name: "service"
    type: "object"
    additionalProperties: false
    properties:
        class:    { type: "string" }
        id:       { type: "string" }
        api:      { type: "string" }
        description:
            type: "object"
            required: true
            additionalProperties: false
            properties:
                id:     {"type": "string"}
                name:   {"type": "string", "required": true}
                family: {"type": "string", "required": true}
                version:{"type": "string", "required": true}
                pkgurl: {"type": "string", "required": true}
        status:
            type: "object"
            required: false
            additionalProperties: false
            properties:
                installed:   { type: "boolean" }
                initialized: { type: "boolean" }
                enabled:     { type: "boolean" }
                running:     { type: "boolean" }
                result:      { type: "string"  }

@include = ->
    zappainclude = @include
    uuid = require('node-uuid')

    webreq = require 'request'
    fs = require 'fs'
    path = require 'path'
    exec = require('child_process').exec


    @get '/services': ->
        res = { 'services': [] }
        db.forEach (key,val) ->
            console.log 'found ' + key
            res.services.push val
        console.log res
        @send res

    # POST/PUT VALIDATION
    # 1. need to make sure the incoming JSON is well formed
    # 2. destructure the inbound object with proper schema
    validateServiceDesc = ->

        console.log @body

        console.log 'performing schema validation on incoming service JSON'
        result = validate @body, schema.properties.description
        console.log result
        return @next new Error "Invalid service posting!: #{result.errors}" unless result.valid
        @next()

    # helper routine for retrieving service data from dirty db
    loadService = ->
        result = lookup @params.id
        unless result instanceof Error
            @request.service = result
            @next()
        else
            return @next result

    @post '/services', validateServiceDesc, ->
        service = { }
        service.id = uuid.v4()
        service.description = desc = @body
        service.description.id ?= uuid.v4()

        # 1. check if the ID already exists in DB, if so, we reject
        # 2. check if package already installed, if so, we we skip download...
        return @next new Error "Duplicate service ID detected!" if db.get service.id
        zappainclude "./node_modules/#{service.description.name}/api/#{service.description.name}"

        console.log "checking if the package has already been installed..."
        exec "dpkg -l #{desc.name} | grep #{desc.name}", (error, stdout, stderr) =>
            unless error
                service.api = "/to/be/defined/in/future"
                service.status = { installed: true }
                db.set service.id, service, =>
                    console.log "'#{desc.name}' already installed successfully, initialized as new service ID: #{service.id}"
                    console.log service
                    @send service
            else
                # let's download this file from the web
                filename = "/tmp/#{service.id}.pkg"
                webreq(desc.pkgurl, (error, response, body) =>
                    # 1. verify that file has been downloaded
                    # 2. dpkg -i filename
                    # 3. verify that package has been installed
                    # 4. XXX - figure out the API endpoint dynamically
                    # 5. return success message back
                    return @next new Error "Unable to download service package! Error was: #{error}" if error?

                    console.log "checking for service package at #{filename}"
                    if path.existsSync filename
                        console.log 'found service package, issuing dpkg -i'
                        exec "dpkg -i -F depends #{filename}", (error, stdout, stderr) =>
                            return @next new Error "Unable to install service package!" if error

                            console.log "verifying that the package has been installed as #{desc.name}"
                            exec "dpkg -l #{desc.name}", (error, stdout, stderr) =>
                                return @next new Error "Unable to verify service package installation!" if error

                                # XXX - TODO figure out the API endpoint for this new package...
                                service.api = "/to/be/defined/in/future"
                                service.status = { installed: true }
                                db.set service.id, service, =>
                                    console.log "#{desc.pkgurl} downloaded and installed successfully as service ID: #{service.id}"
                                    console.log service
                                    @send service
                    else
                        return @next new Error "Unable to download and install service package!"
                    ).pipe(fs.createWriteStream(filename))

    @get '/services/:id', loadService, ->
        service = @request.service

        # for debugging the below command is uncommented. Kindly enable this
        #exec "pwd", (error, stdout, stderr) =>
        exec "svcs #{service.description.name} status", (error, stdout, stderr) =>
            if error or not stdout?
                service.status = null
            else
                status =
                    installed: service.status?.installed?
                    initialized: false
                    enabled: false
                    running: false
                    result: stdout

                console.log stdout

                if stdout.match /disabled/
                    status.initialized = true
                else if stdout.match /enabled/
                    status.enabled = true
                    unless stdout.match /not running/
                        status.running = true

                service.status = status

            console.log service
            @send service


    @put '/services/:id', validateServiceDesc, loadService, ->
        # XXX - can have intelligent merge here

        # PUT VALIDATION
        # 1. need to make sure the incoming JSON is well formed
        # 2. destructure the inbound object with proper schema
        # 3. perform 'extend' merge of inbound service data with existing data
        service = @request.service

        # desc = @body
        # @body = entry
        # @body.description ?= desc if desc?

        db.set service.id, service, ->
            console.log "updated service ID: #{service.id}"
            console.log service
            @send service
            # do some work

    @del '/services/:id', loadService, ->
        # 1. verify that the package is actually installed
        # 2. perform dpkg -r PACKAGENAME
        # 3. remove the service entry from DB
        service = @request.service
        desc = service.description
        console.log "verifying that the package has been installed as #{desc.name}"
        #delFilePath = __dirname+'/services/'+service.id
        exec "dpkg -l #{desc.name}", (error, stdout, stderr) =>
            return @next new Error "Unable to verify service package installation!" if error

            console.log "removing the service package: dpkg -r #{desc.name}"
            exec "dpkg -r #{desc.name}", (error, stdout, stderr) =>
                return @next new Error "Unable to remove service package '#{desc.name}': #{stderr}" if error
                db.rm service.id, =>
                    console.log "removed service ID: #{service.id}"
                    # exec "rm -rf #{delFilePath}", (error, stdout, stderr) =>
                    #      return @next new Error "Unable to remove services directory : #{desc.name}!" if error
                    @send { deleted: true }

    @post '/services/:id/action', loadService, ->
        return @next new Error "Invalid service posting!" unless @body.command
        service = @request.service
        desc = service.description

        console.log "looking to issue 'svcs #{desc.name} #{@body.command}'"
        switch @body.command
            when "on", "start", "off", "stop","restart", "sync"
                exec "svcs #{desc.name} #{@body.command}", (error, stdout, stderr) =>
                #exec "pwd", (error, stdout, stderr) =>
                    return @next new Error "Unable to perform requested action!" if error
                    @send { result: true }

            else return @next new Error "Invalid action, must specify 'command' (on|off,start|stop,restart,sync)!"
