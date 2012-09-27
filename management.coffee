validate = require('json-schema').validate
cfile = new require './fileops.coffee'
tunnelstatus = ""
dbmgmt =
    main: require('dirty') '/tmp/mgmttunnel.db'

tunnelSchema =
    name: "openvpn"
    type: "object"
    additionalProperties: false
    properties:
        pull: {"type":"boolean", "required":true}
        'tls-client': {"type":"boolean", "required":true}
        dev: {"type":"string", "required":true}
        proto: {"type":"string", "required":true}
        ca: {"type":"string", "required":true}
        dh: {"type":"string", "required":true}
        cert: {"type":"string", "required":true}
        key: {"type":"string", "required":true}
        remote: {"type":"string", "required":true}
        cipher: {"type":"string", "required":false}
        'tls-cipher': {"type":"string", "required":false}
        route:
            items: { type: "string" }
        push:
            items: { type: "string" }
        'persist-key': {"type":"boolean", "required":false}
        'persist-tun': {"type":"boolean", "required":false}
        status: {"type":"string", "required":false}
        'comp-lzo': {"type":"string", "required":false}
        verb: {"type":"number", "required":false}
        mlock: {"type":"boolean", "required":false}


@include = ->
    validateschema = ->
        result = validate @body, tunnelSchema.properties.description
        console.log result
        return @next new Error "Invalid schema posting!: #{result.errors}" unless result.valid
        @next()


    generatevpnConfig = ->
        for key, val of @body
            switch (typeof val)
                when "object"
                    if val instanceof Array
                        for i in val
                            config += "#{key} #{i}\n" if key is "route"
                            config += "#{key} \"#{i}\"\n" if key is "push"
                when "number", "string"
                    config += key + ' ' + val + "\n"
                when "boolean"
                    config += key + "\n"
        console.log "config: " + config
        return config


    @get  '/management/activation/action' : ->
        console.log "looking to issue activation #{@body.command}"
        switch @body.command
            when "start"
                # start the activation 
            when "restart"
                #clean up old activation stuff
            else return @next new Error "Invalid activation action specified, must be (start|restart)"

    @post '/management/tunnel', validateschema,  ->
        filename = "/config/management/openvpn/client.conf"
        cfile.createFile filename, (result) ->
            return result if result instanceof Error

        config = generatevpnConfig()

        cfile.updateFile config, filename, (result) ->
            return result if result instanceof Error

        dbmgmt.main.set "mgmt-tunnel", @body, ->
            console.log "mgmt tunnel configuration saved"
        tunnel-status = "configured"
        return {result:success}

# Return Management Tunnel Status
    @get '/management/tunnel' : ->
        return {"status": "#{tunnel-status}"}


    @post '/management/tunnel/action' : ->
        switch @body.command
            when "start", "stop", "restart", "sync"
                exec "svcs mgmttunnel #{@body.command}", (error, stdout, stderr) =>
                    return @next new Error "Unable to perform requested action!" if error
                    @send {result:true}
            else return @next new Error "Invalid action, must specify 'command' (start|stop|restart|sync)"

