# XZ examples for Delphi

## Overview

This repository aims to provide Delphi bindings for liblzma and a translation
of \doc\examples\ from XZ Utils package to Delphi. This Delphi code is
licensed under LGPL3.

It should work with almost all versions of Delphi and even with
Lazarus/FreePascal. However, pay attention to older versions of Delphi :
the ErrOutput variable is not defined.

Currently, I do not care of linux compatibility because I had troubles
with command line FreePascal compiler and when generating Makefile.

Any suggestions or improvements are welcome.
Send them to vincent.hardy.be@gmail.com

Homepage: https://github.com/delphiunderground/xz-example-delphi


## About XZ utils and liblzma

liblzma is a public domain general-purpose data compression library with
a zlib-like API. The native file format is .xz, but also the old .lzma
format and raw (no headers) streams are supported. Multiple compression
algorithms (filters) are supported. Currently LZMA2 is the primary filter.

liblzma is part of [XZ Utils](https://tukaani.org/xz/). XZ Utils includes
a gzip-like command line tool named xz and some other tools. XZ Utils
is developed and maintained by Lasse Collin.

Major parts of liblzma are based on Igor Pavlov's public domain
[LZMA SDK](http://www.7-zip.org/sdk.html).
The SHA-256 implementation is based on the public domain code found from
[7-Zip](http://www.7-zip.org), which has a modified version of the public
domain SHA-256 code found from [Crypto++](https://www.cryptopp.com).
The SHA-256 code in Crypto++ was written by Kevin Springle and Wei Dai.
