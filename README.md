# 👑 🕊️ pigeon

Define procedures on the server, call them from the browser.

Pigeon is a wrapper for [Prologue](https://github.com/planety/prologue) with a DSL for easily creating Remote Procedure Call (RPC) functionality for web applications. When compiling to C-like backends, procedures under the `autoRoute` macro are automatically exposed as an API. When compiling to JS, matching procedures are created that make AJAX requests to the server.

Pigeon gives you the ability to import your backend as a package into frontend code, even though they will run seperately, across different devices.

## Simple Example

This is a very simple example of a server with a couple of exposed procedures, and a Karax SPA that imports and uses them.

```nim
# server.nim

import pigeon

setup: 
    var counter = 0

autoRoute:

    proc getCount*(): int =
        return counter

    proc incCount*(amount: int) =
        counter += amount

serve "static"
run 8080
```


```nim
# webapp.nim

include karax / prelude
import server

var code: string

proc createDom(): VNode =
    buildHtml(tdiv):

        button:
            text $getCount()
            proc onclick(ev: Event; n: VNode) =
                incCount(1)

setRenderer createDom
```

`webapp.nim` is compiled to JS, then placed in the `static` directory with Karax boilerplate HTML. `server.nim` is compiled with the C backend and started. Done 😀

Run `start.nims` in the `example` directory to see this in action.

## Routing

When using pigeon on the backend and frontend, you don't have to worry at all about the specifics of HTTP methods and routes, since you're just defining and calling procedures. However, if you're intending for the API to be used by clients other than a Nim web app, pigeon lets you control the underlying routes as well.

Methods are automatically infered from procedure names if possible. For example, the `getSource` procedure used above is mapped to the `GET` method because the name starts with that keyword. Similarly, a unique path is created for every procedure.

You can specify the method and path for an autorouted procedure by annotating it. This also lets you define path parameters. For example:

```nim
GET "/user/{username}/info"
proc userInfo(username: string): User
```

All arguments not included `{in the path}` will be expected in a JSON body by default, or in query parameters in the case of the `GET`, `DELETE` and `HEAD` methods.

## Marshaling

All procdeure arguments and return values, except for string types, are marshaled as JSON, allowing the use of custom types as well as primitives.

## Prologue Routes

For non-RPC routes, such as for serving the app itself, you can directly include Prologue handlers under `autoRoute`. For example:

```nim
GET "/"
proc home(ctx: Context) {.async.} =
    ctx.staticFileResponse("index.html", "")
```