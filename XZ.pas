(*
 * XZ stream management Unit
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

unit XZ;

interface

{$IFNDEF VER90}
{$IFNDEF VER93}
{$IFNDEF VER100}
{$IFNDEF VER110}
{$IFNDEF VER120}
{$IFNDEF VER125}
{$IFNDEF VER130}
{$DEFINE LFS} { Large File Support }
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}
{$ENDIF}

uses
  SysUtils, Classes, LibLZMA;

type
  // Abstract ancestor class
  TCustomXZStream = class(TStream)
  private
    FStrm: TStream;
  {$IFDEF LFS}
    FStrmPos: Int64;
  {$ELSE}
    FStrmPos: Integer;
  {$ENDIF}
    FOnProgress: TNotifyEvent;
    FXZRec: lzma_stream;
    FBuffer: array[Word] of Char;
  protected
    procedure Progress(Sender: TObject); dynamic;
    property OnProgress: TNotifyEvent read FOnProgress write FOnProgress;
    constructor Create(Strm: TStream);
  public
    destructor Destroy; override;
  end;

{ TXZCompressionStream compresses data on the fly as data is written to it, and
  stores the compressed data to another stream.

  TXZCompressionStream is write-only and strictly sequential. Reading from the
  stream will raise an exception. Using Seek to move the stream pointer
  will raise an exception.

  Output data is cached internally, written to the output stream only when
  the internal output buffer is full.  All pending output data is flushed
  when the stream is destroyed.

  The Position property returns the number of uncompressed bytes of
  data that have been written to the stream so far.

  The OnProgress event is called each time the output buffer is filled and
  written to the output stream.  This is useful for updating a progress
  indicator when you are writing a large chunk of data to the compression
  stream in a single call.}

  TXZCompressionStream = class(TCustomXZStream)
  private
  public
    constructor Create(Dest: TStream; preset:uint32_t; check: lzma_check=LZMA_CHECK_CRC64);
    constructor Create_custom(Dest: TStream; filters:pointer; check: lzma_check=LZMA_CHECK_CRC64);
    constructor Create_mt(Dest: TStream; mt:pointer);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
{$IFDEF LFS}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
{$ENDIF}
    property OnProgress;
  end;

{ TDecompressionStream decompresses data on the fly as data is read from it.

  Compressed data comes from a separate source stream.  TDecompressionStream
  is read-only and unidirectional; you can seek forward in the stream, but not
  backwards.  The special case of setting the stream position to zero is
  allowed.  Seeking forward decompresses data until the requested position in
  the uncompressed data has been reached.  Seeking backwards, seeking relative
  to the end of the stream, requesting the size of the stream, and writing to
  the stream will raise an exception.

  The Position property returns the number of bytes of uncompressed data that
  have been read from the stream so far.

  The OnProgress event is called each time the internal input buffer of
  compressed data is exhausted and the next block is read from the input stream.
  This is useful for updating a progress indicator when you are reading a
  large chunk of data from the decompression stream in a single call.}

  TXZDecompressionStream = class(TCustomXZStream)
  public
    constructor Create(Source: TStream);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
{$IFDEF LFS}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
{$ENDIF}
    property OnProgress;
  end;

  EXZError = class(Exception);
  EXZCompressionError = class(EXZError);
  EXZDecompressionError = class(EXZError);

function lzma_cputhreads: uint32_t;
function lzma_lzma_preset(options: pointer; preset: uint32_t): boolean;

implementation

function lzma_cputhreads: uint32_t;
begin
  result:=Tf_lzma_cputhreads(plzma_cputhreads);
end;

function lzma_lzma_preset(options: pointer; preset: uint32_t): boolean;
begin
  if Tf_lzma_lzma_preset(plzma_lzma_preset)(options, preset)<>LZMA_OK then
  begin
    raise Exception.CreateFmt('Unsupported preset, possibly a bug',[]);
  end else Result:=true;;
end;

function CCheck(code: Integer): Integer;
var
  msg:string;
begin
  Result := code;
  if (code <> LZMA_OK) and (code<>LZMA_STREAM_END) then
  begin
    case code of
    LZMA_MEM_ERROR: msg:='Memory allocation failed';
    LZMA_OPTIONS_ERROR: msg:='Specified preset is not supported';
    LZMA_UNSUPPORTED_CHECK: msg:='Specified integrity check is not supported';
    LZMA_DATA_ERROR: msg:='File size limits exceeded';   // >(2^63 bytes) !!!!
    else msg:='Unknown error, possibly a bug';
         // This is most likely LZMA_PROG_ERROR.
    end;
    raise EXZCompressionError.CreateFmt('%s - error code %d', [msg,code]);
  end;
