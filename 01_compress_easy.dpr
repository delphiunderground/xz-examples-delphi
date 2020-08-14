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

// Compress from stdin to stdout in multi-call mode
//
// Usage:      01_compress_easy PRESET < INFILE > OUTFILE
//
// Example:    01_compress_easy 6 < foo > foo.xz


{$APPTYPE CONSOLE}
program compress_easy;

uses
  SysUtils, Windows, Classes,
  LibLZMA, XZ;


procedure show_usage_and_exit;
begin
  writeln(ErrOutput,'Usage: '+paramstr(0)+' PRESET < INFILE > OUTFILE');
  writeln(ErrOutput,'PRESET is a number 0-9 and can optionally be followed by ''e'''+
         ' to indicate extreme preset');
  halt(1);
end;

function get_preset:Cardinal;
begin
  // One argument whose first char must be 0-9.
  if (paramcount<>1) or (paramstr(1)[1]<'0') or (paramstr(1)[1]>'9')
  then
    show_usage_and_exit;
  // Calculate the preste level 0-9.
  result:=ord(paramstr(1)[1])-48;
  // If there is a second char, it must be 'e'. It will set
  // the LZMA_PRESET_EXTREME flag.
  if length(paramstr(1))>1 then
  begin
    if (paramstr(1)[2]<>'e') and (length(paramstr(1))<>2)
    then
      show_usage_and_exit
    else
      result:=result or LZMA_PRESET_EXTREME;
  end;
end;

var
  StdIn,StdOut:THandleStream;
  Comp: TXZCompressionStream;
  preset:Cardinal;
begin
  if LoadLZMADLL then
  begin
    preset:=get_preset;
    StdIn := THandleStream.Create(GetStdHandle(STD_INPUT_HANDLE));
    StdOut := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE));
    Comp := TXZCompressionStream.Create(StdOut, preset, LZMA_CHECK_CRC64);
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
