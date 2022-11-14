import macros

macro clientSide*(body: untyped): untyped =
    if defined(js):
        return body

macro serverSide*(body: untyped): untyped =
    if not defined(js):
        return body