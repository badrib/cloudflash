# validation is used by other modules
validate = require('json-schema').validate
cfile = new require './fileops.coffee'
@include = ->
    vpnlib = require './openvpnlib'
    services = require './services'

    loadService = ->
        result = services.lookup @params.id
        unless result instanceof Error
            @request.service = result
            @next()
        else
            return @next result

    @post '/services/:id/openvpn/client', loadService, ->
        vpn = new vpnlib @request, @send, @params, @body, @next
        result = vpn.validateOpenvpnClient()
        if result instanceof Error
            return @next result
        else
            console.log 'schema is good'
            vpn.configClient (res) ->
                vpn.send res

    @post '/services/:id/openvpn/server', loadService, ->
        vpn = new vpnlib @request, @send, @params, @body, @next
        result = vpn.validateOpenvpnServer()
        if result instanceof Error
            return @next result
        else
            vpn.configServer (res) ->
                vpn.send res
    
    @post '/services/:id/openvpn/users', loadService, ->
        vpn = new vpnlib @request, @send, @params, @body, @next
        result = vpn.validateUser()
        if result instanceof Error
            return @next result
        else
            vpn.addUser (res) ->
                vpn.send res

    @del '/services/:id/openvpn/users/:user', loadService, ->
        vpn = new vpnlib @request, @send, @params, @body, @next
        vpn.delUser (res) ->
            vpn.send res

            
    @get '/services/:id/openvpn', loadService, ->
        vpn = new vpnlib @request, @send, @params, @body, @next
        vpn.getInfo 2020,"/var/log/server-status.log", @request.service.id, (result) ->
            vpn.send result
