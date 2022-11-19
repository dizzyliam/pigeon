import "../src/pigeon"

autoRoute:

    # GET, no params.
    proc getSimple*(): string =
        return "success"
    
    # GET, params.
    proc getParams*(text: string): string =
        return text

    # GET, chained params.
    proc getChained*(text1, text2: string): string =
        return text1 & text2

    # GET, default value.
    proc getDefault*(text: string = "success"): string =
        return text

    # GET, path param.
    GET "/{text}"
    proc getPathParam*(param: string): string =
        return param

    # POST, with body.
    proc postBody*(text: string): string =
        return text

    # POST, default value.
    proc postDefault*(text: string = "success"): string =
        return text

    # Duplicate name.
    proc getParams*(text1, text2: string): string =
        return text1 & text2

serve "static"
run 8080