end;

function DCheck(code: Integer): Integer;
var
  msg:string;
begin
  Result := code;
  if (code <> LZMA_OK) and (code<>LZMA_STREAM_END) then
  begin
    case code of
    LZMA_OPTIONS_ERROR: msg:='Unsupported decompressor flags';
    LZMA_MEM_ERROR: msg:='Memory allocation failed';
    LZMA_FORMAT_ERROR: msg:='The input is not in the .xz format';
                       // .xz magic bytes weren't found.
    LZMA_DATA_ERROR: msg:='Compressed file is corrupt';
    LZMA_BUF_ERROR: msg:='Compressed file is truncated or otherwise corrupt';
    else msg:='Unknown error, possibly a bug';
         // This is most likely LZMA_PROG_ERROR.
    end;
    raise EXZDecompressionError.CreateFmt('%s - error code %d', [msg,code]);
  end;
end;


// TCustomXZStream

constructor TCustomXZStream.Create(Strm: TStream);
begin
  inherited Create;
  FStrm := Strm;
  FStrmPos := Strm.Position;
  //When you declare an instance of lzma_stream, you can immediately
  //initialize it so that initialization functions know that no memory
  //has been allocated yet. Delphi does this for us with FXZRec.
end;

procedure TCustomXZStream.Progress(Sender: TObject);
begin
  if Assigned(FOnProgress) then FOnProgress(Sender);
end;

destructor TCustomXZStream.Destroy;
begin
  inherited Destroy;
end;


// TXZCompressionStream

constructor TXZCompressionStream.Create(Dest: TStream; preset:uint32_t; check: lzma_check=LZMA_CHECK_CRC64);
begin
  inherited Create(Dest);
  FXZRec.next_out := FBuffer;
  FXZRec.avail_out := sizeof(FBuffer);
  CCheck(Tf_lzma_easy_encoder(plzma_easy_encoder)(@FXZRec, preset, check));
end;

constructor TXZCompressionStream.Create_custom(Dest: TStream; filters:pointer; check: lzma_check=LZMA_CHECK_CRC64);
begin
  inherited Create(Dest);
  FXZRec.next_out := FBuffer;
  FXZRec.avail_out := sizeof(FBuffer);
  CCheck(Tf_lzma_stream_encoder(plzma_stream_encoder)(@FXZRec, filters, check));
end;

constructor TXZCompressionStream.Create_mt(Dest: TStream; mt:pointer);
begin
  inherited Create(Dest);
  FXZRec.next_out := FBuffer;
  FXZRec.avail_out := sizeof(FBuffer);
  CCheck(Tf_lzma_stream_encoder_mt(plzma_stream_encoder_mt)(@FXZRec, mt));
end;

destructor TXZCompressionStream.Destroy;
begin
  FXZRec.next_in := nil;
  FXZRec.avail_in := 0;
  try
    if FStrm.Position <> FStrmPos then FStrm.Position := FStrmPos;
    while (CCheck(Tf_lzma_code(plzma_code)(@FXZRec,LZMA_FINISH)) <> LZMA_STREAM_END)
      and (FXZRec.avail_out = 0) do
    begin
      FStrm.WriteBuffer(FBuffer, sizeof(FBuffer));
      FXZRec.next_out := FBuffer;
      FXZRec.avail_out := sizeof(FBuffer);
    end;
    if FXZRec.avail_out < sizeof(FBuffer) then
      FStrm.WriteBuffer(FBuffer, sizeof(FBuffer) - FXZRec.avail_out);
  finally
    Tf_lzma_end(plzma_end)(@FXZRec);
  end;

  inherited Destroy;
end;

function TXZCompressionStream.Read(var Buffer; Count: Longint): Longint;
begin
  raise EXZCompressionError.Create('Invalid stream operation');
end;

function TXZCompressionStream.Write(const Buffer; Count: Longint): Longint;
begin
  FXZRec.next_in := @Buffer;
  FXZRec.avail_in := Count;
  if FStrm.Position <> FStrmPos then FStrm.Position := FStrmPos;
  while (FXZRec.avail_in > 0) do
  begin
    CCheck(Tf_lzma_code(plzma_code)(@FXZRec, LZMA_RUN));
    if FXZRec.avail_out = 0 then
    begin
      FStrm.WriteBuffer(FBuffer, sizeof(FBuffer));
      FXZRec.next_out := FBuffer;
      FXZRec.avail_out := sizeof(FBuffer);
      FStrmPos := FStrm.Position;
    end;
    Progress(Self);
  end;
  Result := Count;
