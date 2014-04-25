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

app.get "/workflow/:board/:id?", (req, res) ->
  server.loadWorkflow req, res

app.get "/print/:type/:id", (req, res) ->
  server.showPrintView req, res


#TODO - make part of config
app.listen 3000
console.log "Listening on port 3000"

