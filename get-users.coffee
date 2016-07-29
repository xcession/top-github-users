#!/usr/bin/env coffee
fs = require 'fs'
utils = require './utils'

BANNED = [
  'samber'    # Automatic updates to Github?
  'soyjavi'   # Not in Thailand?
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
  MIN_FOLLOWERS = 5
  MAX_PAGES = 10

  criteria = ["followers:>#{MIN_FOLLOWERS}"]
  criteria.push "location:\"#{loc}\"" for loc in LOCATIONS

  getParams = (page) ->
    q: criteria.join(' ')
    sort: 'followers'
    order: 'desc'
    per_page: 100
    page: page

  urls = utils.range(1, MAX_PAGES + 1).map (page) ->
    params = []
    params.push "#{k}=#{v}" for k, v of getParams(page)
    encodeURI "https://api.github.com/search/users?#{params.join('&')}"

  parse = (text) ->
    JSON.parse(text).items.map (_) -> _.login

  utils.batchGet urls, parse, (all) ->
    logins = [].concat.apply [], all
    filtered = logins.filter (name) ->
      name not in BANNED
    utils.writeStats './temp-logins.json', filtered

saveTopLogins()
