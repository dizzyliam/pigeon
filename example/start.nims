exec "nim js -o:static/app.js webapp.nim"
exec "nim c --threads:on server.nim"
exec "./server"