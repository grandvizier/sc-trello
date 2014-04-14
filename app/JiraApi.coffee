request = require 'request'

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