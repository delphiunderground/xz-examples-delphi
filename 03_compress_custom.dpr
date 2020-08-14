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

// Compress in multi-call mode using x86 BCJ and LZMA2
//
// Usage:      03_compress_custom < INFILE > OUTFILE
//
// Example:    03_compress_custom < foo > foo.xz


{$APPTYPE CONSOLE}
program compress_custom;

uses
  SysUtils, Windows, Classes,
  LibLZMA, XZ;

var
  opt_lzma2: lzma_options_lzma;
  filters:array[1..3] of lzma_filter;
  StdIn,StdOut:THandleStream;
  Comp: TXZCompressionStream;
begin
  if LoadLZMADLL then
  begin
    //Init Filters
    // Use the default preset (6) for LZMA2.
    if not lzma_lzma_preset(@opt_lzma2, LZMA_PRESET_DEFAULT) then
    begin
      // It should never fail because the default preset
      // (and presets 0-9 optionally with LZMA_PRESET_EXTREME)
      // are supported by all stable liblzma versions.
      //
      // (The encoder initialization later in this function may
      // still fail due to unsupported preset *if* the features
      // required by the preset have been disabled at build time,
      // but no-one does such things except on embedded systems.)
      writeln(ErrOutput,'Unsupported preset, possibly a bug!');
      halt(1);
    end;
    // Now we could customize the LZMA2 options if we wanted. For example,
    // we could set the the dictionary size (opt_lzma2.dict_size) to
    // something else than the default (8 MiB) of the default preset.
    // See lzma/lzma12.h for details of all LZMA2 options.
    //
    // The x86 BCJ filter will try to modify the x86 instruction stream so
    // that LZMA2 can compress it better. The x86 BCJ filter doesn't need
    // any options so it will be set to NULL below.
    //
    // Construct the filter chain. The uncompressed data goes first to
    // the first filter in the array, in this case the x86 BCJ filter.
    // The array is always terminated by setting .id = LZMA_VLI_UNKNOWN.
    //
    // See lzma/filter.h for more information about the lzma_filter
    // structure.
    filters[1].id:=LZMA_FILTER_X86;
    filters[1].options:=nil;
    filters[2].id:=LZMA_FILTER_LZMA2;
    filters[2].options:=@opt_lzma2;
    filters[3].id:=LZMA_VLI_UNKNOWN;
    filters[3].options:=nil;
    StdIn := THandleStream.Create(GetStdHandle(STD_INPUT_HANDLE));
    StdOut := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE));
    Comp := TXZCompressionStream.Create_custom(StdOut, @filters, LZMA_CHECK_CRC64);
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
