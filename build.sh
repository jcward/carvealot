#!/bin/bash

set -e

rm -rf dist
mkdir dist
cp src/index.html dist/
sassc src/style.scss > dist/style.css

haxe build.hxml
