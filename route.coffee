express = require "express"
async = require 'async'
cons = require 'consolidate'
_ = require 'lodash'
TrelloApi = require './app/TrelloApi'


app = express()

app.configure ->
  app.use express.favicon(__dirname + "/public/favicon.ico")
  app.use express.bodyParser()
  app.set "views", __dirname + "/views"
  app.engine "hbs", cons.handlebars
  app.set "view engine", "hbs"
  app.use express.static(__dirname + "/public")
  # app.locals.ucfirst = (value) ->
  #   value.charAt(0).toUpperCase() + value.slice(1)


app.get "/", (req, res) ->
  loadBoard req, res

app.get "/board/:board?", (req, res) ->
  loadBoard req, res


app.get "/list/:id?", (req, res) ->


app.get "/hbs", (req, res) ->
  res.render "index",
    title: "Trying Handlebars"


app.listen 3000
console.log "Listening on port 3000"



loadBoard = (req, res) ->
  board = req.params.board
  trello = new TrelloApi
  async.series
    getAllBoards: (next) =>
      trello.getAllBoards next
    getAllLists: (next) =>
      unless board then return next()
      trello.getAllListsWithCards board, next
  , (error, results) =>
    if error then res.render "error.jade", error: error
    unless board then res.render "allBoards.jade",
      boards: results.getAllBoards
    else
      boardUsed = _.find results.getAllBoards, (brd) -> brd.id is board
      res.render "board.jade",
        board: boardUsed.name
        lists: results.getAllLists
