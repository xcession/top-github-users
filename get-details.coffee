#!/usr/bin/env coffee
cheerio = require 'cheerio'
utils = require './utils'

stats = {}

getStats = (html, url) ->
  $ = cheerio.load html
  byProp = (field) -> $("[itemprop='#{field}']")
  getInt = (text) -> parseInt text.replace ',', ''
  getOrgName = (item) -> $(item).attr('aria-label')
  getFollowers = ->
    text = $('.vcard-stats > a:nth-child(1) > .vcard-stat-count').text().trim()
    multiplier = if text.indexOf('k') > 0 then 1000 else 1
    (parseFloat text) * multiplier

  pageDesc = $('meta[name="description"]').attr('content')

  userStats =
    name: byProp('name').text().trim()
    login: byProp('additionalName').text().trim()
    location: byProp('homeLocation').text().trim()
    language: (/\sin ([\w-+#\s\(\)]+)/.exec(pageDesc)?[1] ? '')
    gravatar: byProp('image').attr('href')
    followers: getFollowers()
    organizations: $('#js-pjax-container > div > div > div.column.one-fourth.vcard > div.clearfix > a').toArray().map(getOrgName)
    contributions: getInt $('#js-pjax-container > div > div > div.column.three-fourths > div.js-repo-filter.position-relative > div > div.boxed-group.flush > h3').text().trim().split(' ')[0]

  stats[userStats.login] = userStats
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
  token  = require './access-token.json'

  endpoints = logins.map (login) -> "https://api.github.com/users/#{login}?access_token=#{token.key}"

  parse = (text) ->
    json = JSON.parse(text)

    apiStat =
      login: json.login
      hireable: if json.hireable then "Yes" else "No"
      public_repos: json.public_repos

    apiStat

  apiStats = null
  utils.batchGet endpoints, parse, (all) ->
    apiStats = all

  urls = logins.map (login) -> "https://github.com/#{login}"
  utils.batchGet urls, getStats, ->
    hash = {}
    for stat in apiStats
      hash[stat.login] = stat

    mergeStats = (stats) ->
      for login, stat of stats
        apiStat = hash[login]
        apiStat[k] = v for k, v of stat

      sortStats hash

    utils.writeStats './raw/github-users-stats.json', mergeStats stats

saveStats()
