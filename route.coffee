express = require "express"
async = require 'async'
cons = require 'consolidate'
_ = require 'lodash'
TrelloApi = require './app/TrelloApi'
JiraApi = require './app/JiraApi'


app = express()

app.configure ->
  app.use express.favicon(__dirname + "/public/favicon.ico")
  app.use express.bodyParser()
  app.set "views", __dirname + "/views"
  app.engine "hbs", cons.handlebars
  app.set "view engine", "hbs"
  app.use express.static(__dirname + "/public")


app.get "/jira-auth", (req, res) ->
  jira = new JiraApi
  jira.connect req, res

app.get "/", (req, res) ->
  res.render "index"

app.get "/update-token", (req, res) ->
  trello = new TrelloApi
  trello.updateToken (url) =>
    res.redirect url

app.get "/board/:board?", (req, res) ->
  loadBoard req, res


app.get "/list/:id?", (req, res) ->
  loadList req, res

app.get "/print/:type/:id", (req, res) ->
  showPrintView req, res


#TODO - make part of config
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
    getAllMembers: (next) =>
      unless board then return next()
      trello.getAllMembersOnBoard board, next
  , (error, results) =>
    if error then return res.render "error.jade", error: error
    unless board then res.render "allBoards.jade",
      boards: results.getAllBoards
    else
      boardUsed = _.find results.getAllBoards, (brd) -> brd.id is board
      res.render "board.jade",
        board: boardUsed.name
        lists: results.getAllLists
        members: results.getAllMembers


loadList = (req, res) ->
  list_id = req.params.id
  trello = new TrelloApi
  unless list_id
    return res.render "error.jade", error: "No list id was provided"
  async.series
    getListInfo: (next) =>
      trello.getListInfo list_id, next
    getAllCards: (next) =>
      trello.getAllCardsWithChecklist list_id, next
    getAllMembers: (next) =>
      trello.getAllMembersForList list_id, next
  , (error, results) =>
    if error then res.render "error.jade", error: error
    else
      res.render "list.jade",
        list: results.getListInfo
        cards: results.getAllCards
        members: results.getAllMembers

showPrintView = (req, res) ->
  viewType = req.params.type
  viewBoard = if viewType is 'card' then "print/fullCard.jade" else "print/fullChecklist.jade"
  listId = req.params.id
  cardId = req.query.card
  trello = new TrelloApi
  unless listId
    return res.render "error.jade", error: "No list id was provided"
  if viewType is 'checklist' and not cardId
    return res.render "error.jade", error: "No card id provided for checklist"
  async.series
    getListInfo: (next) =>
      trello.getListInfo listId, next
    getAllItems: (next) =>
      if viewType is 'card'
        trello.getAllCardsWithChecklist listId, next
      else
        trello.getChecklistsForCard cardId, next
    getAllMembers: (next) =>
      trello.getAllMembersForList listId, next
  , (error, results) =>
    if error then res.render "error.jade", error: error
    else
      res.render viewBoard,
        viewType: viewType
        list: results.getListInfo
        cards: results.getAllItems
        members: results.getAllMembers