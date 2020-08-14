(*
 * xz-examples-delphi
 * Copyright (C) 2015-2020 Vincent Hardy <vincent.hardy@linuxunderground.be>
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License version
 * 3.0 as published by the Free Software Foundation.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, see
 * https://www.gnu.org/licenses/.
 *)

// Compress in multi-call mode using LZMA2 in multi-threaded mode
//
// Usage:      04_compress_easy_mt < INFILE > OUTFILE
//
// Example:    04_compress_easy_mt < foo > foo.xz


{$APPTYPE CONSOLE}
program compress_easy_mt;

uses
  SysUtils, Windows, Classes,
  LibLZMA, XZ;

var
  mt: lzma_mt;
  StdIn,StdOut: THandleStream;
  Comp: TXZCompressionStream;
begin
  if LoadLZMADLL then
  begin
    With mt do
    begin
      // No flags are needed.
      flags:=0;

      // Let liblzma determine a sane block size.
      block_size:=0;

      // Use no timeout for lzma_code() calls by setting timeout
      // to zero. That is, sometimes lzma_code() might block for
      // a long time (from several seconds to even minutes).
      // If this is not OK, for example due to progress indicator
      // needing updates, specify a timeout in milliseconds here.
      // See the documentation of lzma_mt in lzma/container.h for
      // information how to choose a reasonable timeout.
      timeout:=0;

      // Use the default preset (6) for LZMA2.
      // To use a preset, filters must be set to NULL.
      preset:=LZMA_PRESET_DEFAULT;
      filters:=nil;

      // Use CRC64 for integrity checking. See also
      // 01_compress_easy.dpr about choosing the integrity check.
      check:=LZMA_CHECK_CRC64;

      // Detect how many threads the CPU supports.
      threads:=lzma_cputhreads;
      // If the number of CPU cores/threads cannot be detected,
      // use one thread. Note that this isn't the same as the normal
      // single-threaded mode as this will still split the data into
      // blocks and use more RAM than the normal single-threaded mode.
      // You may want to consider using lzma_easy_encoder() or
      // lzma_stream_encoder() instead of lzma_stream_encoder_mt() if
      // lzma_cputhreads() returns 0 or 1.
      if threads=0 then threads:=1;

      // If the number of CPU cores/threads exceeds threads_max,
      // limit the number of threads to keep memory usage lower.
      // The number 8 is arbitrarily chosen and may be too low or
      // high depending on the compression preset and the computer
      // being used.
      //
      // FIXME: A better way could be to check the amount of RAM
      // (or available RAM) and use lzma_stream_encoder_mt_memusage()
      // to determine if the number of threads should be reduced.
      if threads > 8 then threads:=8;
    end;
    StdIn := THandleStream.Create(GetStdHandle(STD_INPUT_HANDLE));
    StdOut := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE));
    Comp := TXZCompressionStream.Create_mt(StdOut, @mt);
    try
      Comp.CopyFrom(StdIn, 0);
    finally
      Comp.Free;
      StdIn.Free;
      StdOut.Free;
    end;
    UnloadLZMADLL;
  end else
    raise Exception.CreateFmt('%s not found.',[LZMA_DLL]);
end.
