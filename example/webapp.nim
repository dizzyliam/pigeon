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