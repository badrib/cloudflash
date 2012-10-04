cloudflash
==========

CloudFlash is a web framework for cloud based automation of openvpn, firmware, modules, and services.

CloudFlash supports JSON data serialization format. The format for both the request and the response
should be specified by using the Content-Type header, the Accept header.

Steps to Install
===============
1) Download cloudflash files into your system
2) Run the follwing commands in cloudflash directory
   - npm install 
   - sudo coffee cloudflash.coffee

Note: During new service post, deb package uses npm to fetch the published package

*List of APIs*
==============

<table>
  <tr>
    <th>Verb</th><th>URI</th><th>Description</th>
  </tr>
  <tr>
    <td>GET</td><td>/services</td><td>List summary of services installed in VCG identified by service ID</td>
  </tr>
  <tr>
    <td>POST</td><td>/services</td><td>Create a new service in VCG</td>
  </tr>
  <tr>
    <td>GET</td><td>/services/service-id</td><td>Describes an installed service in VCG by service ID</td>
  </tr>
  <tr>
    <td>DELETE</td><td>/services/service-id</td><td>Delete an installed service in VCG by service ID</td>
  </tr>
  <tr>
    <td>POST</td><td>/services/service-id/openvpn</td><td>Modify existing OpenVPN configuration</td>
  </tr>
  <tr>
    <td>POST</td><td>/services/service-id/firewall</td><td>Modify existing Firewall configuration</td>
  </tr>
  <tr>
    <td>POST</td><td>/services/service-id/action</td><td>Execute command on the VCG</td>
  </tr>

</table>


*URI structure*

For now there is no API version specified in either URI or JSON data. But, in future we plan to use
API version in the URI.

For example

      /services/V1.0/service family/service type


*Authentication*

Current implementation of cloudflash in VCG does not require that each request will include the credntials of
the user submiting the request.
Plan is to have OAuth scheme of authentication.

*Services API*
==============

 List Services
--------------

    Verb	URI	        Description
    GET	/services	Lists summary of services configured in VCG identified by service ID.


Note: The request does not require a message body.
Success: Returns JSON data with list of services installed on VCG. Each service is identified by service ID

The service ID is generated is a UUID.

Service Family is the generic service type while name is the actual service name.

pkgurl: The package download link provided to VCG

api: Supported APIs for this service.

*Note: Currently no validation of the package contents done*

*TODO: Caller to provide md5sum of the package along with pkgurl*


**Example Request and Response**

*Request*

    GET /services HTTP/1.1

*Response*

```
{
    "services": [
        {
            "id": "40860f06-7dcf-41ab-a414-98957b092b7b",
            "status": "installed"
            "api": "/vpnrac",
			"description": {
				 "name": "at",
            	 "family": "remote-access",
			     "version": "1.0",
            	 "pkgurl": "http://my-url.com/vpnrac-0.0.1.deb"
			}
        }
    ]
}
```

Create Service
---------------


    Verb	URI	        Description
    POST	/services	Create a new service in VCG.


The request **must** have the following parameters in JSON data

      1. service version
      2. service Name
      3. Service Family
      4. Package URL

On success it returns JSON data with the UUID for the service created.

**Example Request and Response**

### Request JSON

    {
    	"name": "at",
    	"family": "remote-access",
    	"version": "1.0",
    	"pkgurl": "http://my-url.com/vpnrac-0.0.1.deb"
    }


### Response JSON

    {
        "id": "61df014d-90cd-4f6f-8928-0a3aadff4658",
        "description": {
            "version": "1.0",
            "name": "at",
            "family": "remote-access",
            "pkgurl": "http://10.1.10.145/vpnrac-0.0.1.deb",
            "id": "48c8d63e-1a3e-4f99-bf2b-a8c5c57afe8d"
        },
        "api": "/to/be/defined/in/future",
        "status": {
            "installed": true
        }
    }

Describe Service
----------------

    Verb	URI	                 Description
    GET	    /services/service-id	  Show a service in VCG specified by service-ID

**Example Request and Response**

### Request Headers

    GET /services/d40d38bd-aab0-4430-ac61-4b8ee91dc668 HTTP/1.1

### Response JSON

    {
        "id": "492e025d-2ae7-49e6-b27d-441ba3784ce3",
        "description": {
            "version": "1.0",
            "name": "at",
            "family": "remote-access",
            "pkgurl": "http://10.1.10.145/vpnrac-0.0.1.deb",
            "id": "7aeeb1a6-88ae-401b-95b6-c5d059b77db0"
        },
        "status": {
            "installed": true,
            "initialized": false,
            "enabled": false,
            "running": false,
            "result": "/home/plee/hack.node/cloudflash\n"
        }
    }

