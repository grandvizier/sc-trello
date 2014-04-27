express = require "express"
cons = require 'consolidate'
_ = require 'lodash'
server = require './app/server'
TrelloApi = require './app/TrelloApi'



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
      if _.indexOf([0,7], lastDigit) > -1
        hash = "f" + base[0] + base[1]
      if _.indexOf([1,8], lastDigit) > -1
        hash = base[0] + "f" + base[1]
      if _.indexOf([2,9], lastDigit) > -1
        hash = base[0] + base[1] + "f"
      if _.indexOf([3,6], lastDigit) > -1
        hash = "#{lastDigit}" + base[0] + base[1]
      if lastDigit is 4
        hash = base[0] + "4" + base[1]
      if lastDigit is 5
        hash = base[0] + base[1] + "5"
    hash


app.get "/jira-home", (req, res) ->
  server.loadJiraProjects req, res


app.get "/", (req, res) ->
  res.render "index"

app.get "/update-token", (req, res) ->
  trello = new TrelloApi
  trello.updateToken (url) =>
    res.redirect url

app.get "/board/:board?", (req, res) ->
  server.loadBoard req, res


app.get "/list/:id?", (req, res) ->
  server.loadList req, res

app.get "/print/:type/:id", (req, res) ->
  server.showPrintView req, res


#TODO - make part of config
app.listen 3000
console.log "Listening on port 3000"

