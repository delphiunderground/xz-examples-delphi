liblzma example programs
========================

Introduction

    You have to first install XZ-utils Windows binaries (https://tukaani.org/xz/)
    Liblzma.dll have to be accessible to Delphi .exe files.

    The examples are written so that the same comments aren't
    repeated (much) in later files.


Delphi units

    LibLZMA.pas                         liblzma Interface Unit
    XZ.pas                              XZ stream management Unit


List of examples

    01_compress_easy.dpr                Multi-call compression using
                                        a compression preset

    02_decompress.dpr                   Multi-call decompression


    03_compress_custom.dpr              Like 01_compress_easy.c but using
                                        a custom filter chain
                                        (x86 BCJ + LZMA2)

    04_compress_easy_mt.dpr             Multi-threaded multi-call
                                        compression using a compression
                                        preset


Known issue

    03_compress_custom does not work when it is compiled with
    Windows 32 bits target (tested with xz-utils 5.2.5).

