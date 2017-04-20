(*
 * xz-examples-delphi
 * Copyright (C) 2015 Vincent Hardy <vincent.hardy.be@gmail.com>
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
 * http://www.gnu.org/licenses/.
 *)

{$APPTYPE CONSOLE}
program decompress;

uses
  Windows,Classes,sysutils,
  XZ;

const
  BufferSize=65536;
var
  InFile:TStream;  
  StdOut:THandleStream;
  DeComp:TXZDecompressionStream;
  Buffer:array[0..BufferSize-1] of Byte;
  i,count:integer;
begin
  if paramcount<1 then
  begin
    writeln(ErrOutput,'Usage: '+paramstr(0)+' FILES...');
    halt(1);
  end;

  StdOut := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE));
  try
    for i:=1 to paramcount do
    begin
      InFile := TFileStream.Create(ParamStr(i), fmOpenRead + fmShareDenyWrite);
      Decomp := TXZDecompressionStream.Create(InFile);
      try
        while True do
        begin
          Count:=Decomp.Read(Buffer,BufferSize);
          if Count<>0 then StdOut.WriteBuffer(Buffer,Count) else Break;
        end;
      finally
        DeComp.Free;
        InFile.Free;
      end;
    end;
  finally
    StdOut.Free;
  end;
end.
