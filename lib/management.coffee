
@include = ->
    cfile = new require 'fileops'
    exec = require('child_process').exec
    vpnlib = require('openvpn')

    @post '/management/tunnel': ->
        console.log vpnlib
        vpn = new vpnlib @request, @send, @params, @body, @next
        console.log vpn
        result = vpn.validateOpenvpnClient()
        if result instanceof Error
            return @next result
        else
            console.log 'schema is good'
            vpn.configClient "/etc/network/management.conf",(res) ->
                vpn.send res

    @get '/management/tunnel': ->
        vpn = new vpnlib @request, @send, @params, @body, @next
        #change the port and filename for management tunnel
        vpn.getInfo 2020,"/var/log/server-status.log","management", (result) ->
            vpn.send result

    @post '/management/tunnel/sync' : ->
        tunnelpid = ''
        zappasend = @send
        zappanext = @next
        #fetch tunnel pid and then do the following
        cfile.readFile "/var/run/mgmt.pid", (result) ->
            console.log 'after readfile' + result
            throw new Error result if result instanceof Error
            tunnelpid =  result
            console.log 'tunnel pid is: ' + tunnelpid
            exec "kill -9 #{tunnelpid}", (error, stdout, stderr) ->
                console.log 'after sending command' + error
                if error
                    zappanext new Error "Unable to perform requested action!"
                else
                    zappasend {result:true}

    '''
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

    @post '/system/:id/config/*' : ->
        # this is a req from activation script in CPE to fetch init config.
        activate = require 'webproxy'
        zappasend = @send
        zappanext = @next
        activate.fetchInitConfig "#{@body.url}", "#{@body.method}", "#{@body.body}" , (statusCode, respString) ->
            if statusCode == 200
                zappasend respString
            else
                zappanext new Error respString

    '''
