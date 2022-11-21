import algorithm
import strutils
import macros
import json

import pigeon / [
    utils,
    types,
    route
]

export utils
export to

clientSide:
    import pigeon / request
    import uri

serverSide:
    import prologue
    export prologue

# This macro is massively too long 
# and I intend to further break it down into procs.
macro autoRoute*(args: varargs[untyped]): untyped =
    
    let 
        body = args[^1]
        pgApp = ident "pgApp"

    result = newStmtList()

    serverSide:
        result.add quote do:
            var `pgApp` = newApp()

    var 
        routes: seq[Route]
        spec: RouteSpec

    for statement in body:
        
        if statement.kind == nnkCommand:
            for v in HttpMethod:
                if ($v).toLower == statement[0].strVal.toLower:
                    
                    spec = RouteSpec(
                        active: true,
                        verb: v,
                        url: statement[1].strVal
                    )

                    break
            continue

        # Make a route object.
        var def = statement
        var route = makeRoute(def, spec)
        spec.active = false

        # Check for url double ups.
        for r in routes.reversed:
            if r.url == route.url:
                
                try:
                    route.suffix = r.url.split("/")[^1].parseInt
                except ValueError:
                    route.suffix = 1
                
                route.url &= "/" & $route.suffix
                break

        # Add the route.
        routes.add route

        let
            url = route.url
            verb = newLit route.verb
            returns = route.returns
            routeNameLit = ident route.name
        
        # Handle native prologue routes.
        if route.isPrologue:

            serverSide:
                result.add def
                result.add quote do:
                    `pgApp`.addRoute(`url`, `routeNameLit`, @[`verb`])
            
            continue
        
        # Add proc definition.
        result.add def

        # Create new innards for the client side version of the proc.
        clientSide:

            let 
                responseIdent = ident "response"
                pgBody = ident "pgBody"
                pgUrl = ident "pgUrl"
                pgParams = ident "pgParams"
            
            var newContent = newStmtList()
            newContent.add quote do:
                var 
                    `pgBody` = %*{}
                    `pgUrl` = `url`
                    `pgParams`: seq[(string, string)]
            
            for t in route.takes:

                let
                    argName = newLit t.name
                    argIdent = ident t.name

                case t.place:

                    of bodyPlace:
                        newContent.add quote do:
                            `pgBody`[`argName`] = %*`argIdent`
                    
                    of urlPlace:
                        newContent.add quote do:
                            `pgUrl` = `pgUrl`.replace("{" & `argName` & "}", marshal(`argIdent`))
                    
                    of queryPlace:
                        newContent.add quote do:
                            `pgParams`.add (`argName`, marshal(`argIdent`))
            
            var resultStatement: NimNode
            if returns.kind != nnkEmpty:
                resultStatement = quote do:
                    return unmarshal(`responseIdent`.text, `returns`)
            else:
                resultStatement = quote do:
                    return
            
            # An AJAX request is made and the result converted to the correct type.
            newContent.add quote do:

                if `pgParams`.len > 0:
                    `pgUrl` &= "?" & encodeQuery(`pgParams`)

                let `responseIdent` = request(`pgUrl`, `verb`, `pgBody`)
                if response.status == 200:
                    `resultStatement`
                else:
                    raise newException(IOError, "HTTP Error " & $response.status)
                    
            result[^1][^1] = newContent

        # Build the server side route.
        serverSide:

            let 
                handlerName = ident(route.name & "PGHandler" & $route.suffix)
                ctx = ident "ctx"
                body = ident "body"

            var handler = quote do:
                proc `handlerName`(`ctx`: Context) {.async.} =
                    var `body` = %*{}
                    if `ctx`.request.contentType == "application/json":
                        `body` = parseJson `ctx`.request.body

            var call = newCall ident(route.name)

            for arg in route.takes:

                let 
                    argName = newLit arg.name
                    argTmpName = ident "pgTmp" & arg.name
                    argType = arg.kind
                    default = arg.default

                case arg.place:

                    of urlPlace:
                        handler[^1].add quote do:
                            var `argTmpName`: `argType` = `default`
                            if `ctx`.getPathParamsOption(`argName`).isSome:
                                `argTmpName` = unmarshal(`ctx`.getPathParamsOption(`argName`).get, `argType`)
                    
                    of queryPlace:
                        handler[^1].add quote do:
                            var `argTmpName`: `argType` = `default`
                            if `ctx`.getQueryParamsOption(`argName`).isSome:
                                `argTmpName` = unmarshal(`ctx`.getQueryParamsOption(`argName`).get, `argType`)
                    
                    of bodyPlace:
                        handler[^1].add quote do:
                            var `argTmpName`: `argType` = `default`
                            if `ctx`.request.contentType.split(";")[0] == "multipart/form-data":
                                if `ctx`.getFormParamsOption(`argName`).isSome:
                                    `argTmpName` = unmarshal(`ctx`.getFormParamsOption(`argName`).get, `argType`)
                            elif `body`.hasKey(`argName`):
                                `argTmpName` = `body`[`argName`].to(`argType`)
                        
                call.add quote do:
                    `argTmpName`
            
            if route.returns.kind == nnkEmpty:
                handler[^1].add quote do:
                    `call`
                    resp "", Http200
            
            else:
                handler[^1].add quote do:
                    resp marshal(`call`)
            
            result.add handler
            result.add quote do:
                `pgApp`.addRoute(`url`, `handlerName`, @[`verb`])

macro serve*(dir: static[string]) =
    return quote do:
        serverSide:

            import pigeon / middlewear
            pgApp.use(pgStaticFileMiddlewear(`dir`))
        
        clientSide:
            discard

macro run*(port: static[int] = 8080) =

    return quote do:
        serverSide:

                pgApp.gScope.settings.port = Port(`port`)
                pgApp.run()
        
        clientSide:
            discard