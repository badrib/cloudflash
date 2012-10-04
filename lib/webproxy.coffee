@include = ->
    handleProxyRequest = (zappaparams, zappabody, method, callback) ->
        serverpath = ''
        for key, value in zappaparams
            serverpath += "/#{key}"
        #Fetch the destination using openvpn get userslist from the management tunnel
        #based on the commonname in the request
        console.log 'zappa parameters rcvd ' + zappaparams
        console.log 'server path is ' + serverpath
        serverurl = 'http://127.0.0.1:5000' + "#{serverpath}"
        console.log 'serverpath is ' + serverpath
        client = require './webclient'
        client.fetchResponse serverurl, method , zappabody, (statusCode, respString) ->
            console.log 'webproxy got response'
            callback statusCode, respString

    @get '/webproxy/:id/*' : ->
        #Fetch the IP address from the commonname
        zappasend = @send
        zappanext = @next
        handleProxyRequest @params, @body, "GET", (statusCode, respString) ->
            console.log 'about to send response ' + respString
            if statusCode == 200
                zappasend respString
            else
                zappasend respString, statusCode

    @del '/webproxy/:id/*' : ->
        zappasend = @send
        zappanext = @next
        handleProxyRequest @params, @body, "DELETE", (statusCode, respString) ->
            console.log 'about to send response'
            console.log statusCode
            console.log respString
            if statusCode == 200
                zappasend respString
            else
                zappasend respString, statusCode

    @post '/webproxy/:id/*' : ->
        zappasend = @send
        zappanext = @next
        handleProxyRequest @params, @body, "POST", (statusCode, respString) ->
            console.log 'about to send response'
            if statusCode == 200
                zappasend respString
            else
                zappasend respString, statusCode
        

    @put '/webproxy/:id/*' : ->
        zappasend = @send
        zappanext = @next
        handleProxyRequest @params, @body, "PUT",  (statusCode, respString) ->
            console.log 'about to send response'
            if statusCode == 200
                zappasend respString
            else
                zappasend respString, statusCode
        




    

