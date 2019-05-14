# <u>__TODO__</u>

### Feat:

##### In progress / cooking task


#### Test Stone Challenge Financial-System
- [] Create the whole architecture
	- [x] Create a supervisor
	- [x] Create a registry
	- [x] Create a DynamicSupervisor for Clients
	- [x] Create first rules for Clients
	- [x] Find a way to fetch conversion values

- Architecture: ~~
	- Supervisor
		- Client Registry
		- DynamicSupervisor
			- Client
		- Transfer Registry
		- DynamicSupervisor
			- Transfers
			- Currencies API


- client.ex
	- put_new_wallet(client_pid, currency, amount_deposited)
	If a wallet already exist, need to decide if:
		- Nothing happened, and an error: :already_exist if return
			- Actual solution
		- The wallet if update and the amount_deposited is added to the previous
			- Possible new solution
---

### <u>Tests:

- [] Re-write FS and FS.Clients Test

---

### <u>Chore:


---

### <u>Function:
- [x] Create_client(name, main_currency \\ "BRL")
	- Presently named `cc`
- [x] Delete_client(client_id)
- [x] Create a wallet by default with an `amount_deposited`
	- Update nested Map in Struct
	- Init Currency with the `main_currency`
- [x] Create_wallet(client_id, currency, deposit \\ 0)
- [x] Delete wallet, only if empty -> value == 0

- [] Transfert()
	- transfert(client_id, to_client_id, value, currency, direct_conversion \\ :true)
	- transfert(account_id, to_account_id , value)
		- account_id == client_id + currency_code
	- transfert(client_id, wallet, to_wallet, value)
		- wallet/to_wallet :: currency_code :: integer in list_currency ISO_4217

- [] Multi_transfert
	- [] multi_transfert(client, [to_clients], value, currency, direct_conversion \\ :true)
	- [] multi_transfert(account_id, [to_account_id], value)
		- account_id == client_id + currency_code
	- [] multi_transfert([client_id], wallet, to_wallet, value)
		- wallet/to_wallet :: currency_code :: integer in list_currency ISO_4217


### <u>Structure:

- #### New Client creation:
	- Prototype:
		- Parameters: ("name", ID, "Currency_CODE", %{Wallets map})
		- .
	- When you create a `new client`, you have to create a `unique HASH` from
	the `global map{}` of client.
		- Basic
			- A number from 1000 to N
		- Improved
			- This `HASH` will be as the ID in the Client structure.
			Like that you will be able to certified the unicity of the client and
			to provide a simple way to identify the client.

- #### Nested data structure:
	- ##### <u>ClientsDB
		- %{ID: %Client{}}
			- Each ID have to be `unique`

	- ##### <u>Client
	Definition of the structure of one `Client`
		- Struct %Name{}

			- Require:
				- Client Name
					- String
				- Client ID
					- Unique Hash ::integer
						- from 1000 to N
						- The "000" part is for identified the wallet currency code
				- Main_currency
					- String reference from ISO_4217
						- Ex: {"BRL", 986}
						- The code has to be feel by the program
				- Wallets
					- Map %{}
					- At least one key:value init
					(value can be positive or negative)
						- Ex: {"BRL": 1000} or {986: 1000}

			- Optionals:
				- Date of the Wallet Creation
				- Date of the last activity
				- Financial exchanges historics
					- from/to
						- require
					- %{Client ID}
						- require
					- Currency of the payment
						- require
					- Currency of reception (Was it a direct conversion ?)
						- optional
					- Value
						- require
					- Rate
						- optional

				- Client ID
					- Unique Crypted/Hashed ID seed by:
						- the Client Name
						- the Date of the wallet creation

					This could provide a security in front of account
					manipulation because we could be able to retrieve creation
					informations from this `ID` or to proof the incoherence of
					the datas

---
---
# <u>__DONE__</u>

### <u>Feat:

