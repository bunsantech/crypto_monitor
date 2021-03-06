defmodule CryptoMonitor.Web.CryptoController do
  use CryptoMonitor.Web, :controller
  alias Crypto.User
  alias Crypto.Currency
  alias CryptoMonitor.Bank

  action_fallback CryptoMonitor.Web.ErrorFallBackCurrencyController

  def index(conn, _params) do
    render conn, "index.html"
  end

  def charts(conn, _params) do
    btc_metrics = Crypto.Metrics.get_metrics("btc")
    render conn, "chart.html",btc_metrics: btc_metrics
  end

  def bussines(conn, _params) do
    case get_session(conn, :user) do
      nil ->
        changeset = User.changeset(%User{}, %{})
        render conn, "bussines.html", changeset: changeset
      _ ->
        conn
          |> redirect(to: "/balance")
    end
  end

  def buy_currency(conn, params) do
    user = get_session(conn, :user)
    changeset = Currency.buy_changeset(%Currency{}, params["currency"])
    if changeset.valid? do
      quantity =  params["currency"]["quantity"]
      currency =  params["name"]
      {quantity, _} = Integer.parse(quantity)
      case Bank.buy(currency, quantity, user) do
        {:ok, _} ->
          conn
            |> redirect(to: "/balance")
        {:error, message} ->
          {:error, message}
      end
    else
      changeset.errors
    end
  end

  def sell_currency(conn, params) do
    user = get_session(conn, :user)
    changeset = Currency.sell_changeset(%Currency{}, params["currency"])
    if changeset.valid? do
      quantity =  params["currency"]["quantity"]
      currency =  params["name"]
      {quantity, _} = Integer.parse(quantity)
      case Bank.sell(currency, quantity, user) do
        {:ok, _} ->
          conn
            |> redirect(to: "/balance")
        {:error, message} ->
          {:error, message}
      end
    else
      changeset.errors
    end
  end

  def balance(conn, _params) do
    user = get_session(conn, :user)
    user_info = User.get_info(user)
    changeset = Currency.changeset(%Currency{}, %{})
    render conn, "balance.html", user_info: user_info, changeset: changeset
  end

  def leader_board(conn, _params) do
    users = Crypto.User.get_top_10
    render conn, "leader_board.html", users: users
  end
end
