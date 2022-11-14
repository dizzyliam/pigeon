import macros

type

    Verb* {.pure.} = enum
        GET = "GET"
        POST = "POST"
        PUT = "PUT"
        DELETE = "DELETE"
    
    Place* {.pure.} = enum
        urlPlace
        queryPlace
        bodyPlace
    
    Argument* = object
        name*: string
        kind*: NimNode
        place*: Place
    
    Route* = object
        name*: string
        url*: string
        verb*: Verb
        returns*: NimNode
        takes*: seq[Argument]
