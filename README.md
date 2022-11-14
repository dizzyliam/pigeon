# 👑 🕊️ pigeon

Define procedures on the server, call them from the browser.

Pigeon replaces HTTP boilerplate with nothing but Nim procedures. When compiling to C (and friends), selected procedures are automatically exposed as an API via Jester. When compiling to JS, matching procedures are created that make requests to the API.

Pigeon gives you the ability to import your backend as a package into frontend code, even though they will run seperately, across different devices.

## Usage

### Simple Example

This is a very simple example of a server with one exposed procedure:

```nim
# server.nim

import pigeon

autoRoute:
    proc getSource*(filename: string): string =
        readFile filename

serve(8080)
```

Here's a simple Karax SPA that simply imports and uses the exposed proc:

```nim
# webapp.nim

include karax / prelude
import server

var code: string

proc createDom(): VNode =
    buildHtml(tdiv):

        button:
            text "CLICK ME"
            proc onclick(ev: Event; n: VNode) =
                code = getSource("webapp.nim")

        pre text code

setRenderer createDom
```

 `webapp.nim` is compiled to JS, then placed in the `public` directory with Karax boilerplate HTML. `server.nim` is compiled with the C backend and started. Done 😀

 Check out the `example` directory to see this example in more detail.

### Smart Routes

Although Pigeon aims to treat server/webapp communication like simple procedure calls, where specifics about resources and HTTP methods are unimportant, it's important to think about these things for interoperability and hackability.

Route methods are automatically infered from procedure names if possible. For example, the `getSource` procedure used above is mapped to the `GET` method because the name starts with that keyword. Methods can also be manually specified using the `{.get.}` and `{.post.}` pragmas.

Pigeon tries to map multiple procedures to the same resource if applicable. For example, if you define a `getThing` and `postThing` procedure, it will map these to the `GET` and `POST` methods on the single `/thing` resource.

If a method isn't specified and can't be infered, Pigeon will default to `POST`, as a mystery procedure must be assumed to have side-effects.

### Why just `GET` and `POST`?

These two HTTP methods simply read and modify resources, whichs maps well to the concept of calling a procedure. Implimenting methods such as `PUT` and `DELETE` would imply the creation and deletion of procedures at runtime, which is impossible. In future they could be implimented with custom annotations that define how parts of a URL are mapped to procedure arguments, similar to the OpenAPI specification.