end;

function TXZCompressionStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  if (Offset = 0) and (Origin = soFromCurrent) then
    Result := FXZRec.total_in
  else
    raise EXZCompressionError.Create('Invalid stream operation');
end;

{$IFDEF LFS}
function TXZCompressionStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  if (Offset = 0) and (Origin = soCurrent) then
    Result := FXZRec.total_in
  else
    raise EXZCompressionError.Create('Invalid stream operation');
end;
{$ENDIF}


// TDecompressionStream

constructor TXZDecompressionStream.Create(Source: TStream);
begin
  inherited Create(Source);
  FXZRec.next_in := FBuffer;
  FXZRec.avail_in := 0;
  DCheck(Tf_lzma_stream_decoder(plzma_stream_decoder)(@FXZRec, Int64(-1), LZMA_CONCATENATED));
end;

destructor TXZDecompressionStream.Destroy;
begin
  Tf_lzma_end(plzma_end)(@FXZRec);
  inherited Destroy;
end;

function TXZDecompressionStream.Read(var Buffer; Count: Longint): Longint;
begin
  FXZRec.next_out := @Buffer;
  FXZRec.avail_out := Count;
  if FStrm.Position <> FStrmPos then FStrm.Position := FStrmPos;
  while (FXZRec.avail_out > 0) do
  begin
    if FXZRec.avail_in = 0 then
    begin
      FXZRec.avail_in := FStrm.Read(FBuffer, sizeof(FBuffer));
      if FXZRec.avail_in = 0 then
      begin
        Result := Count - FXZRec.avail_out;
        if Result=0 then DCheck(Tf_lzma_code(plzma_code)(@FXZRec, LZMA_FINISH));
        Exit;
      end;
      FXZRec.next_in := FBuffer;
      FStrmPos := FStrm.Position;
    end;
    DCheck(Tf_lzma_code(plzma_code)(@FXZRec, LZMA_RUN));
    Progress(Self);
  end;
  Result := Count;
end;

function TXZDecompressionStream.Write(const Buffer; Count: Longint): Longint;
begin
  raise EXZDecompressionError.Create('Invalid stream operation');
end;

function TXZDecompressionStream.Seek(Offset: Longint; Origin: Word): Longint;
var
  I: Integer;
  Buf: array[0..4095] of Char;
begin
  if (Offset = 0) and (Origin = soFromBeginning) then
  begin
    FStrm.Position := 0;
    FStrmPos := 0;
  end
  else if ((Offset >= 0) and (Origin = soFromCurrent)) or
    (((Offset - FXZRec.total_out) > 0) and (Origin = soFromBeginning)) then
  begin
    if Origin = soFromBeginning then Dec(Offset, FXZRec.total_out);
    if Offset > 0 then
    begin
      for I := 1 to Offset div sizeof(Buf) do
        ReadBuffer(Buf, sizeof(Buf));
      ReadBuffer(Buf, Offset mod sizeof(Buf));
    end;
  end
  else
    raise EXZDecompressionError.Create('Invalid stream operation');
  Result := FXZRec.total_out;
end;

{$IFDEF LFS}
function TXZDecompressionStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
var
  I     : Integer;
  Buf   : array[0..4095] of Char;
  NewOff: Int64;
begin
  if (Offset = 0) and (Origin = soBeginning) then
  begin
    FStrm.Position := 0;
    FStrmPos := 0;
  end
  else if ((Offset >= 0) and (Origin = soCurrent)) or
    (((Offset - FXZRec.total_out) > 0) and (Origin = soBeginning)) then
  begin
    NewOff := Offset;
    if Origin = soBeginning then Dec(NewOff, FXZRec.total_out);
    if NewOff > 0 then
    begin
      for I := 1 to NewOff div sizeof(Buf) do
        ReadBuffer(Buf, sizeof(Buf));
      ReadBuffer(Buf, NewOff mod sizeof(Buf));
    end;
  end
  else
    raise EXZDecompressionError.Create('Invalid stream operation');
  Result := FXZRec.total_out;
end;
{$ENDIF}


end.
