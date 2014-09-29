request = require 'request'
_ = require 'lodash'

module.exports = class JiraApi

  # check oauth documentation here
  # https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+Example+-+OAuth+authentication
  basicAuth = ""
  baseUrl = "https://symphony.atlassian.net/"

  curlRequest: (url, done) ->
    #TODO: cache these calls somewhere? redis?
    unless url then return done new Error 'no url provided'
    options =
      url: url
      headers:
        "Authorization": "Basic #{basicAuth}"
    request options, (error, response, body) ->
      if error then return done error
      if response?.statusCode is 200
        try
          result = JSON.parse(body)
          done null, result
        catch ex
          done ex
      else
        console.log response.statusCode + '  returned: ', body
        done response


  getAllProjects: (done) ->
    @curlRequest baseUrl + "rest/greenhopper/1.0/rapidview", done

  getAgileBoardData: (rapidViewId, done) ->
    @curlRequest baseUrl + "rest/greenhopper/1.0/xboard/work/allData/?rapidViewId=#{rapidViewId}", done

  getStoriesFromBoard: (rapidViewId, done) ->
    @curlRequest baseUrl + "rest/greenhopper/1.0/xboard/work/allData/?rapidViewId=#{rapidViewId}", (error, data) =>
      if error then return done error
      stories = []
      _.forEach data.issuesData.issues, (issue) =>
        #10001 = Story; 2 = New Feature; 4 = Improvement
        if issue.typeId in ['10001', '2', '4']
          stories.push issue
      # get actual issues from list (for the descriptions and story points)
      storyIds = _.flatten(stories, 'id').join(',')
      @curlRequest baseUrl + "rest/api/2/search?jql=id+in+(#{storyIds})", (error, data) =>
        if error then return done error
        done null, data.issues.reverse()

  getSubtasksFromParent: (parentKey, done) ->
    @curlRequest baseUrl + "rest/api/2/search?jql=parent=#{parentKey}", (error, data) =>
      if error then return done error
      done null, data.issues

  getBugsFromBoard: (rapidViewId, onlyOpenBugs, done) ->
    @curlRequest baseUrl + "rest/greenhopper/1.0/xboard/work/allData/?rapidViewId=#{rapidViewId}", (error, data) =>
      if error then return done error
      bugs = []
      _.forEach data.issuesData.issues, (issue) =>
        #1 = Bug; 10200 = Fire
        if issue.typeId in ['1', '10200']
          if onlyOpenBugs and issue.statusName is 'Open'
            bugs.push issue
          else if not onlyOpenBugs
            bugs.push issue
      done null, bugs
