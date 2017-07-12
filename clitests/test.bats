#!/usr/bin/env bats

@test "basic" {
	[ "$(../dist/cli.js)" = "Hello World RecipeJs" ]
}

@test "arguments" {
	[ "$(../dist/cli.js -F arguments.rcp -a -b Hello --flagC --argD=World)" = "true Hello true World" ]
}

@test "make" {
	[ "$(echo '# RecipeJs' >test.md;rm -f test.html;../dist/cli.js -F make.rcp;cat test.html;rm test.html;rm test.md)" = "<h1>RecipeJs</h1>" ]
}

