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
