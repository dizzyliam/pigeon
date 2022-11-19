include karax / prelude
import backend
import utils

proc createDom(): VNode =
    buildHtml(tdiv):

        test "GET, no params.", getSimple()
        test "GET, params.", getParams("success")
        test "GET, chained params.", getChained("succ", "ess")
        test "GET, default value.", getDefault()
        test "GET, path param.", getPathParam("success")
        test "POST, with body.", postBody("success")
        test "POST, default value.", postDefault()
        test "Duplicate name.", getParams("succ", "ess")

setRenderer createDom