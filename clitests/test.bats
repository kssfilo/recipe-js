#!/usr/bin/env bats

@test "basic" {
	[ "$(../dist/cli.js)" = "Hello World RecipeJs" ]
}

@test "arguments" {
	[ "$(../dist/cli.js -F arguments.rcp -a -b Hello --flagC --argD=World)" = "true Hello true World" ]
}

