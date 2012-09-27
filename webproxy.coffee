@include = ->
    handleProxyRequest = (callback) ->
        serverpath = ''
        for key, value in @request.params
            serverpath += "/#{key}"
        #Fetch the destination using openvpn get userslist from the management tunnel
        #based on the commonname in the request
        destination = ''
        webclient = new require './webclient.coffee'
        webclient.fetchResponse "serverurl", "GET", "#{@body}", (statusCode, respString) ->
            callback (statusCode, respString)

    @get '/webproxy/*' : ->
        handleProxyRequest (statusCode, respString) ->
            @send statusCode, respString

    @del '/webproxy/*' : ->
        handleProxyRequest (statusCode, respString) ->
            @send statusCode, respString
    @post '/webproxy/*' : ->
        handleProxyRequest (statusCode, respString) ->
            @send statusCode, respString
        



    

