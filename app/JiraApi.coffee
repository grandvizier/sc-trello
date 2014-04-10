fs = require("fs")
OAuth = require("oauth").OAuth

module.exports = class JiraApi

  privateKeyData = fs.readFileSync("/home/qa/rsa.pem", "utf8")

  consumer = new OAuth(
    "https://symphony.atlassian.net/plugins/servlet/oauth/request-token", 
    "https://symphony.atlassian.net/plugins/servlet/oauth/access-token", 
    "oauth-sample-consumer", 
    "", 
    "1.0", 
    "http://localhost:8080/sessions/callback", 
    "RSA-SHA1", 
    null, 
    privateKeyData
    )



  connect: (request, response) ->
    consumer.getOAuthRequestToken (error, oauthToken, oauthTokenSecret, results) ->
      console.log '------ error ', error
      console.log '------ token', oauthToken
      if error
        console.log error.data
        response.send "Error getting OAuth access token"
      else
        request.session.oauthRequestToken = oauthToken
        request.session.oauthRequestTokenSecret = oauthTokenSecret
        console.log '------'
        console.log request.session
        response.redirect "https://jdog.atlassian.com/plugins/servlet/oauth/authorize?oauth_token=" + request.session.oauthRequestToken
      return