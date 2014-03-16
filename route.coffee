express = require "express"
async = require 'async'
_ = require 'lodash'
TrelloApi = require './app/TrelloApi'


app = express()

app.configure ->
  app.use express.favicon(__dirname + "/public/favicon.ico")
  app.use express.bodyParser()
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.static(__dirname + "/public")
  # app.locals.ucfirst = (value) ->
  #   value.charAt(0).toUpperCase() + value.slice(1)


app.get "/:board?", (req, res) ->
  board = req.params.board
  trello = new TrelloApi
  async.series
    getAllBoards: (next) =>
      trello.getAllBoards next
    getAllLists: (next) =>
      unless board then return next()
      trello.getAllListsWithCards board, next
  , (error, results) =>
    if error then res.render "error", error: error
    unless board then res.render "allBoards",
      boards: results.getAllBoards
    else
      boardUsed = _.find results.getAllBoards, (brd) -> brd.id is board
      res.render "board",
        board: boardUsed.name
        lists: results.getAllLists


app.get "/list/:id?", (req, res) ->


app.listen 3000
console.log "Listening on port 3000"