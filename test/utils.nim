include karax / prelude

proc test*(desc, call: string): VNode =
    buildHtml(tdiv):

        if call == "success":
            p(class="success"):
                text desc
        
        else:
            p(class="failure"):
                text desc