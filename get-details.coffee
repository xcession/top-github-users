#!/usr/bin/env coffee
cheerio = require 'cheerio'
utils = require './utils'

stats = {}

getStats = (text) ->
  userStats = JSON.parse(text)
  stats[userStats.login] = userStats
  userStats

extractStats = (html) ->
  $ = cheerio.load html
  byProp = (field) -> $("[itemprop='#{field}']")
  getInt = (text) -> parseInt text.replace ',', ''
  getOrgName = (item) -> $(item).attr('aria-label')

  pageDesc = $('meta[name="description"]').attr('content')

  userStats =
    login: byProp('additionalName').text().trim()
    language: (/\sin ([\w-+#\s\(\)]+)/.exec(pageDesc)?[1] ? '')
    gravatar: byProp('image').attr('href')
    organizations: $('#js-pjax-container > div > div > div.column.one-fourth > div.clearfix > a').toArray().map(getOrgName)
    contributions: getInt $('#js-pjax-container > div > div > div.column.three-fourths > div.js-repo-filter.position-relative > div > div.boxed-group.flush > h3').text().trim().split(' ')[0]

  if stats[userStats.login]?
    stats[userStats.login][k] = v for k, v of userStats when k isnt 'login'

  userStats

sortStats = (stats) ->
  minContributions = 1
  Object.keys(stats)
    .filter (login) ->
      stats[login].contributions >= minContributions
    .sort (a, b) ->
      stats[b].contributions - stats[a].contributions
    .map (login) ->
      stats[login]

saveStats = ->
  logins = require './temp-logins.json'
  apiEndpoints = logins.map (login) -> "https://api.github.com/users/#{login}"
  webUrls = logins.map (login) -> "https://github.com/#{login}"

  utils.batchGet apiEndpoints, getStats, (_all) ->
    utils.batchGet webUrls, extractStats, (_all) ->
      utils.writeStats './raw/github-users-stats.json', sortStats stats

saveStats()
