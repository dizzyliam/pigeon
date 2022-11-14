import strutils
import macros

import types

proc readName(route: var Route, name: string) {.compileTime.} =
    route.name = name

    # Try to infer route method from the proc's name.
    for m in Verb:

        if route.name.toLower.find(($m).toLower) == 0:
            route.verb = m

proc makeRoute*(def: var NimNode): Route {.compileTime.} =

    # Default to the POST method (assume unsafe).
    result.verb = POST

    if def[0].kind == nnkIdent:
        result.readName def[0].strVal

    elif def[0].kind == nnkPostfix:
        result.readName def[0][1].strVal

    else:
        error "Could not read proc name"
    
    # Get the proc's return type.
    result.returns = def[3][0]
    
    # See if there are any pragmas specifying a method.
    var pragmaIndex = -1
    for index, p in def[4]:
        
        for m in Verb:

            if m != result.verb and p.strVal.toUpper == $m:
                result.verb = m

                if pragmaIndex == -1:
                    pragmaIndex = index
                else:
                    error "Multiple HTTP methods specified by proc pragmas"

    # Cleanup leftover pragmas.

    if pragmaIndex != -1:
        def[4].del pragmaIndex

    if def[4].len == 0:
        def[4] = newEmptyNode()
    
    # Parse out all the proc's arguments.
    if def[3].len > 1:

        for i in def[3][1..^1]:
            i.expectKind nnkIdentDefs

            for arg in i[0..^3]:

                var place = bodyPlace
                if result.verb == GET:
                    place = queryPlace

                result.takes.add Argument(name: arg.strVal, kind: i[^2], place: place)