Delete a service
----------------

    Verb	URI	                 Description
    DELETE	/services/service-id	  Delete a service in VCG specified by service-ID


On Success returns 200 with JSON data

*TODO: Return appropriate error code and description in case of failure.*

**Example Request and Response**

### Request Headers

    DELETE /services/d40d38bd-aab0-4430-ac61-4b8ee91dc668 HTTP/1.1

### Response JSON

    { deleted: true }


Action Command API
------------------
This API is used to perform the action like start, stop, restart and sync on the installed services as identified by service-id


    Verb	URI	                 Description
    POST	/services/service-id/action	  Execute an action command

**Example Request and Response**

### Request Headers

    POST /services/a12796b8-c786-4351-ba7d-4b95cd8e0797/action HTTP/1.1

### Request JSON

    { command: "stop" }

### Response JSON

    { result: true }


*OpenVPN API*
=============

Post openVPN Configuration
--------------------------

    Verb	URI	        		Description
    POST	/services/service-id/openvpn	 Update the openvpn server.conf file in VCG.

On success it returns JSON data with the service-id, service Name, config success.

*TODO: Define JSON format for error codes and description.*

**Example Request and Response**

### Request Headers


### Request JSON

    {
        port: "7000",
        dev: "tun",
        proto: "udp",
        ca: "/etc/ca-bundle.pem"
        dh: "/etc/dh1024.pem"
        cert: "/etc/identity/snap.cert",
        key: "/etc/identity/snap.key",
        server: "172.17.0.0 255.255.255.0",
        'script-security': "3 system",
        multihome: true,
        management: "127.0.0.1 2020",
        cipher: "AES-256-CBC",
        'tls-cipher': "AES256-SHA",
        auth: "SHA1",
        topology: "subnet",
        'route-gateway': "172.17.0.1"
        'client-config-dir': "/config/openvpn/ccd"
        'ccd-exclusive': true,
        'ccd-to-client': true,
        route: [ "192.168.0.0 255.255.255.0", "192.168.1.0 255.255.255.0" ],
        push:  [ "route 192.168.3.0 255.255.255.0", "comp-lzo no" ],
        'max-clients': "254",
        'persist-key': true,
        'persist-tun': true,
        status: "/var/log/server-status.log",
        keepalive: "5 45",
        'comp-lzo': "no",
        sndbuf: "262144"
        rcvbuf: "262144"
        txqueuelen: "500"
        'replay-window': "512 15"
        verb: "3"
        mlock: true
    }

### Response JSON


	{ result: true }


Upon error, error code 500 will be returned


Add a User to VPN
-----------------

    Verb	URI	        		                 Description
    POST	/services/service-id/openvpn/users	 Add user into client-config-directory

On success it returns JSON data with the service-id, service Name, config success.

**Example Request and Response**

### Request Headers


### Request JSON

    {
    	id: "492e025d-2ae7-49e6-b27d-441ba3784ce3",
    	email: "master@oftheuniverse.com",
    	push: [
    		"dhcp-option DNS x.x.x.x",
    		"ip-win32 dynamic",
    		"route-delay 5"
    	]
    }

### Response JSON

	{ result: true }

Upon error, error code 500 will be returned


Delete a User from VPN
----------------------

    Verb	URI	                 Description
    DELETE	/services/service-id/openvpn/users/user-id	  Delete user from client-config-directory


On Success returns 200 with JSON data

**Example Request and Response**

### Request Headers

    DELETE /services/d40d38bd-aab0-4430-ac61-4b8ee91dc668/openvpn/users/a5ce61b6-80ff-4cfa-aa49-9efe83c0c80b HTTP/1.1

### Response JSON

    { deleted: true }

Describe OpenVPN
----------------

    Verb	URI	                 Description
    GET	    /services/service-id/openvpn	  Show OpenVPN info in VCG specified by service-ID

**Example Request and Response**

### Request Headers

    GET /services/d40d38bd-aab0-4430-ac61-4b8ee91dc668/openvpn HTTP/1.1

### Response JSON

    {
        "id": "d40d38bd-aab0-4430-ac61-4b8ee91dc668",
        "users": [
			{
    			id: "492e025d-2ae7-49e6-b27d-441ba3784ce3",
    			email: "master@oftheuniverse.com",
    			push: [
    				"dhcp-option DNS x.x.x.x",
    				"ip-win32 dynamic",
    				"route-delay 5"
    			]
			}
        ],
		"connections": [
			{
				cname: "e-mail or UUID",
				remote: "1.2.3.4:1234",
				ip: "172.17.0.4",
				received: 12345,
				sent: 54321,
				since: "Tue Jul 17 12:17:18 2012"
			}
		]
    }

