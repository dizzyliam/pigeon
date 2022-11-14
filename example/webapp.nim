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