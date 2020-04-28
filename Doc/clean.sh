#!/bin/sh
rubber --pdf --clean LFToolbox
rm *.log > /dev/null 2>&1
rm *.aux *.out *.blg *.bbl > /dev/null 2>&1
