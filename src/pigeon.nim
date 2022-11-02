import strutils
import json
import macros

const methods = [
    "GET",
    "POST"
]

type Route = object
    name: string
    originalName: string
    rMethod: string
    returns: NimNode
    takes: seq[tuple[name: string, argType: NimNode]]
    postfix: string

macro clientSide*(body: untyped): untyped =
    if defined(js):
        return body

macro serverSide*(body: untyped): untyped =
    if not defined(js):
        return body

clientSide:
    import pigeon / request
    import uri

serverSide:
    import jester
    export jester

proc readName(route: var Route, name: string) {.compileTime.} =
    route.name = name
    route.originalName = name

    # Try to infer route method from the proc's name.
    for m in methods:

        if route.name.toLower.find(m.toLower) == 0:
            route.rMethod = m
            
            let first = route.name[route.rMethod.len].toLowerAscii
            route.name = first & route.name[route.rMethod.len+1..^1]

            break

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

    for def in body:
        
        if def.kind != nnkProcDef:
            error "Only procedure definitions are allowed in the autoRoute macro"

        var route: Route

        # Read the name of the proc.

        if def[0].kind == nnkIdent:
            route.readName def[0].strVal

        elif def[0].kind == nnkPostfix:
            route.readName def[0][1].strVal

        else:
            error "Could not read proc name"
        
        # Get the proc's return type.
        route.returns = def[3][0]

        # Parse out all the proc's arguments.
        if def[3].len > 1:

            for i in def[3][1..^1]:
                i.expectKind nnkIdentDefs

                for arg in i[0..^3]:
                    route.takes.add (name: arg.strVal, argType: i[^2])
        
        # See if there are any pragmas specifying a method.
        var pragmaIndex = -1
        for index, p in def[4]:

            if p.strVal.toUpper in methods:

                if pragmaIndex == -1:
                    pragmaIndex = index
                else:
                    error "Multiple HTTP methods specified by proc pragmas"

                if p.strVal.toUpper != route.rMethod:

                    route.rMethod = p.strVal.toUpper
                    route.name = route.originalName
                
                break

        # Cleanup leftover pragmas.

        if pragmaIndex != -1:
            def[4].del pragmaIndex

        if def[4].len == 0:
            def[4] = newEmptyNode()
        
        # Default to the POST method (assume unsafe).
        if route.rMethod == "":
            route.rMethod = "POST"
            warning "Defaulting to POST method for proc: " & route.originalName
        
        var count = 0
        for i in routes:
            if i.name == route.name and i.rMethod == route.rMethod:
                count += 1
        
        if count > 0:
            route.postfix = "/" & $count
        
        routes.add route

        # Define proc for the server to use.
        serverSide:
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
                endPoint = route.name & route.postfix
                rMethod = route.rMethod
                returns = route.returns
                responseIdent = ident "response"
            
            var resultStatement: NimNode
            if returns.kind != nnkEmpty:
                resultStatement = quote do:
                    return to(`responseIdent`.text.parseJson, `returns`)
            else:
                resultStatement = quote do:
                    return
            
            # An AJAX request is made and the result converted to the correct type.
            newContent.add quote do:
                let `responseIdent` = request(`endPoint`, `rMethod`, `pgArgs`)
                if response.status == 200:
                    `resultStatement`
                else:
                    raise newException(IOError, "HTTP Error " & $response.status)
                    
            result.add def
            result[^1][^1] = newContent

    # Build the jester router for the sever side.
    serverSide:

        var routerCases = newStmtList()

        let request = ident "request"
        let routeBlock = ident "route"

        for route in routes:

            let 
                rMethod = route.rMethod
                url = "/" & route.name & route.postfix

            var call = newNimNode(nnkCall)
            call.add newIdentNode(route.originalName)

            case rMethod:

                of "GET":
                    
                    # Build a function call with arguments taken from the request.
                    for t in route.takes:

                        let 
                            name = t.name
                            argType = t.argType

                        call.add quote do:
                            to(parseJson(@`name`), `argType`)
                    
                    # Add a case for the route.

                    if route.returns.kind != nnkEmpty:

                        routerCases.add quote do:
                            if `url` == `request`.pathInfo and `rMethod` == $(`request`.reqMeth):
                                let pgResult = `call`
                                resp %*pgResult
                    
                    else:

                        routerCases.add quote do:
                            if `url` == `request`.pathInfo and `rMethod` == $(`request`.reqMeth):
                                `call`
                                resp
                
                of "POST":

                    let jsonIdent = ident "pgJson"

                    # Build a function call with arguments taken from the request.
                    for t in route.takes:

                        let 
                            name = t.name
                            argType = t.argType

                        call.add quote do:
                            to(`jsonIdent`[`name`], `argType`)
                    
                    # Add a case for the route.
                    
                    if route.returns.kind != nnkEmpty:
                        
                        routerCases.add quote do:
                            if `url` == `request`.pathInfo and `rMethod` == $(`request`.reqMeth):
                                let `jsonIdent` = parseJson(`request`.body)
                                `call`
                                resp Http200
                    
                    else:

                        routerCases.add quote do:
                            if `url` == `request`.pathInfo and `rMethod` == $(`request`.reqMeth):
                                let `jsonIdent` = parseJson(`request`.body)
                                `call`
                                resp Http200

                else:
                    error "Unsupported request method"

        # Create the matching proc and start a Jester server.
        result.add quote do:
            proc match(`request`: Request): Future[ResponseData] {.async.} =
                block `routeBlock`:
                    `routerCases`

            let port = Port(`port`)
            let settings = newSettings(port=port)
            var jester = initJester(match, settings=settings)
            jester.serve()