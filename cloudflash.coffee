{@app} = require('zappajs') 5000, ->
    @configure =>
      @use 'bodyParser', 'methodOverride', @app.router, 'static'
      @set 'basepath': '/v1.0'

    @configure
      development: => @use errorHandler: {dumpExceptions: on, showStack: on}
      production: => @use 'errorHandler'

    @enable 'serve jquery', 'minify'

    @include 'services'
    @include 'personality'

    @include 'openvpn'
#    @include 'management'
#    @include 'openvpnlog'
#    @include 'firewall'

    @get '/test': ->
        @render index: {title: 'cloudflash', layout: no}

    @on 'set nickname': ->
        @client.nickname = @data.nickname

    @on serviceadded: ->
        @broadcast said: {nickname: @client.nickname, text: @data.text}
        @emit said: {nickname: @client.nickname, text: @data.text}

    @on servicedeleted: ->
        @broadcast said: {nickname: @client.nickname, text: @data.text}
        @emit said: {nickname: @client.nickname, text: @data.text}

    @on openvpnadded: ->
        @broadcast said: {nickname: @client.nickname, text: @data.text}
        @emit said: {nickname: @client.nickname, text: @data.text}

    @on firewalladded: ->
        @broadcast said: {nickname: @client.nickname, text: @data.text}
        @emit said: {nickname: @client.nickname, text: @data.text}


    @client '/index.js': ->
        @connect()

        @on serviceadded: ->
          $('#panel').append "<p>#{@data} and #{@text}</p>"

        $ =>
#          @emit 'set nickname': {nickname: prompt 'Pick a nickname!'}

          $('#box').focus()

          $('button').click (e) ->
            $form = $(this).closest('form')
            sid = $form.find('input[name="id"]').val()
            #console.log $form.attr('id')
            switch $form.attr('id')
                when 'create'
                    type = "POST"
                    url = '/services'
                    data = $form.serializeFormJSON()
                when 'action'
                    type = "POST"
                    url = "/services/#{sid}/action"
                    data = { 'command': $form.find('option:selected').val() }
                when 'delete'
                    type = "DELETE"
                    url = "/services/#{sid}"
                when 'personality'
                    type = "POST"
                    url = "/personality"
                    data = { 'personality': [ $form.serializeFormJSON() ] }

            json = JSON.stringify(data) if data
