import strutils
import macros
import json

macro clientSide*(body: untyped): untyped =
    if defined(js):
        return body

macro serverSide*(body: untyped): untyped =
    if not defined(js):
        return body

template setup*(body: untyped) = 
    serverSide:
        body

template marshal*(data: auto): untyped =
    when data is string:
        data
    else:
        $(%*data)

template unmarshal*(str: string, T: type): untyped =
    when T is string:
        str
    else:
        parseJson(str).to(T)