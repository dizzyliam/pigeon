import ajax
import json
import uri

import types

proc request*(endpoint: string, 
    meth: Verb, 
    data: JsonNode, 
    arguments: seq[tuple[name: string, place: Place]] = @[]
): tuple[status: int, text: string] =

    var 
        httpRequest = newXMLHttpRequest()
        url = endpoint
        body: JsonNode
        params: seq[(string, string)]
    
    for arg in arguments:
        case arg.place:

            of queryPlace:
                params.add (arg.name, $data[arg.name])
            
            of bodyPlace:
                body[arg.name] = data[arg.name]
            
            else:
                continue
    
    if params.len > 0:
        url &= "?"
        url &= encodeQuery(params)

    httpRequest.open(($meth).cstring, url.cstring, false)

    if meth != GET:
        httpRequest.setRequestHeader("Content-Type", "application/json")
        httpRequest.send(($data).cstring)
    else:
        httpRequest.send()

    while httpRequest.readyState != rsDONE:
        continue
    
    return (status: httpRequest.status, text: $(httpRequest.response))
