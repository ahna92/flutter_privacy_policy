#!/bin/bash


flutter build web

rm -rf public/*

cp -r build/web/ public/

#firebase emulators:start
