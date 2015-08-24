
liblzma example programs
========================

Introduction

    You have to first install XZ-utils Windows binaries (http://tukaani.org/xz/)
    Liblzma.dll have to be accessible to Delphi .exe files.

    The examples are written so that the same comments aren't
    repeated (much) in later files.

File XZ.pas

    liblzma Data Compression Interface Unit


List of examples

    01_compress_easy.dpr                Multi-call compression using
                                        a compression preset

    02_decompress.dpr                   Multi-call decompression


Todo examples

    03_compress_custom.dpr              Like 01_compress_easy.c but using
                                        a custom filter chain
                                        (x86 BCJ + LZMA2)

    04_compress_easy_mt.dpr             Multi-threaded multi-call
                                        compression using a compression
                                        preset

