
class webclient
    constructor: ->
        console.log 'webclient initialized'

    fetchResponse: (urlstring, method, body, callback) ->
        console.log 'url is ' + urlstring
        url = require 'url'
        parsedurl = url.parse urlstring, true
        console.log 'parsed url is ' + parsedurl
        port = 80
        if parsedurl.port
            port = parsedurl.port

        http = require 'http'
        options =
            host : "#{parsedurl.hostname}",
            port : "#{port}",
            method : "#{method}",
            path : "#{parsedurl.path}"

        console.log 'options to http request ' + options
        req = http.request options, (res) ->
            console.log 'got response'
          
        req.on 'error', (error) ->
           console.log error
           callback 500, error
      
        console.log 'body sending to the server ' + JSON.stringify(body)
        req.setHeader "Content-Type", "application/json"
        req.setHeader "Connection", "Keep-Alive"
        req.write JSON.stringify(body) if body.length

        buf = new Buffer(102400)
        size = 0
        statusCode = 200
        req.on 'response', (resp) ->
            statusCode = resp.statusCode
            if statusCode != 200
                console.log 'recvd response code:' + statusCode
            '''
                callback statusCode, {"No valid response recevied"}
            '''
            resp.on 'data', (chunk) ->
                console.log "response rcvd "
                respstr = chunk.toString "utf-8", 0, chunk.length

                chunk.copy(buf, size, 0 , chunk.length)
                size += chunk.length
            resp.on 'end', () ->
                respString  = buf.toString "utf-8", 0, size
                console.log 'size of buffer is :' + respString.length
                console.log 'status code is: ' + statusCode
                callback statusCode, respString

            resp.on 'close', () ->
                console.log 'connection closed abruptly'

        req.end()
        console.log 'request ended with buf' if buf.length

module.exports = new webclient
