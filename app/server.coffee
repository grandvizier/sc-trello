JiraApi = require './JiraApi'
_ = require 'lodash'
async = require 'async'


module.exports.loadAllProjects = (req, res) ->
  jira = new JiraApi
  jira.getAllProjects (error, results) =>
    if error then return res.render "error.jade", error: error
    projects = _.sortBy results.views, "name"
    renderAllProjects res, projects

module.exports.loadSprintForProject = (req, res) ->
  jira = new JiraApi
  projectId = req.params.projectId
  unless projectId
    return res.render "error.jade", error: "Project ID is not valid"
  jira.getAgileBoardData projectId, (error, results) =>
    if error then return res.render "error.jade", error: error
    renderSprint res, results, projectId


module.exports.showPrintView = (req, res) ->
  viewType = req.params.type
  ucFirst = viewType.charAt(0).toUpperCase() + viewType.slice(1);
  viewBoard = "print/full#{ucFirst}.jade"
  projectId = req.params.id
  cardId = req.query.card
  unless projectId
    return res.render "error.jade", error: "No Project id was provided"
  if viewType is 'stories'
    return loadStories res, viewBoard, projectId
  if viewType is 'tasks'
    return loadTasks res, viewBoard, projectId
  if viewType is 'bugs'
    return loadBugs res, viewBoard, projectId



loadStories = (res, viewBoard, projectId) ->
  jira = new JiraApi
  jira.getStoriesFromProject projectId, (error, results) =>
    if error then return res.render "error.jade", error: error
    res.render viewBoard,
      stories: results

loadTasks = (res, viewBoard, parentKey) ->
  jira = new JiraApi
  jira.getSubtasksFromParent parentKey, (error, results) =>
    if error then return res.render "error.jade", error: error
    res.render viewBoard,
      subtasks: results
      parentKey: parentKey

loadBugs = (res, viewBoard, board) ->
  jira = new JiraApi
  jira.getBugsFromBoard board, false, (error, results) =>
    if error then return res.render "error.jade", error: error
    res.render viewBoard,
      bugs: results




renderAllProjects = (res, projects) ->
  res.render "index.jade",
      projects: projects

renderSprint = (res, data, projectId) ->
  lists = []
  _.forEach data.columnsData.columns, (col) ->
    matchingIssues = _.where(data.issuesData.issues, { 'statusId': col.statusIds.toString().split(',')[0] } )
    lists.push
      id: col.id
      name: col.name
      issues: matchingIssues

  res.render "sprint.jade",
    projectId: projectId
    sprintName: _.find(data.sprintsData.sprints, { state: "ACTIVE" }).name
    lists: lists

