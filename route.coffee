express = require "express"
cons = require 'consolidate'
_ = require 'lodash'
md5 = require 'MD5'
server = require './app/server'


app = express()

app.configure ->
  app.use express.favicon(__dirname + "/public/favicon.ico")
  app.use express.bodyParser()
  app.set "views", __dirname + "/views"
  app.engine "hbs", cons.handlebars
  app.set "view engine", "hbs"
  app.use express.static(__dirname + "/public")
  app.locals.modify = (str) ->
    return "0" if str.length is 0
    i = 0
    len = str.length
    while i < len
      chr = str.charCodeAt(i)
      hash = ((hash << 5) - hash) + chr
      hash |= 0 # Convert to 32bit integer
      i++
    hash.toString().substr(0,3)

  app.locals.hashColor = (str) ->
    return "000" if str.length is 0
    color = md5(str)
    color.substr(0,3)

  app.locals.colorHash = (str) ->
    hash = "000"
    return hash if str.length is 0
    int = parseInt(str)
    lastDigit = parseInt(str.substr(-1))
    base = []
    if str.length is 2 then base = str.split('')
    if str.length is 3 then base = str.substr(-2).split('')
    if str.length is 4 then base = str.substr(-3,2).split('')

    if str.length is 1
      unless int % 2 then hash = str + (10 - int) + str
      else hash = (10 - int) + str + str
    else
      switch lastDigit
        when 0 then hash = "f" + base[0] + base[1]
        when 1 then hash = base[0] + "f" + base[1]
        when 2 then hash = base[0] + base[1] + "f"
        when 3 then hash = "b" + base[0] + base[1]
        when 4 then hash = base[0] + "b" + base[1]
        when 5 then hash = base[0] + base[1] + "b"
        when 6 then hash = "c" + base[0] + base[1]
        when 7 then hash = "#{lastDigit}" + base[0] + base[1]
        when 8 then hash = base[0] + "#{lastDigit}" + base[1]
        when 9 then hash = base[0] + base[1] + "#{lastDigit}"
    hash


app.get "/", (req, res) ->
  server.loadAllProjects req, res

app.get "/update-token", (req, res) ->
  res.render "token-update.jade"

app.get "/project/:projectId?", (req, res) ->
  server.loadSprintForProject req, res

app.get "/print/:type/:id", (req, res) ->
  server.showPrintView req, res



#TODO - make part of config
app.listen 3000
console.log "Listening on port 3000"

