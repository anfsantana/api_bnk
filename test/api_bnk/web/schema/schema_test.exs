defmodule ApiBnK.SchemaTest do
  use ApiBnK.Support.ConnCase, async: true
  alias ApiBnK.Accounts.AccountsResolver

  describe "account" do

    @login_info %{agency: "0002", account: "456783", password: "123456789"}
    @account_info %{email: "ric@email.com", name: "João",
                    cpf: "31671727460", bank_code: "005"}
    setup do

      with {:ok, _} <- AccountsResolver.create(Map.merge(@account_info, @login_info), nil),
      {:ok, %{token: authe_token}} = AccountsResolver.login(@login_info, nil) do
        conn = Phoenix.ConnTest.build_conn()
               |> Plug.Conn.put_req_header("content-type", "application/json")
               |> Plug.Conn.put_req_header("authentication", "Bearer #{authe_token}")

        {:ok, %{conn: conn}}
      else
        {:error, msg} -> {:error, msg}
      end
    end

    test "[Query GraphQL] login: sucesso em efetuar o login/obter o token de autenticação.", %{conn: conn} do
      query = """
        query {
            login(agency: "#{@login_info.agency}", account: "#{@login_info.account}", password: "#{@login_info.password}") {
            token
          }
        }
      """

      res =
        conn
        |> post("/api/graphiql", %{query: query})
        |> json_response(200)

      %{"data" => %{"login" => %{"token" => token}}} = res
      assert String.length(token) > 0

    end

    test "[Query GraphQL] authorization: sucesso em obter o token de autorização da conta logada.", %{conn: conn} do
      query = """
        query {
            authorization(password: "#{@login_info.password}") {
            token
          }
        }
      """

      res =
        conn
        |> post("/api/graphiql", %{query: query})
        |> json_response(200)

      %{"data" => %{"authorization" => %{"token" => token}}} = res
      assert String.length(token) > 0

    end

    test "[Query GraphQL] balance: sucesso na consulta de saldo da conta da conta logada.", %{conn: conn} do
      query = """
      query {
        balance
      }
      """
      res =
        conn
        |> post("/api/graphiql", %{query: query})
        |> json_response(200)

      %{"data" => %{"balance" => value}} = res
      assert value == "1000"

    end

    test "[Mutation GraphQL] createAccount: sucesso na criação de conta. ", %{conn: conn} do
      mutation = """
          mutation {
            createAccount(
                account: "456785",
                agency: "0002",
                bankCode: "005",
                name: "João",
                password: "123456",
                cpf: "31671727467",
                email: "roselitest@email.com"
            ){
            code
            message
            }
          }
      """
      res =
        conn
        |> post("/api/graphiql", %{query: mutation})
        |> json_response(200)

      assert %{"data" => %{"createAccount" => %{"code" => 201, "message" => _}}} = res
    end

    test "[Mutation GraphQL] updateAccount: sucesso na atualização de dados da conta logada.", %{conn: conn} do
        new_email = "silvajoao@email.com"

        mutation = """
        mutation {
          updateAccount(
              name: "João",
              email: "#{new_email}"
          ){
            accEmail
          }
        }
        """
        res =
          conn
          |> post("/api/graphiql", %{query: mutation})
          |> json_response(200)

        assert %{"data" => %{"updateAccount" => %{"accEmail" => new_email}}} = res
    end

    test "[Mutation GraphQL] logout: sucesso ao efetuar logout.", %{conn: conn} do
      mutation = """
        mutation {
          logout {
            code
            message
          }
      }
      """
      res =
        conn
        |> post("/api/graphiql", %{query: mutation})
        |> json_response(200)

      %{"data" => %{"logout" => %{"code" => code, "message" => _}}} = res
      assert code == 200

    end

  end

  describe "financial_transactions" do

    @login_info %{agency: "0002", account: "456784", password: "323245"}

    @login_info_authorization %{acc_agency: "0002", acc_account: "456784", acc_password: "323245"}

    @account_origin_info %{email: "ric@email.com", name: "Ricardo", cpf: "31671727460",
      bank_code: "005"}

    @account_destination_info %{email: "jo@email.com", name: "João", cpf: "41671727460",
      agency: "0002", account: "456785", password: "123456789",
      bank_code: "005"}

    setup do

      with {:ok, _} <- AccountsResolver.create(Map.merge(@account_origin_info, @login_info), nil),
      {:ok, _} <- AccountsResolver.create(@account_destination_info, nil),
      {:ok, %{token: authe_token}} <- AccountsResolver.login(@login_info, nil),
      {:ok, %{token: autho_token}} <- AccountsResolver.authorization(@login_info, %{context: %{current_user: @login_info_authorization}}) do
        conn = Phoenix.ConnTest.build_conn()
               |> Plug.Conn.put_req_header("content-type", "application/json")
               |> Plug.Conn.put_req_header("authentication", "Bearer #{authe_token}")
               |> Plug.Conn.put_req_header("authorization", "Bearer #{autho_token}")
          {:ok, %{conn: conn}}
      else
        {:error, msg} -> {:error, msg}
      end

    end

    test "[Mutation GraphQL] transferency: sucesso na transferência de valores. ", %{conn: conn} do
      interpolation = fn(map) -> ("""
          mutation {
            transferency(account: "#{map.account}",
                         agency: "#{map.agency}",
                         bankCode: "#{map.bank_code}", value: 500.55){
              message
              code
            }
          }
      """) end

      mutation_transferency = interpolation.(@account_destination_info)

      res =
        conn
        |> post("/api/graphiql", %{query: mutation_transferency})
        |> json_response(200)

        assert %{"data" => %{"transferency" => %{"code" => 200, "message" => _}}} = res
    end

  end
