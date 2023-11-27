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
❯ zig build run
Welcome to Monkey Islang!!!
This is the REPL for Monkey programming language.
Feel free to type commands or 'quit;'
>> let a = 10;
token.Token{ .type = token.TokenType.LET, .literal = { 108, 101, 116 } }
token.Token{ .type = token.TokenType.IDENT, .literal = { 97 } }
token.Token{ .type = token.TokenType.ASSIGN, .literal = { 61 } }
token.Token{ .type = token.TokenType.INT, .literal = { 49, 48 } }
token.Token{ .type = token.TokenType.SEMICOLON, .literal = { 59 } }
>> quit;
token.Token{ .type = token.TokenType.IDENT, .literal = { 113, 117, 105, 116 } }

May your trip be as enjoyable as finding extra bananas at the bottom of the bag!
```

- We will visit
  - [x] **Lexer** islang
  - [ ] **Parser** islang
  - [ ] **AST** islang
  - [ ] **IOS** islang also known as Internal Object System islang
  - [ ] **Evaluator** islang
