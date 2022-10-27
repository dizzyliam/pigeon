import ajax
import json
import uri

proc request*(endPoint: string, meth: string, data: JsonNode): tuple[status: int, text: string] =
    var 
        httpRequest = newXMLHttpRequest()
        url = endPoint
    
    if meth == "GET":
        var args: seq[(string, string)]
        
        for i in data.keys():
            args.add (i, $data[i])
        
        if args.len > 0:
            url &= "?"
            url &= encodeQuery(args)

    httpRequest.open(meth, url, false)

    if meth == "POST":
        httpRequest.setRequestHeader("Content-Type", "application/json")
        httpRequest.send(($data).cstring)
    else:
        httpRequest.send()

    while httpRequest.readyState != rsDONE:
        continue
    
    return (status: httpRequest.status, text: $(httpRequest.response))
