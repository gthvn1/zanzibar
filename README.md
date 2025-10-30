# Zanzibar Red Colobus

## Monkey Islang

The **Zanzibar Red Colobus** is a monkey endemic to Unguja, the main island of the Zanzibar Archipelago.
The name was chosen by reference to [Monkeylang](https://monkeylang.org/). And as you probably notice its
name starts with a 'Z' and its a reference to [Ziglang](https://ziglang.org/).

Monkey is a programming language that you can build yourself by reading through
[Writing An Interpreter In Go](https://interpreterbook.com/) and
[Writing A Compiler In Go](https://compilerbook.com/). So let's give it a try...

Thus [Zanzibar](https://github.com/gthvn1/zanzibar/) is an implementation of [Monkey](https://monkeylang.org/) in [Zig](https://ziglang.org/)

## Travel to Monkey Islang

- As easy as `zig build run`
```
Welcome to Monkey Islang REPL!
Type Monkey code to set sail on an adventure.
Use '#help' for guidance, or '#quit' to leave the island.
>> ++/
You typed: <++/>
OK: added 3 tokens, total is 3
>> -/
You typed: <-/>
OK: added 2 tokens, total is 5
>> #help
Commands:
  #help   -> show available commands
  #quit   -> exit the REPL
  #tokens -> show current tokens
>> #quit
Farewell, adventurer! May you always find extra
bananas at the bottom of the bag...
```
- We will visit
  - [ ] **Lexer**
  - [ ] **Parser**
  - [ ] **AST**
  - [ ] **IOS**
  - [ ] **Evaluator**
