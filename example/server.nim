import pigeon

autoRoute:
    proc getSource*(filename: string): string =
        readFile filename

serve(8080)