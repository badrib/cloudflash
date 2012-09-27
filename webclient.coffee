

module.exports = class webclient
    constructor = ->
        console.log 'webclient initialized'

    fetchResponse = (url, method, body, callback) ->
        url = require 'url'
        parsedurl = url.parse "url", 0, true
        http = require 'http'
        options.host = parsedurl.host
        options.port = parsedurl.port

        #Get initial config from partner
        options.method = method
        options.path = parsedurl.path
        req = http.request options, (res) ->
            console.log 'got response'
          
        req.on 'error', (error) ->
           console.log error
           callback (500, error)
      
        console.log JSON.stringify(body)
        req.setHeader "Content-Type", "application/json"
        req.write JSON.stringify(body)
        
        buf = new Buffer(102400)
        size = 0
        statusCode = 200
        req.on 'response', (resp) ->
            statusCode = resp.statusCode
            if statusCode != 200
                callback (statusCode, "No valid response recevied")

            resp.on 'data', (chunk) ->
                console.log "response rcvd "
                respstr = chunk.toString "utf-8", 0, chunk.length

                chunk.copy(buf, size, 0 , chunk.length)
                size += chunk.length
            resp.on 'end', () ->
                respString  = buf.toString "utf-8", 0, size
                console.log 'size of buffer is :' + respString.length
                console.log 'status code is: ' + statusCode
                callback (statusCode, respString)
        req.end()

