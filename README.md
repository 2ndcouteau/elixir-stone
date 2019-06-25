# elixir_stone
###### Entry test for Stone company

This program is writing in [Elixir](https://elixir-lang.org/). It's has been made in a learning purpose, it has been made in learning and test purpose.
So some parts suffer of over-engineering.

###### Summary of the exercise:

Create a sample of bank account exchange management.
You will be able to create client accounts with different wallets.
Then, you will be able to transfer money between different wallets.
From a client wallet to another wallet, from a client wallet to another
client wallet or between a client wallet and multiple clients wallets.
Every money transfer are compliant with the norm ISO_4217.

###### What will you be able to do ?:

With this program, you can create and delete client accounts.
For each account, create new wallets with a particular currency and a defined
amount.
With these accounts, you will be able to make transfers between them.
And finally you can make conversion between two different currencies.

All currencies available are compliant with the ISO_4217.
You can use them with there conventional codes like "EUR", "978", 978.

All currency rates are updated each hour from fixer.io

Clients are identified by an ID which is a multiple of 1000. Ex: 5000, 68000, etc.
There is also a name, to help to make the distinction between clients.

---
### <u>How to install :

Please, download the repository with the following command:

```
git clone https://github.com/2ndcouteau/elixir-stone
cd elixir_stone
```

Fetch, install and update dependencies:
```
mix deps.get
```

You are now ready to use the `elixir-stone` project

### <u>How to use :

#### Import

For comfort, main functions are gather in a single module named FS.
So you can start by import FS directly and use program as showing bellow.

```
iex> import FS
```

#### Client management:

create_client(name, main_currency \\ 978 "EUR", amount_deposited \\ 0)
```
iex> create_client("Mister Jack", "BRL", 28451)
iex> create_client("Madame Bault", 952, 849451)
```

delete_client(client_id)
```
iex> delete_client("1000")
iex> delete_client("2000")
```

create_wallet(client_id, currency, amount_deposited \\ 0)
```
iex> create_wallet(1000, 124, 4242)
```

delete_wallet(client_id, currency)

The wallet can only be delete if there is no money in it.
Wallet_found == 0
```
iex> delete_wallet(1000, 124)
```



print_client_infos(client) when is_integer(client)

print_client_infos(client) when is_binary(client)
```
iex> print_client_infos("Madame Bault")
> 1000
iex> print_client_infos(1000)
---------------------
ID: 1000, Name: Madame Bault
Main Currency: EUR, 978, minor_unit = 2
EUR: 8813.00
---------------------
```

#### Transfers management

transfer(from_client_id, to_client_id, from_currency, value, direct_conversion)
```
iex> transfer(27000, 48000, "EUR", 1200, :true)
iex> transfer(51000, 92000, 124, 1158.74, :false)
```

transfer(account_id, to_account_id, value)
```
transfer(84124, 3978, 3200)
```

transfer(from_client_id, from_wallet, to_wallet, value)
```
transfer(65000, 978, 124, 321.52)
```

multi_transfer(from_client_id, to_clients_ids, from_currency, value, direct_conversion)
```
multi_transfer(35000, [3000, 84000, 124000, 72000], 978, 1200, :true)
multi_transfer(35000, [3000], "CAD", 421.03, :false)
```


multi_transfer(account_id, to_accounts_ids, value)
```
multi_transfer(84978, [142124, 6986, 3840], 943.45)
```

conversion(value, from_currency, to_currency)
```
conversion(731.5, 124, 986)
```

---
##### <u>- Run the program
You can lunch the application with the following command:
```
iex -S mix
```

##### <u>- Run the tests
You can run tests with:
```
mix test
```
or for include external tagged tests:
```
mix test --include external
```
These tests make request on the distant API with a limited usage.

##### <u>- Run Static analyzer
And also use the static analyzer `Dialyxir` with:
```
mix dialyzer
```
Some errors are ignored. You can find more details about them in the file
`.dialyzer_ignore` in the root of the project.

##### <u>- Generate documentation
Finally, you can generate the documentation with:
```
mix docs
```
That will generate a folder doc with all the documentation available from the
@doc/@docmodule attributes in the code.

##### Notes:
- The key API is available in the git repository for a convenient access as part
of this exercise.
The `secret` folder should normally be exclude in the .gitignore configuration
file.
---

##### Program Architecture:

- Supervisor
	- Client Registry
	- DynamicSupervisor
		- Client
	- Transfer Registry
	- DynamicSupervisor
		- Transfers
	- Currencies API

(The `Transfers` functions are not all Supervised yet)

##### Resources:
- Main Resources
	- [Elixir-lang](https://elixir-lang.org/getting-started/introduction.html)
	- [Elixir School](https://elixirschool.com/en/)
	- [Hex](https://hex.pm/)
	- [Hexdoxs](https://hexdocs.pm/elixir/master/Kernel.html)
	- [Elixir style guide](https://github.com/gusaiani/elixir_style_guide)
	- [Stone best practices](https://github.com/stone-payments/stoneco-best-practices)
	- [Stone Git best practice](https://github.com/stone-payments/stoneco-best-practices/blob/master/gitStyleGuide/README.md)
	- [Elixir Cheat Sheet](https://media.pragprog.com/titles/elixir/ElixirCheat.pdf)


- Specific resources
	- [Realtime data Updates](https://www.poeticoding.com/realtime-market-data-updates-with-elixir/)

---

#### Reminder

-  **feat** :
	a new feature
-  **fix** :
	a bug fix
-  **docs** :
	changes to documentation
-  **style** :
	formatting, missing semi-colons, etc.; no code change
-  **refactor** :
	refactoring production code
-  **test** :
	adding tests, refactoring test; no production code change
-  **chore** :
	updating build tasks, package manager configs, etc.; no production code change
