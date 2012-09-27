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
        @send result if result instanceof Error
        vpn.configClient(res) ->
            vpn.send res

    @post '/services/:id/openvpn/server', loadService, ->
        vpn = new vpnlib @request, @send, @params, @body, @next
        result = vpn.validateOpenvpnServer()
        @send result if result instanceof Error
        vpn.configServer (res) ->
            vpn.send res
    
    #@post '/services/:id/openvpn/server', vpn.loadService, vpn.validateOpenvpnServer, vpn.configServer

    #@post '/services/:id/openvpn/users', vpn.loadService, vpn.validateUser, vpn.adduser

    #@del '/services/:id/openvpn/users/:user', vpn.loadService, vpn.deluser

    @get '/services/:id/openvpn', loadService, ->
        @send 'hi'
        #vpn = new vpnlib @request, @send, @params, @body, @next
        vpn.getInfo
