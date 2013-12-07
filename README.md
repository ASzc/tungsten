# Tungsten - WolframAlpha CLI

# Overview

A GPLv3+ licensed bash script that processes queries with the **WolframAlpha API**. It is named tungsten because that word refers to the same metal that wolfram does, respectively of Swedish and German origin.

Derived from `wa.sh` by [saironiq](https://github.com/saironiq/shellscripts/tree/master/wolframalpha_com).

## How To Use

Simply type the query as you would at [WolframAlpha.com](https://wolframalpha.com), examples:

    tungsten "P=NP"

    tungsten "What's the airspeed of an unladen swallow?"

    tungsten What is the airspeed of a laden swallow?

The results that can be displayed as plain text will be returned for you to view.

## Install

Tungsten requires the following packages: `curl`, `xmlstarlet`, and `bash`. Provided that these are installed, the script can be run in-place, or included in your PATH.
