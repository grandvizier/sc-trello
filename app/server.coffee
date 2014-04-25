TrelloApi = require './TrelloApi'
JiraApi = require './JiraApi'
_ = require 'lodash'
async = require 'async'


module.exports.loadJiraProjects = (req, res) ->
  jira = new JiraApi
  jira.getAllProjects (error, results) =>
    if error then return res.render "error.jade", error: error
    renderAllProjects res, results.views

loadJiraProject = (res, board) ->
  jira = new JiraApi
  jira.getAgileBoardData board, (error, results) =>
    if error then return res.render "error.jade", error: error
    renderSprint res, results, board

module.exports.loadBoard = (req, res) ->
  board = req.params.board
  if board and board.length is 2 then return loadJiraProject res, board
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
    unless board then renderAllProjects res, results.getAllBoards
    else
      boardUsed = _.find results.getAllBoards, (brd) -> brd.id is board
      res.render "board.jade",
        board: boardUsed.name
        lists: results.getAllLists
        members: results.getAllMembers


module.exports.loadWorkflow = (req, res) ->
  list_id = req.params.id
  board = req.params.board
  jira = new JiraApi
  unless list_id
    return res.render "error.jade", error: "No list id was provided"
  jira.getAgileBoardData board, (error, results) =>
    if error then return res.render "error.jade", error: error
    renderList res, list_id, results


module.exports.loadList = (req, res) ->
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

module.exports.showPrintView = (req, res) ->
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




renderAllProjects = (res, projects) ->
  res.render "allBoards.jade",
      boards: projects

renderSprint = (res, data, boardId) ->
  lists = []
  _.forEach data.columnsData.columns, (col) ->
    matchingIssues = _.where(data.issuesData.issues, { 'statusId': col.statusIds.toString().split(',')[0] } )
    lists.push
      id: col.id
      name: col.name
      issues: matchingIssues

  res.render "sprint.jade",
    boardId: boardId
    sprintName: _.find(data.sprintsData.sprints, { state: "ACTIVE" }).name
    lists: lists


renderList = (res, listId, data) ->
  matchingIssues = []
  statuses = {}
  _.forEach data.columnsData.columns, (col) =>
    _.forEach col.statusIds, (statusId) =>
      statuses[statusId] = col.id

  console.log statuses
  # allStatusIds = _.flatten(_.pluck(data.columnsData.columns, 'statusIds'))
  # console.log allStatusIds
  # _.forEach _.pluck(data.columnsData.columns, 'statusIds'), (statusId) ->
  #   console.log statusId
  # statuses = _.first(data.columnsData.columns, { 'id': 36 } )[0].statusIds
  # _.forEach statuses, (statusId) =>
  #   matchingIssues.push _.where(data.issuesData.issues, { 'statusId': "1" } )
  # console.log _.union(_.union(matchingIssues))
  res.render "error.jade", error: _.union(matchingIssues).length

