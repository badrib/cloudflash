@include = ->
    handleProxyRequest = (zappaparams, callback) ->
        serverpath = ''
        console.log zappaparams[0]
        for key, value in zappaparams[2...1]
            serverpath += "/#{key}"
        #Fetch the destination using openvpn get userslist from the management tunnel
        #based on the commonname in the request
        console.log serverpath
        #webclient = new require './webclient.coffee'
        #webclient.fetchResponse "serverurl", "GET", "#{@body}", (statusCode, respString) ->
            #callback statusCode, respString

    @get '/webproxy/*' : ->
        #Fetch the IP address from the commonname
        zappasend = @send
        zappanext = @next
        handleProxyRequest @params, (statusCode, respString) ->
            @send statusCode, respString

    @del '/webproxy/*' : ->
        handleProxyRequest (statusCode, respString) ->
            @send statusCode, respString
    @post '/webproxy/*' : ->
        handleProxyRequest (statusCode, respString) ->
            @send statusCode, respString
        



    