#            alert 'about to issue POST to: '+url+' with: '+json

            $.ajax
                type: type
                url: url
                data: json
                contentType: "application/json; charset=utf-8"
                success: (data) =>
                    @emit serviceevent: { text: data }

            e.preventDefault()


      #Have to implement encoded and decoding
      #work in progress..
      #after recieving the encoded base64 do the decode appropriate

      @client '/openvpn.js': ->
        @connect()

        @on openvpnadded: ->
          $('#panel').append "<p>#{@data.services.openvpn} said: #{@data.service.id}</p>"

        $ =>

          $('#box').focus()

          $('button').click (e) =>
             json =  $("#configdata").val()
             id = $("#id").val()
             unless id is " " and id is "undefined"
             	 $.ajax
                  type: "POST"
                  url: '/services/'+id+'/openvpn'
                  data: json
                  contentType: "application/json; charset=utf-8"
                  success: (data) =>
                      @emit openvpnadded: { text: $('#box').val() }


               e.preventDefault()

       @client '/firewall.js': ->
        @connect()

        @on firewalladded: ->
          $('#panel').append "<p>#{@data.services.firewall} said: #{@data.service.id}</p>"

        $ =>

          $('#box').focus()

          $('button').click (e) =>
             json =  $("#configdata").val()
             id = $("#id").val()

             unless id is " " and id is "undefined"
             	 $.ajax
                  type: "POST"
                  url: '/services/'+id+'/firewall'
                  data: json
                  contentType: "application/json; charset=utf-8"
                  success: (data) =>
                      @emit firewalladded: { text: $('#box').val() }


               e.preventDefault()

    @view index: ->
        doctype 5
        html ->
          head ->
            title 'CloudFlash Test Application!'
            script src: '/socket.io/socket.io.js'
            script src: '/zappa/jquery.js'
            script src: '/zappa/zappa.js'
            script src: '/jquery-json.js'
            script src: '/index.js'
          body ->
            div id: 'panel'
            div ->
                p 'Create a new Service'
                form '#create', ->
                    input
                        type: 'hidden'
                        name: 'version'
                        value: '1.0'
                    p ->
                        span 'Service Name: '
                        input '#name'
                            type: 'text'
                            name: 'name'
                            value: 'at'
                    p ->
                        span 'Service Type: '
                        input '#family',
                            type: 'text'
                            name: 'family'
                            value: 'remote-access'
                    p ->
                        span 'Package URL: '
                        input '#pkgurl',
                            type: 'text'
                            name: 'pkgurl'
                            value: 'http://10.1.10.145/vpnrac-0.0.1.deb'
                    button 'Send'
            div ->
                p 'Send an action to Service'
                form '#action', ->
                    p ->
                        span 'Service ID: '
                        input
                            type: 'text'
                            name: 'id'
                            value: ''
                    p ->
                        span 'Action: '
                        select name: 'action', ->
                            option value: 'start', 'Start'
                            option value: 'stop', 'Stop'
                            option value: 'restart', 'Restart'
                            option value: 'sync', 'Sync'
                    button 'Send'
            div ->
                p 'Delete a Service'
                form '#delete', ->
                    p ->
                        span 'Service ID: '
                        input '#id'
                            type: 'text'
                            name: 'id'
                            value: 'service id'
                    button 'Send'
            div ->
                p 'Post a Personality'
                form '#personality', ->
                    p ->
                        span 'Path: '
                        input '#path'
                            type: 'text'
                            name: 'path'
                            value: ''
                    p ->
                        span 'Contents: '
                        textarea '#contents'
                            name: 'contents'
                            value: ''
                    # p ->
                    #     span 'Postxfer: '
                    #     input '#postxfer'
                    #         type: 'text'
                    #         name: 'postxfer'
                    #         value: ''
                    button 'Send'

     @view openvpn: ->
          doctype 5
          html ->
            head ->
              title 'CloudFlash Test Application!'
              script src: '/socket.io/socket.io.js'
              script src: '/zappa/jquery.js'
              script src: '/zappa/zappa.js'
              script src: '/jquery-json.js'
              script src: '/openvpn.js'
            body ->
              div id: 'panel'
              form '#services', ->
                p ->
                      span 'Service Name: '
                      input '#name'
                          type: 'text'
                          name: 'name'
                          value: 'openvpn'
                p ->
                    span 'Service Type: '
                    input '#type',
                        type: 'text'
                        name: 'type'
                        value: 'vpn'
                p ->
                      span 'Service id: '
                      input '#id'
                          type: 'text'
                          name: 'guid'
                          value: 'openvpn guid'
                p ->
                      span 'Openvpn Config: '
                      input '#configdata'
                          type: 'text'
                          name: 'openvpnpostdata'
                          value: ''

                button 'Send'

      @view firewall: ->
          doctype 5
          html ->
            head ->
              title 'CloudFlash Test Application!'
              script src: '/socket.io/socket.io.js'
              script src: '/zappa/jquery.js'
              script src: '/zappa/zappa.js'
              script src: '/jquery-json.js'
              script src: '/firewall.js'
            body ->
              div id: 'panel'
              form '#services', ->
                p ->
                      span 'Service Name: '
                      input '#name'
                          type: 'text'
                          name: 'name'
                          value: 'firewall'
                p ->
                    span 'Service Type: '
                    input '#type',
                        type: 'text'
                        name: 'type'
                        value: 'iptables'
                p ->
                      span 'Service id: '
                      input '#id'
                          type: 'text'
                          name: 'guid'
                          value: 'firewall guid'
                p ->
                      span 'Firewall Config: '
                      input '#configdata'
                          type: 'text'
                          name: 'firewallpostdata'
                          value: ''

                button 'Send'

