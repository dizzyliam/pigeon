import prologue
import uri
import os

proc pgStaticFileMiddlewear*(dir: string): HandlerAsync =
  result = proc(ctx: Context) {.async.} =

    let file = dir / ctx.request.path.decodeUrl

    if fileExists file:
      await ctx.staticFileResponse(file, "")
    elif fileExists file / "index.html":
      await ctx.staticFileResponse(file / "index.html", "")
    else:
        await switch(ctx)