#### Test Stone Challenge Financial-System
- Init the project
- [x] Clients
	- [x] Create process for each new client
	- [x] Save him in the Registry state
	- [x] Feel informations in the client state
		- [x] name
		- [x] id
		- [x] main_currency
		- [x] default_wallet
	- [x] ID usage identification
	- [x] Can fetch informations of client from his ID
	- [x] Can fetch informations of clients from names
		- [x] Find a way to return multiple value from List in get_id_name(name, id_name)

- [x] Add spec to all functions -- Have to continue until the end
- [x] Add [decimal_arithmetic](https://hex.pm/packages/decimal_arithmetic)
	- Get [decimal](https://hex.pm/packages/decimal)

- [x] Fetch currency conversion value
	- First and simple way:
		- [x] Hard encoded conversion value
			- use Poison for JSON
				- {:poison, "~> 4.0.1"},
		[x] Use a rescue system if API is not available.
			- [x] Get information from backup json file
			- [x] Update the backup file when new API are available
				- check timestamp
	- or:
		- [x] Extern API usage
			- https://fixer.io/ (free -- EUR)
				- [x] API_key use
				- [x] Save the api_key in a `secret` folder
				- [x] Make request on API
				- [x] Get information a save it in the Transfert GenServer State
				- [x] Save update informations in a backup file, cf `First way`
			<!-- - https://currencylayer.com/ (free -- USD)
			- https://openexchangerates.org/ (paid) -->
		- Good ressources :
			- Simple request:
				- https://github.com/edgurgel/httpoison
				- https://stackoverflow.com/questions/46633620/make-http-request-with-elixir-and-phoenix

			- Subscribe/Sockets
				- No need, the Fixer.API do not provide a pure realtime update
				system.
				- https://www.poeticoding.com/realtime-market-data-updates-with-elixir/
				<!-- - {:websockex, "~> 0.4.2"}, -->
				- {:poison, "~> 4.0.1"},

- [x] Manage Decimal type correctly

- [x] Conversion(value, from_currency, to_currency)
	- [x] Base to Currency
	- [x] Currency to Base
	- [x] Currency to Currency
	- [x] Base to Base
	- [x] Round by Minor Unit
	- [x] Manage Decimal type correctly

- [x] Review Clients functions -- Bad wallet management
	- [x] Check available_currencies
	- [x] Check minor_unit compliance
	- [x] wallet creations
	- [x] wallet updates


#### Test Programs
- "Hello World" Elixir
- "Hello World" Elixir Script
- Advanced Test programming in progress

#### Ressources
- Get ISO_4217 tab in csv and json format.
	- Clean json
- Fetch and save Test subject

---
### <u>Chore:
##### Continuous integration
- Init CircleCi
- Read Documentation -> 25%
- Add rule in CircleCi to check format
- [“mix format --check-formatted”](https://hexdocs.pm/mix/Mix.Tasks.Format.html)
- Reactivate CircleCi on the master branch

- [x] Dialyxir integration
- [x] Remove useless warning for protocol GIN in registry.ex

#### Git
- Create a dev git branch

#### Working Environnement
- Install Elixir
- Config Atom for Elixir
- Add Elixir linter in Atom
- Format command executed for each save on '.ex' and '.exs' files

---
### <u>Test:
- Tests FS
	- Create Client
- Tests Registry
	- Create_client
	- Fetch
- Test Transfer part
	- need details ...
- Test Currency_API part
	- need details ...

---
### <u>Documentation:
- Read documentation about Stoneco best practice
- Read documentation about Elixir Style Guide
- Read documentation from [Elixir School](https://elixirschool.com/en/)
	- Basic Part
	- Advanced Part In Progress
- Read documentation from [Elixir-lang](https://elixir-lang.org/)
	- Getting Started DONE
	- MIX and OTP DONE

- Get Cheat sheet
- Export Documentations on Mobile Device
	- Stoneco best practice
	- Elixir Style Guide
	- Cheat sheet
	- Elixir School
	- Elixir-lang
