import ajax
import json
import uri

import types

proc request*(url: string, 
    meth: HttpMethod, 
    body: JsonNode
): tuple[status: int, text: string] =

    var httpRequest = newXMLHttpRequest()
    httpRequest.open(($meth).cstring, url.cstring, false)

    if body.len > 0:
        httpRequest.setRequestHeader("Content-Type", "application/json")
        httpRequest.send(($body).cstring)
    else:
        httpRequest.send()

    while httpRequest.readyState != rsDONE:
        continue
    
    return (status: httpRequest.status, text: $(httpRequest.response))
