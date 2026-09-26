#!/bin/bash

set -e

cd slides
rm -rf ../website/static/slides
echo Building Slides
make
mkdir -p ../website/static/slides
cp build/*.pdf ../website/static/slides/

cd ..
echo Building Website
cd website
npm install
npm run clear
npm run build
