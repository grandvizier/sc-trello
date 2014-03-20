request = require 'request'
async = require 'async'

module.exports = class TrelloApi

  key = ""
  token = ""
  # to update token:

  baseUrl = "https://api.trello.com"
  endURL = "key=#{key}&token=#{token}"


  curlRequest: (url, done) ->
    unless url then return done new Error 'no url provided'
    request url, (error, response, body) ->
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


  getAllBoards: (done) ->
    apiEndpoint = "/1/members/me/boards?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  getAllLists: (board_id, done) ->
    apiEndpoint = "/1/boards/#{board_id}/lists?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  getAllCards: (list_id, done) ->
    apiEndpoint = "/1/lists/#{list_id}/cards?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  getChecklistsForCard: (card_id, done) ->
    apiEndpoint = "/1/cards/#{card_id}/checklists?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  getAllListsWithCards: (board_id, done) ->
    @getAllLists board_id, (error, lists) =>
      if error then return done error
      async.forEach lists, ((list, callback) =>
        @getAllCards list.id, (error, cards) =>
          async.forEach cards, ((card, cb) =>
            @getChecklistsForCard card.id, (error, checklist) =>
              card.checklist = checklist
              cb()
          ), () =>
            list.cards = cards
            callback()
      ), (error) ->
        done error, lists

