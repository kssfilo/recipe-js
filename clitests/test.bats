#!/usr/bin/env bats

@test "basic" {
	[ "$(../dist/cli.js)" = "Hello World RecipeJs" ]
}

@test "arguments" {
	[ "$(../dist/cli.js -f arguments.rcp -a -b Hello --flagC --argD=World)" = "true Hello true World" ]
}

@test "make" {
	[ "$(echo 'RecipeJs' >test.txt;rm -f test.html;../dist/cli.js -f make.rcp;cat test.html;rm test.html;rm test.md;rm test.txt)" = "<h1>RecipeJs</h1>" ]
}

@test "make-nopipe" {
	[ "$(echo 'RecipeJs' >test.txt;rm -f test.md;rm -f test.html;../dist/cli.js -f make-nopipe.rcp;cat test.html;rm test.html;rm test.md;rm test.txt)" = "RecipeJs" ]
}
