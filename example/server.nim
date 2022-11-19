import pigeon

setup: 
    var counter = 0

autoRoute:

    proc getCount*(): int =
        return counter

    proc incCount*(amount: int) =
        counter += amount

serve "static"
run 8080