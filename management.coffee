cfile = new require './fileops.coffee'
vpnlib = new require './openvpnlib.coffee'
tunnelstatus = ''
tunnel-pid = ''

@include = ->
    @get  '/management/activation/action' : ->
        return @next new Error "Invalid service posting!" unless @body.command
        console.log "looking to issue activation #{@body.command}"
        switch @body.command
            when "start"
                # start the activation 
                console.log ''
            when "restart"
                #clean up old activation stuff
                console.log ''
            else return @next new Error "Invalid activation action specified, must be (start|restart)"

    @post '/management/tunnel', vpnlib.validateschema, vpnlib.configClient ("/etc/network/management.conf")

    @get '/management/tunnel', vpnlib.getInfo

    @post '/management/tunnel/sync' : ->

        #fetch tunnel pid and then do the following
        cfile.readFile filename, (result) ->
            @send new Error result if result instanceof Error
            tunnel-pid =  result
            exec "kill -9 #{tunnel-pid}", (error, stdout, stderr) =>
                console.log stderr
                return @next new Error "Unable to perform requested action!" if error
                tunnelstatus = 'up'
                @send {result:true}

    @post '/system/:id/config/*' : ->
        # this is a req from activation script in CPE to fetch init config.
        activate = new require './activation.coffee'
        activate.fetchInitConfig "#{@body.url}", "#{@body.method}", "#{@body.body}" , (statusCode, respString) ->
            if statusCode == 200
                @send respString
            else
                @send new Error respString
