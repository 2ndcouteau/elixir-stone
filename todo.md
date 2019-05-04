# <u>__TODO__</u>

### Feat:
#### Test Stone Challenge Financial-System
- [] Define all upstream needs

- [] Create the whole architecture
	- [x] Create a supervisor
	- [x] Create a registry
	- [x] Create a DynamicSupervisor for Clients
	- [x] Create first rules for Clients
	- [] a Stack ?
	- [] Find a way to fetch conversion values

- [] Fetch currency conversion value
	- First and simple way:
		- [] Hard encoded conversion value
	- or:
		- [] Extern API usage
			- https://fixer.io/
			- https://currencylayer.com/
			- https://openexchangerates.org/
---

### <u>Function:
- [x] create_client(name, main_currency \\ "BRL")
	- Presently named `cc`
- [] Create a wallet by default with an `amount_deposited`
	- Update nested Map in Struct
	- Init Currency with the `main_currency`
- [] create_wallet(client_id, currency, deposit \\ 0)
- [] delete_client(client_id)
- [] transfert(client_id, to_client_id, value, currency, direct_conversion \\ :true)
- [] multi_transfert(client, {to_clients}, value, currency, direct_conversion \\ :true)
- [] conversion(client, value, from_currency, to_currency)


### <u>Structure:

- #### New Client creation:
	- Prototype:
		- Parameters: ("name", ID, "Currency_CODE", %{Wallets map})
		- .
	- When you create a `new client`, you have to create a `unique HASH` from
	the `global map{}` of client.
		This `HASH` will be as the ID in the Client structure.
		Like that you will be able to certified the unicity of the client and
		to provide a simple way to identify the client.
		- Can be a number

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
				- Main_currency
					- String reference from ISO_4217
						- Ex: "BRL"
				- Wallets
					- Map %{}
					- At least one key:value init
					(value can be positive or negative)
						- Ex: {"BRL": 1000}

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

#### Git
- Create a dev git branch

#### Working Environnement
- Install Elixir
- Config Atom for Elixir
- Add Elixir linter in Atom
- Format command executed for each save on '.ex' and '.exs' files

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