Please note that the top-level `id` returned above refers to the service-ID.

Upon error, error code 500 will be returned


*Firewall API (Currently N/A)*
==============================

Modify the firewall Config
--------------------------


            Verb	URI	        			Description
             POST	/services/service-id/firewall		 Update the firewall firewall.sh file in VCG.


The request must have the following parameters in JSON data

      1. service Name
      2. service Type
      3. Service id
      4. firewall base64 encrypted value

On success it returns JSON data with the service-id, service Name, command success.

*TODO: Define JSON format for error codes and description.*

**Example Request and Response**

### Request Headers

```
Response Headersview source
Connection	keep-alive
Content-Length	95
Content-Type	application/json; charset=utf-8
X-Powered-By	Express
Request Headersview source
Accept	*/*
Accept-Encoding	gzip, deflate
Accept-Language	en-us,en;q=0.5
Cache-Control	no-cache
Connection	keep-alive
Content-Length	1107
Content-Type	application/json; charset=utf-8
Host	10.2.56.153:3000
Pragma	no-cache
Referer	http://10.2.56.153:3000/services/415794ee-c6f7-4545-a5a6-3253448de10e/firewall
User-Agent	Mozilla/5.0 (Windows NT 5.1; rv:12.0) Gecko/20100101 Firefox/12.0
X-Requested-With	XMLHttpRequest
Response Headers From Cache
Connection	keep-alive
Content-Length	95
Content-Type	application/json; charset=utf-8
X-Powered-By	Express
```

### Request JSON

            { "services":
                        { "firewall" :
                                      {
					"command":"IyEvYmluL3NoDQppcHRhYmxlcyAoKSB7IHRlc3QgIiQyIiAhPSAic2hvcmV3YWxsIiAmJiBzYWZlX2NhbGwgaXB0YWJsZXMgJEA7IH0NCg0Kc2FmZV9jYWxsICgpIHsNCgliaW49JCh3aGljaCAkMSkNCglzaGlmdA0KCSRiaW4gJEANCglpZiBbICQ/		ICE9IDAgXTsgdGhlbiANCgkgICAgaXB0YWJsZXMtcmVzdG9yZSA8IC9jb25maWcvaXB0YWJsZXMuc2F2ZQ0KCSAgICBleGl0IDENCglmaQ0KfQ0KIyBxdCAoKSB7ICIkQCIgPi9kZXYvbnVsbCAyPiYxIH0NCg0KaWYgWyAteCAvYmluL2J1c3lib3ggXTsgdGhlbg0KCSMgWFhYIC0gaGFjayAtIGJ1ZyB3aXRoIGlwdGFibGVzLXNhdmUgaW4gcnVudCBpbWFnZQ0KCWNwIC9ldGMvbmV0d29yay9pcHRhYmxlcy5kZWZhdWx0IC9jb25maWcvaXB0YWJsZXMuc2F2ZQ0KZWxzZQ0KCWlwdGFibGVzLXNhdmUgPiAvY29uZmlnL2lwdGFibGVzLnNhdmUNCmZpDQoNClsgLWYgL2NvbmZpZy9pcHRhYmxlcy9mdW5jdGlvbnMgXSAmJiAuIC9jb25maWcvaXB0YWJsZXMvZnVuY3Rpb25zDQoNCmlwdGFibGVzIC1MIHNob3Jld2FsbCAtbg0KaXB0YWJsZXMgLUYgc2hvcmV3YWxsDQppcHRhYmxlcyAtWCBzaG9yZXdhbGwNCmlwdGFibGVzIC10IG5hdCAtRg0KaXB0YWJsZXMgLXQgbmF0IC1YDQppcHRhYmxlcyAtdCBuYXQgLVAgUFJFUk9VVElORyBBQ0NFUFQNCmlwdGFibGVzIC10IG5hdCAtUCBQT1NUUk9VVElORyBBQ0NFUFQNCmlwdGFibGVzIC10IG5hdCAtUCBPVVRQVVQgQUNDRVBUDQppcHRhYmxlcyAtdCBtYW5nbGUgLUYNCmlwdGFibGVzIC10IG1hbmdsZSAtWA0K"
                                      }
			}
	}


### Response JSON


        {
           "services":{
                        "id":"415794ee-c6f7-4545-a5a6-3253448de10e",
                        "name":"iptable",
                        "command":"success"
                       }
         }


