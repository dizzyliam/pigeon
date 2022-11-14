import strutils
import macros
import json

import pigeon / [
    utils,
    types,
    route
]

clientSide:
    import pigeon / request
    import uri

serverSide:
    import jester
    export jester

macro autoRoute*(args: varargs[untyped]): untyped =

    # Allow a port to be specified.
    var port = newIntLitNode(8080)
    if args.len == 2:
        port = args[0]
    elif args.len > 2:
        error "Too many arguments for autoRoute"
    
    let body = args[^1]

    result = newStmtList()
    var routes: seq[Route]

    for statement in body:
        
        if statement.kind != nnkProcDef:
            error "Only procedure definitions are allowed in the autoRoute macro"

        # Make a route object.
        var def = statement
        let route = makeRoute def
        routes.add route

        # Define proc.
        result.add def

        # Create new innards for the client side version of the proc.
        clientSide:
            
            var newContent = newStmtList()
                
            var pgArgs = newIdentNode("pgArgs")
            
            # Arguments are collected into a JSON object.
            newContent.add quote do:
                var `pgArgs` = %*{}

            for arg in route.takes:
                let 
                    name = arg.name
                    nameIdent = newIdentNode(arg.name)
                newContent.add quote do:
                    `pgArgs`[`name`] = %*`nameIdent`
            
            let 
                endPoint = route.name
                verb = route.verb
                returns = route.returns
                responseIdent = ident "response"
            
            var resultStatement: NimNode
            if returns.kind != nnkEmpty:
                resultStatement = quote do:
                    return to(`responseIdent`.text.parseJson, `returns`)
            else:
                resultStatement = quote do:
                    return

            var arguments: seq[tuple[name: string, place: Place]]
            for t in route.takes:
                arguments.add (name: t.name, place: t.place)
            
            # An AJAX request is made and the result converted to the correct type.
            newContent.add quote do:
                let `responseIdent` = request(`endPoint`, Verb(`verb`), `pgArgs`, `arguments`)
                if response.status == 200:
                    `resultStatement`
                else:
                    raise newException(IOError, "HTTP Error " & $response.status)
                    
            result[^1][^1] = newContent

            echo newContent.treeRepr

    # Build the jester router for the sever side.
    serverSide:

        var routerCases = newStmtList()

        let request = ident "request"
        let routeBlock = ident "route"

        for route in routes:

            let 
                verb = $route.verb
                url = "/" & route.name

            var call = newNimNode(nnkCall)
            call.add newIdentNode(route.name)

            let jsonIdent = ident "pgJson"

            # Build a function call with arguments taken from the request.
            for t in route.takes:

                let 
                    name = t.name
                    kind = t.kind
                    place = t.place
                
                case place:

                    of bodyPlace:
                        call.add quote do:
                            to(`jsonIdent`[`name`], `kind`)
                    
                    else:
                        call.add quote do:
                            to(parseJson(@`name`), `kind`)
            
            # Add a case for the route.
            
            if route.returns.kind != nnkEmpty:
                
                routerCases.add quote do:
                    if `url` == `request`.pathInfo and `verb` == $(`request`.reqMeth):
                        let `jsonIdent` = parseJson(`request`.body)
                        resp `call`
            
            else:

                routerCases.add quote do:
                    if `url` == `request`.pathInfo and `verb` == $(`request`.reqMeth):
                        let `jsonIdent` = parseJson(`request`.body)
                        `call`
                        resp Http200

        # Create the matching proc and start a Jester server.
        result.add quote do:
            proc pgMatch(`request`: Request): Future[ResponseData] {.async.} =
                block `routeBlock`:
                    `routerCases`

macro serve*(
    port: static[int] = 8080, 
    staticDir: static[string] = "./public"
) =

    return quote do:
        serverSide:

                let 
                    settings = newSettings(
                        port = Port(`port`), 
                        staticDir = `staticDir`
                    )

                var jester = initJester(pgMatch, settings=settings)
                jester.serve()
        
        clientSide:
            discard