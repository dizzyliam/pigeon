# Package

version       = "0.3.0"
author        = "Liam Scaife"
description   = "🕊️ Define procedures on the server, call them from the browser."
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.0.0"
requires "prologue"
requires "regex"
requires "ajax"

task test, "Tests the pigeon library. Visit the served page to confirm success.":
    cd "test"
    exec "nim js -o:static/test.js frontend.nim"
    exec "nim c -r backend.nim"
