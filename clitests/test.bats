#!/usr/bin/env bats

@test "basic" {
	[ "$(../dist/cli.js)" = "Hello World RecipeJs" ]
}

@test "arguments" {
	[ "$(../dist/cli.js -f arguments.rcp -a -b Hello --flagC --argD=World)" = "true Hello true World" ]
}

@test "make" {
	[ "$(echo 'RecipeJs' >test.txt;rm -f test.html;../dist/cli.js -f make.rcp;sleep 1;echo 'RecipeJs2'>test.txt;../dist/cli.js -f make.rcp;cat test.html;rm test.html;rm test.md;rm test.txt)" = "<h1>RecipeJs2</h1>" ]
}

@test "make-bin" {
	[ "$(dd if=/dev/urandom of=test.png bs=1k count=1 2>/dev/null >/dev/null ;rm -f test.bin;../dist/cli.js -f make-bin.rcp;diff test.bin test.png 2>&1;rm test.bin test.png)" = "" ]
}

@test "make-nopipe" {
	[ "$(echo 'RecipeJs' >test.txt;rm -f test.md;rm -f test.html;../dist/cli.js -f make-nopipe.rcp;cat test.html;rm test.html;rm test.md;rm test.txt)" = "RecipeJs" ]
}

@test "shell" {
	[ $(../dist/cli.js -f shell.rcp|tr -d "\n") = "RecipeJS" ]
}

@test "exec" {
	[ $(../dist/cli.js -f exec.rcp|tr -d "\n") = "RecipeJS" ]
}

@test "shebang" {
	cd shebang
	[ $(./shebang.rcp|tr -d "\n") = "RecipeJS" ]
	cd -
}
