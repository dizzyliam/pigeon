# 👑 🕊️ pigeon

Define procedures on the server, call them from the browser.

Pigeon replaces HTTP boilerplate with nothing but Nim procedures. When compiling to C (and friends), procedures defined within the `autoRoute` macro are automatically exposed as an API via Jester. When compiling to JS, matching procedures are created that make requests to the API. All arguments and return values are marshalled into JSON for the journey.

The result is a dissolution of the barriers between frontend and backend, letting you write them as one unified piece of software.

## Usage

### Simple Example

This is a very simple example using Pigeon in conjunction with Karax:

```nim
import pigeon

autoRoute:
    proc getSource(filename: string): string =
        # This runs on the server side.
        readFile filename

clientSide:
    include karax / prelude
    var code: string

    proc createDom(): VNode =
        buildHtml(tdiv):

            button:
                text "CLICK ME"
                proc onclick(ev: Event; n: VNode) =
                    code = getSource("app.nim")

            pre text code
    
    setRenderer createDom
```

Simply compile to C to create the server, then compile to JS to create the webapp (see `example/start.nims`). 

It's worth noting that the `clientSide` macro is only used in this example so that it can be condensed into one file. In any real-world application, server and webapp functionality would be implimented in seperate files, e.g.:

`server.nim` Would be compile to C:
```nim
import pigeon

serverSide:
    # Some code to only be run on the server,
    # like imports or opening DB connections.

autoRoute:
    proc getSource*(filename: string): string =
        ...
```

`webapp.nim` Would be compiled to JS:
```nim
include karax / prelude
import server

# Use getSource in some way.
```

This is the power of Pigeon; it lets you import your backend like a library into frontend code, even though they will run seperately, across different devices.

### Smart Routes

Although Pigeon aims to treat server/webapp communication like simple procedure calls, where specifics about resources and HTTP methods are unimportant, it's important to think about these things for interoperability and hackability.

Route methods are automatically infered from procedure names if possible. For example, the `getSource` procedure used above is mapped to the `GET` method because the name starts with that keyword. Methods can also be manually specified using the `{.get.}` and `{.post.}` pragmas.

Pigeon tries to map multiple procedures to the same resource if applicable. For example, if you define a `getThing` and `postThing` procedure, it will map these to the `GET` and `POST` methods on the single `/thing` resource.

If a method isn't specified and can't be infered, Pigeon will default to `POST`, as a mystery procedure must be assumed to have side-effects.

### Why just `GET` and `POST`?

These two HTTP methods simply read and modify resources, whichs maps well to the concept of calling a procedure. Implimenting methods such as `PUT` and `DELETE` would imply the creation and deletion of procedures at runtime, which is impossible. In future they could be implimented with custom annotations that define how parts of a URL are mapped to procedure arguments, similar to the OpenAPI specification.