import macros

import httpcore
export httpcore

type
    
    Place* {.pure.} = enum
        urlPlace
        queryPlace
        bodyPlace
    
    Argument* = object
        name*: string
        kind*: NimNode
        place*: Place
        default*: NimNode
    
    Route* = object
        name*: string
        url*: string
        suffix*: int
        isPrologue*: bool
        verb*: HttpMethod
        returns*: NimNode
        takes*: seq[Argument]
    
    RouteSpec* = object
        active*: bool
        verb*: HttpMethod
        url*: string
