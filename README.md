# elixir_stone
###### Entry test for Stone company

This program is writing in [Elixir](https://elixir-lang.org/)

###### Summary of the exercise:

Create a sample of bank account exchange management.
You will be able to create client accounts with different wallets.
Then, you will be able to transfer money between different wallets.
From a client wallet to another wallet, from a client wallet to another
client wallet or between a client wallet and multiple clients wallets.
Every money transfer are compliant with the norm ISO_4217.

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

You can lunch the application with the following command:
```
iex -S mix
```

You can run tests with:
```
mix test
```

And also use the static analyzer `Dialyxir` with:
```
mix dialyzer
```
Some errors are ignored. You can find more details about them in the file
`.dialyzer_ignore` in the root of the project.

---

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
