defmodule ApiBnK.Repo.Migrations.AccountsAddColumnAccAuthoToken do
  use Ecto.Migration

  def change do
    alter table("accounts") do
      add :acc_autho_token, :text
    end
  end
end