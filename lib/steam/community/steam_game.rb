# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2011, Sebastian Staudt

require 'steam/community/game_leaderboard'
require 'steam/community/game_stats'
require 'steam/community/web_api'

# This class represents a game available on Steam
#
# @author Sebastian Staudt
class SteamGame

  @@games = {}

  # Returns the Steam application ID of this game
  #
  # @return [Fixnum] The Steam application ID of this game
  attr_reader :app_id

  # Returns the full name of this game
  #
  # @return [String] The full name of this game
  attr_reader :name

  # Returns the short name of this game (also known as "friendly name")
  #
  # @return [String] The short name of this game
  attr_reader :short_name

  # Creates a new or cached instance of the game specified by the given XML
  # data
  #
  # @param [REXML::Element] game_data The XML data of the game
  # @see #initialize
  def self.new(game_data)
    app_id = game_data.elements['appID'].text.to_i
    @@games.key?(app_id) ? @@games[app_id] : super(app_id, game_data)
  end

  # Returns whether this game has statistics available
  #
  # @return [Boolean] `true` if this game has stats
  def has_stats?
    !@short_name.nil?
  end

  # Returns the leaderboard for this game and the given leaderboard ID or name
  #
  # @param [Fixnum, String] id The ID or name of the leaderboard to return
  # @return [GameLeaderboard] The matching leaderboard if available
  def leaderboard(id)
    GameLeaderboard.leaderboard @short_name, id
  end

  # Returns an array containing all of this game's leaderboards
  #
  # @return [Array<GameLeaderboard>] The leaderboards for this game
  def leaderboards
    GameLeaderboard.leaderboards @short_name
  end

  # Returns whether the given version of this game is up-to-date
  #
  # @param [Fixnum] version The version to check against the Web API
  # @return [Boolean] `true` if the given version is up-to-date
  def uptodate?(version)
    params = { :appid => @app_id, :version => version }
    result = WebApi.json 'ISteamApps', 'UpToDateCheck', 1, params
    result = MultiJson.decode(result, { :symbolize_keys => true})[:response]
    raise SteamCondenserError, result[:error] unless result[:success]
    result[:up_to_date]
  end

  # Creates a stats object for the given user and this game
  #
  # @param [String, Fixnum] steam_id The custom URL or the 64bit Steam ID of
  #        the user
  # @return [GameStats] The stats of this game for the given user
  def user_stats(steam_id)
    return unless has_stats?

    GameStats.create_game_stats steam_id, @short_name
  end

  private

  # Creates a new instance of a game with the given data and caches it
  #
  # @param [Fixnum] app_id The application ID of the game
  # @param [REXML::Element] game_data The XML data of the game
  def initialize(app_id, game_data)
    @app_id = app_id
    @name   = game_data.elements['name'].text
    if game_data.elements['globalStatsLink'].nil?
      @short_name = nil
    else
      @short_name = game_data.elements['globalStatsLink'].text.match(/http:\/\/steamcommunity.com\/stats\/([^?\/]+)\/achievements\//)[1].downcase
    end

    @@games[@app_id] = self
  end

end
