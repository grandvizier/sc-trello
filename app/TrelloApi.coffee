request = require 'request'
async = require 'async'
_ = require 'lodash'

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


  updateToken: (done) ->
    apiEndpoint = "https://trello.com/1/authorize?key=#{key}" +
      "&name=SymphonyBoard&expiration=never&response_type=token"
    done apiEndpoint

  # ---  MEMBERS  ---

  getMemberInfo: (member_id, done) ->
    apiEndpoint = "/1/members/#{member_id}?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  getAllMembersOnBoard: (board_id, done) ->
    base = "/1/boards/#{board_id}/members"
    apiEndpoint =  base + "?fields=fullName,username,avatarHash&" + endURL
    @curlRequest baseUrl + apiEndpoint, (error, members) =>
      if error then return done error
      collapsedMembers = {}
      _.forEach(members, (member) ->
        collapsedMembers[member.id] = _.omit(member, "id")
        if member.avatarHash
          avatarLink = "https://trello-avatars.s3.amazonaws.com/#{member.avatarHash}/30.png"
        else avatarLink = null
        collapsedMembers[member.id].avatar = avatarLink
      )
      done null, collapsedMembers

  getAllMembersForList: (list_id, done) ->
    @getListInfo list_id, (error, list) =>
      if error then return done error
      @getAllMembersOnBoard list.idBoard, done



  # ---  BOARDS  ---

  getAllBoards: (done) ->
    apiEndpoint = "/1/members/me/boards?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  # ---  LISTS  ---

  getAllLists: (board_id, done) ->
    apiEndpoint = "/1/boards/#{board_id}/lists?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  getListInfo: (list_id, done) ->
    apiEndpoint = "/1/lists/#{list_id}?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  # ---  CARDS  ---

  getAllCards: (list_id, done) ->
    apiEndpoint = "/1/lists/#{list_id}/cards?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  getChecklistsForCard: (card_id, done) ->
    apiEndpoint = "/1/cards/#{card_id}/checklists?" + endURL
    @curlRequest baseUrl + apiEndpoint, done

  # ---  COMBINED  ---

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


  getAllCardsWithChecklist: (list_id, done) ->
    @getAllCards list_id, (error, cards) =>
      if error then return done error
      async.forEach cards, ((card, callback) =>
        @getChecklistsForCard card.id, (error, checklist) =>
          card.checklist = checklist
          callback()
      ), (error) ->
        done error, cards
