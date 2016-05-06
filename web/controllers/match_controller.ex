defmodule Loltrainer.MatchController do
  use Loltrainer.Web, :controller

  def index(conn, _params) do
    # Call RIOT api and get matches
    base_url = 'https://euw.api.pvp.net/api/lol/euw'
    riot_api_key = ""

    # 1. Get summoner id
    summoner_name = "microyoshi"
    url = "#{base_url}/v1.4/summoner/by-name/#{summoner_name}?api_key=#{riot_api_key}"

    case riot_api_request(url) do
      {:ok, json} ->
        summoner_id = json[summoner_name]["id"]

        # 2. Get matches
        rankedQueues = 'RANKED_SOLO_5x5'
        seasons = 'SEASON2016'
        url = "#{base_url}/v2.2/matchlist/by-summoner/#{summoner_id}?rankedQueues=#{rankedQueues}&seasons=#{seasons}&api_key=#{riot_api_key}"

        case riot_api_request(url) do
          {:ok, json} ->
            matches =
              json
                |> Map.fetch!("matches")
                |> Enum.map(fn(match) -> match["matchId"] end)
                |> Enum.map(fn(match_id) -> 
                  # 3. Get match info
                  url = "#{base_url}/v2.2/match/#{match_id}?api_key=#{riot_api_key}"

                  case riot_api_request(url) do
                    {:ok, json} ->
                      json
                  end
                end)
                |> Enum.map(fn(match) -> extract_player_data(summoner_name, match) end)
            json conn, matches
        end
    end
  end

  defp riot_api_request(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Poison.decode!(body)}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  defp extract_player_data(summoner_name, match) do
    # 1. Fetch participant identity from match["participantIdentities"]
    participant_id = 
      match["participantIdentities"]
      |> Enum.find(fn(participant_identity) -> 
        participant_identity["player"]["summonerName"] === summoner_name
      end)
      |> Map.fetch!("participantId")
    # 2. Fetch participant data based on participantId from match["participants"]
  end
end
