import strutils
import macros
import regex

import types

proc readName(route: var Route, name: string) {.compileTime.} =
    route.name = name

    # Try to infer route method from the proc's name.
    for m in HttpMethod:

        if route.name.toLower.find(($m).toLower) == 0:
            route.verb = m

proc makeRoute*(def: NimNode, spec: RouteSpec): Route {.compileTime.} =

    # Default to the POST method (assume unsafe).
    result.verb = HttpPost

    if def[0].kind == nnkIdent:
        result.readName def[0].strVal

    elif def[0].kind == nnkPostfix:
        result.readName def[0][1].strVal

    else:
        error "Could not read proc name"
    
    # Override verb from spec.
    if spec.active:
        result.verb = spec.verb
    
    # Get the proc's return type.
    result.returns = def[3][0]

    if spec.active:
        result.url = spec.url
    else:
        result.url = "/" & result.name

    # Check for a native prologue route.
    if def[3].len == 2 and def[3][1][1].strVal == "Context":
        result.isPrologue = true
        return
    
    # Parse out all the proc's arguments.
    if def[3].len > 1:

        for i in def[3][1..^1]:
            i.expectKind nnkIdentDefs

            for arg in i[0..^3]:

                var place = bodyPlace

                if result.verb in [HttpHead, HttpGet, HttpDelete]:
                    place = queryPlace
                
                if ("{" & arg.strVal & "}") in result.url:
                    place = urlPlace

                result.takes.add Argument(name: arg.strVal, kind: i[^2], place: place, default: i[^1])