#
#  describe "createUser" do
#    test "it creates a User with proper params", %{conn: conn} do
#      query = """
#      {
#        createUser(username: "duder", email: "dude@dude.dude" password: "dudedude", passwordConfirmation: "dudedude") {
#          id
#        }
#      }
#      """
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert %{"data" => %{"createUser" => %{"id" => _}}} = res
#    end
#
#    test "it provides an error if validations fail", %{conn: conn} do
#      query = """
#      {
#        createUser(username: "dude", email: "bad", password: "dudedude", passwordConfirmation: "dudedude") {
#          id
#        }
#      }
#      """
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert %{"errors" => [%{"message" => message}]} = res
#      assert message == "Failed: email has invalid format"
#    end
#  end
#
#  describe "user" do
#    setup do
#      [user: insert(:user, %{username: "dude"})]
#    end
#
#    test "gets a User by username", %{conn: conn, user: %{username: username}} do
#      query = """
#      {
#        user(username: "#{username}") {
#          username
#        }
#      }
#      """
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert res == %{"data" => %{"user" => %{"username" => username}}}
#    end
#
#    test "returns nil if the User is not found", %{conn: conn, user: user} do
#      query = """
#      {
#        user(username: "not#{user.username}") {
#          username
#        }
#      }
#      """
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert res == %{"data" => %{"user" => nil}}
#    end
#  end
#
#  describe "games" do
#    setup do
#      1..5 |> Enum.map(fn _ -> insert(:player) end)
#
#      :ok
#    end
#
#    test "gets a list of Games", %{conn: conn} do
#      query = """
#      { games { id } }
#      """
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      %{"data" => %{"games" => games}} = res
#      assert length(games) == 5
#    end
#  end
#
#  describe "game" do
#    setup do
#      [game: insert(:game)]
#    end
#
#    test "gets a game by id", %{conn: conn, game: %{id: id}} do
#      query = """
#      {
#        game(id: #{id}) {
#          id
#        }
#      }
#      """
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert res == %{"data" => %{"game" => %{"id" => "#{id}"}}}
#    end
#
#    test "returns nil if the Game is not found", %{conn: conn, game: %{id: id}} do
#      query = """
#      {
#        game(id: #{id}1) {
#          id
#        }
#      }
#      """
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert res == %{"data" => %{"game" => nil}}
#    end
#  end
#
#  describe "createPlayer" do
#    setup do
#      user = insert(:user)
#      game = insert(:game)
#
#      [user: user, game: game]
#    end
#
#    test "creates a Player with valid params", %{conn: conn, user: %{id: user_id}, game: %{id: game_id}} do
#      query = """
#      {
#        createPlayer(userId: #{user_id}, gameId: #{game_id}, status: "user-pending") {
#          id
#        }
#      }
#      """
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert %{"data" => %{"createPlayer" => %{"id" => _}}} = res
#    end
#
#    test "returns errors with invalid params", %{conn: conn, user: %{id: user_id}, game: %{id: game_id}} do
#      query = """
#      {
#        createPlayer(userId: #{user_id}1, gameId: #{game_id}, status: "user-pending") {
#          id
#        }
#      }
#      """
#
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert %{"errors" => [%{"message" => message}]} = res
#      assert message == "Failed: user does not exist"
#    end
#  end
#
#  describe "player" do
#    setup do
#      [player: insert(:player)]
#    end
#
#    test "gets a Player by id", %{conn: conn, player: %{id: id}} do
#      query = """
#      {
#        player(id: #{id}) {
#          id
#        }
#      }
#      """
#
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert res == %{"data" => %{"player" => %{"id" => "#{id}"}}}
#    end
#
#    test "returns nil if the Player is not found", %{conn: conn, player: %{id: id}} do
#      query = """
#      {
#        player(id: #{id}1) {
#          id
#        }
#      }
#      """
#      res =
#        conn
#        |> post("/api", %{query: query})
#        |> json_response(200)
#
#      assert res == %{"data" => %{"player" => nil}}
#    end
#  end
end