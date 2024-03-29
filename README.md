# Tungsten - WolframAlpha CLI

## Overview

A GPLv3+ licensed bash script that processes queries with the **WolframAlpha API**. It is named tungsten because that word refers to the same metal that wolfram does, respectively of Swedish and German origin.

Derived from `wa.sh` by [saironiq](https://github.com/saironiq/shellscripts/tree/master/wolframalpha_com).

## How To Use

You should get your own [API Key](https://developer.wolframalpha.com/portal/apisignup.html) (called AppID on WolframAlpha) from WolframAlpha before use. It can take a few minutes or hours to get your API key once you apply for it. If you do not provide an API key then a fallback will be used, however that may result in a few missing / incorrect characters in the output.

Simply type the query as you would at [WolframAlpha.com](https://wolframalpha.com), examples:

    tungsten "P=NP"
    tungsten "What's the airspeed of an unladen swallow?"
    tungsten What is the airspeed of a laden swallow?

The results that can be displayed as plain text will be returned for you to view, example:

    $ tungsten not a or b
    Input
    ¬a||b
    (NOT a) OR  b
    Truth table
    a | b | ¬a||b
    T | T | T
    T | F | F
    F | T | T
    F | F | T
    Minimal forms
    DNF | ¬a||b
    CNF | ¬a||b
    ANF | ¬((a&&b)xora)
    NOR | ¬(¬anorb)
    NAND | anand¬b
    AND | ¬(a&&¬b)
    OR | ¬a||b
    Other forms
    ESOP | (¬a&&¬b)xorb
    ITE | (a&&b)||¬a
    Boolean operator number
    11 with variable ordering {a, b}

When outputting to a terminal, the output is colourised.

## Install

Tungsten requires the following packages: `curl`, `jq`, and `bash`, as well as the POSIX `iconv` command, which is often provided by libc packages like `glibc`. Provided that these are installed, the script can be run in-place, or included in your PATH.

## Changelog

### 2.1

* Handle null results gracefully. Thanks to @federicotorrielli

### 2.0

* Swap `xmlstarlet` dependency out for `jq` (JSON backend instead of XML). This avoids a class of bugs from XML handling.
* Support for simple queries without an API Key. Thanks to @theblazehen

### 1.1
*   Add XML un-escape to fix seeing things like `&amp;` in the results

### 1.0
*   Initial release
