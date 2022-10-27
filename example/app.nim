import pigeon

autoRoute:
    proc getSource(filename: string): string =
        readFile "app.nim"

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
            