exec "nim js -o:public/app.js webapp.nim"
exec "nim c server.nim"
exec "./server"