fs = require 'fs'

serial-key = ''
module.exports = class activation
    constructor = (nexusserver, nexusport, activationserver, activationport) ->
        @nexusserver = nexusserver
        @nexusport = nexusport
        @activationserver = activationserver
        @activationport = activationport
        @serialkey = ''
        @configpath = "/registration/#{@serialkey}/config"


    activate = ->
        try
            exec "/config/activation/bootstrap.sh"
        catch err
            console.log 'Error in activating the CPE'
        return fileExists("/var/run/activated")

        
    fetchInitConfig = (serialkey, callback) ->
        httpclient = new require './webclient.coffee'
        httpclient.fetchResponse "http://#{@partnerserver}:#{@partnerport}#{@configurepath}", "GET", " " , (statusCode, respString) ->
            if statusCode != 200
                return new Error respString
            
            respjson = JSON.parse(respString)
            #Parse through the recvd response and call cloudflash APIs
            for key, val of respjson
                switch (typeof val)
                    when "object"
                        if val instanceof Array
                            for i in val
                                httpclient.fetchResponse "#{i.url}", "#{i.method}", "#{i.body}", (statusCode, respString) ->
                                    if statusCode != 200
                                        console.log "failed to process the url: " + "#{i.method} #{i.url}"  
                                        callback (statusCode, respString)
                                        
        
            callback (200, {result:success})
        







    





