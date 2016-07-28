#!/usr/bin/env coffee
fs = require 'fs'
utils = require './utils'

BANNED = [
  'gugod'         # 7K commits in 4 days.
  'sindresorhus'  # Asked to remove himself from the list.
  'funkenstein'   # Appears in the list even though he has 30 followers (bug).
  'beberlei'      # 1.7K contribs every day
  'IonicaBizau'   # Contribution graffiti.
  'scottgonzalez' # Graffiti.
  'AutumnsWind'   # Graffiti.
  'hintjens'      # Graffiti.
]

LOCATIONS = [
  'thailand'
  ', TH'
  'bangkok'
  'bkk'
  'chiang mai'
  'koh samui'
  'pattaya'
  'phuket'
]

saveTopLogins = ->
  MIN_FOLLOWERS = 10
  MAX_PAGES = 10

  q = ["followers:>#{MIN_FOLLOWERS}"]
  q = q.concat "location:\"#{loc}\"" for loc in LOCATIONS
  q = q.join(' ')

  getParams = (page) ->
    q: q
    sort: 'followers'
    order: 'desc'
    per_page: 100
    page: page

  urls = utils.range(1, MAX_PAGES + 1).map (page) ->
    params = getParams(page)
    components = []
    components.push "#{k}=#{v}" for k, v of params
    encodeURI "https://api.github.com/search/users?#{components.join('&')}"

  parse = (text) ->
    JSON.parse(text).items.map (_) -> _.login

  utils.batchGet urls, parse, (all) ->
    logins = [].concat.apply [], all
    filtered = logins.filter (name) ->
      name not in BANNED
    utils.writeStats './temp-logins.json', filtered

saveTopLogins()
