#!/bin/sh

# Script to download JDownloader JAR if not present

if [ ! -f JDownloader.jar ]; then
    wget -nv --timeout=5 -O JDownloader.jar http://installer.jdownloader.org/JDownloader.jar || rm -f JDownloader.jar
fi
