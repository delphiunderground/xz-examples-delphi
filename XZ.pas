(*
 * liblzma Data Compression Interface Unit
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

unit XZ;

interface

uses
  windows, Sysutils, Classes;

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

type
  uint32_t = longword;
  uint64_t = Int64;
  p_uint64_t = ^uint64_t;

  //size_t is also defined in delphi XE
  //C:\Program Files (x86)\Embarcadero\RAD Studio\10.0\source\rtl\posix\Posix.SysTypes.pas
  {$IFDEF WIN64}
  size_t = Int64;
  {$ELSE}
  size_t = integer;
  {$ENDIF}

  lzma_ret = integer;
  lzma_action = integer;
  lzma_check = integer;

  lzma_reserved_enum = integer;
  
{*
 * Custom functions for memory handling.
 * See also :
 * lzma/base.h (src/liblzma/api/lzma/base.h in the source package
 * or e.g. c:\xz\include\lzma\base.h depending on the install prefix).
 *}
  TAlloc = function(opaque: Pointer; Items, Size: size_t): Pointer; cdecl;
  TFree = procedure(opaque, Block: Pointer); cdecl;

  lzma_allocator = packed record
    XZalloc : TAlloc;
    XZfree : TFree;
    opaque : pointer;
  end;

  p_lzma_allocator = ^lzma_allocator;

{* 
 * Passing data to and from liblzma.
 * See also :
 * lzma/base.h (src/liblzma/api/lzma/base.h in the source package
 * or e.g. c:\xz\include\lzma\base.h depending on the install prefix).
 *}
  lzma_stream = packed record
    next_in : PChar;         //Pointer to the next input byte.
    avail_in : size_t;       //Number of available input bytes in next_in.
    total_in : uint64_t;     //Total number of bytes read by liblzma.

    next_out : PChar;        //Pointer to the next output position.
    avail_out : size_t;      //Amount of free space in next_out.
    total_out : uint64_t;    //Total number of bytes written by liblzma.

    //Custom memory allocation functions
    //In most cases this is nil which makes liblzma use
    //the standard malloc() and free().
    allocator : p_lzma_allocator; //pointer;

    //Internal state is not visible to applications.
    internal : pointer;

    //Reserved space to allow possible future extensions without
    //breaking the ABI. Excluding the initialization of this structure,
    //you should not touch these, because the names of these variables
    //may change.
    reserved_ptr1 : pointer;
    reserved_ptr2 : pointer;
    reserved_ptr3 : pointer;
    reserved_ptr4 : pointer;
    reserved_int1 : uint64_t;
    reserved_int2 : uint64_t;
    reserved_int3 : size_t;
    reserved_int4 : size_t;
    reserved_enum1 : lzma_reserved_enum;
    reserved_enum2 : lzma_reserved_enum;
  end;

  p_lzma_stream = ^lzma_stream;


{*
 * Initialize .xz Stream encoder using a preset number.
 * See also :
 * lzma/container.h (src/liblzma/api/lzma/container.h in the source package
 * or e.g. c:\xz\include\lzma\container.h depending on the install prefix).
 *}
  Tf_lzma_easy_encoder = function(
    strm: p_lzma_stream;
    preset: uint32_t;    //Compression preset to use.
    check: lzma_check    //Type of the integrity check to calculate from uncompressed data.
    ): lzma_ret; cdecl;

{*
 * Initialize .xz Stream decoder
 * See also :
 * lzma/container.h (src/liblzma/api/lzma/container.h in the source package
 * or e.g. c:\xz\include\lzma\container.h depending on the install prefix).
 *}
  Tf_lzma_stream_decoder = function(
    strm: p_lzma_stream;
    memlimit: uint64_t;
    flags: uint32_t
    ): lzma_ret; cdecl;

{*
 * Encode or decode data.
 *
 * Once the lzma_stream has been successfully initialized (e.g. with
 * lzma_stream_encoder()), the actual encoding or decoding is done
 * using this function. The application has to update strm->next_in,
 * strm->avail_in, strm->next_out, and strm->avail_out to pass input
 * to and get output from liblzma.
 *
 * See also :
 * lzma/base.h (src/liblzma/api/lzma/base.h in the source package
 * or e.g. c:\xz\include\lzma\base.h depending on the install prefix).
 *}
  Tf_lzma_code = function(
    strm: p_lzma_stream;
    action: lzma_action
    ): lzma_ret; cdecl;
{*
 * Free memory allocated for the coder data structures
 * See also :
 * lzma/base.h (src/liblzma/api/lzma/base.h in the source package
 * or e.g. c:\xz\include\lzma\base.h depending on the install prefix).
 *}
  Tf_lzma_end = procedure(
    pstrm: p_lzma_stream
    ); cdecl;


{*
 * lzma/container.h (src/liblzma/api/lzma/container.h in the source package
 * or e.g. c:\xz\include\lzma\container.h depending on the install prefix).
 *}
  Tf_lzma_easy_buffer_encode = function(
    preset: uint32_t;    //Compression preset to use.
    check: lzma_check;   //Type of the integrity check to calculate from uncompressed data.
    allocator: p_lzma_allocator;
    in_: PChar;
    in_size: size_t;
    out_: PChar;
    out_pos: pointer;
    out_size: size_t
    ): lzma_ret; cdecl;
  
  tf_lzma_stream_buffer_decode = function(
    memlimit: p_uint64_t;
    flags: uint32_t;
    allocator: p_lzma_allocator;
    in_: PChar;
    in_pos: pointer;
    in_size: size_t;
    out_: PChar;
    out_pos: pointer;
    out_size: size_t
    ): lzma_ret; cdecl;


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
    constructor Create(preset:uint32_t; Dest: TStream);
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

 
var
  lzmaHandle:THandle=0;

  plzma_easy_encoder:pointer;          //-> Tf_lzma_easy_encoder;
  plzma_stream_decoder:pointer;        //-> Tf_lzma_stream_decoder;
  plzma_code:pointer;                  //-> Tf_lzma_code;
  plzma_end:pointer;                   //-> Tf_lzma_end;

  plzma_easy_buffer_encode:pointer;    //-> Tf_lzma_easy_buffer_encode;
  plzma_stream_buffer_decode:pointer;  //-> Tf_lzma_stream_buffer_decode;

  
function LoadLzmaDLL:boolean;


implementation


const
  LZMA_DLL = 'liblzma.dll';  //-> http://tukaani.org/xz/xz-5.2.0-windows.zip

{*
 * Return values used by several functions in liblzma
 * These values are documented in
 * lzma/base.h (src/liblzma/api/lzma/base.h in the source package
 * or e.g. c:\xz\include\lzma\base.h depending on the install prefix).
 *}
  LZMA_OK = 0;
  LZMA_STREAM_END = 1;
  LZMA_NO_CHECK = 2;
  LZMA_UNSUPPORTED_CHECK = 3;
  LZMA_GET_CHECK = 4;
  LZMA_MEM_ERROR = 5;
  LZMA_MEMLIMIT_ERROR = 6;
  LZMA_FORMAT_ERROR = 7;
  LZMA_OPTIONS_ERROR = 8;
  LZMA_DATA_ERROR = 9;
  LZMA_BUF_ERROR = 10;
  LZMA_PROG_ERROR = 11;

{*
 * Type of the integrity check (Check ID)
 * This is documented in
 * lzma/check.h (src/liblzma/api/lzma/check.h in the source package
 * or e.g. c:\xz\include\lzma\check.h depending on the install prefix).
 *}
  LZMA_CHECK_NONE = 0;
  LZMA_CHECK_CRC32 = 1;
  LZMA_CHECK_CRC64 = 4;
  LZMA_CHECK_SHA256 = 10;

{*
 * The 'action' argument for lzma_code()
 * This is documented in
 * lzma/base.h (src/liblzma/api/lzma/base.h in the source package
 * or e.g. c:\xz\include\lzma\base.h depending on the install prefix).
 *}
  LZMA_RUN = 0;
  LZMA_SYNC_FLUSH = 1;
  LZMA_FULL_FLUSH = 2;
  LZMA_FULL_BARRIER = 4;
  LZMA_FINISH = 3;

{* 
 * Decoding
 *}  
  LZMA_CONCATENATED = $08;

function LoadLzmaDLL:boolean;
begin
  if lzmaHandle=0 then  //Dll pas encore chargée
  begin
    lzmaHandle := LoadLibrary(LZMA_DLL);
    Result:=lzmaHandle>=32;
    if Result then
    begin
      plzma_easy_encoder := GetProcAddress(lzmaHandle,'lzma_easy_encoder');
      Assert(plzma_easy_encoder <> nil);
      plzma_stream_decoder := GetProcAddress(lzmaHandle,'lzma_stream_decoder');
      Assert(plzma_stream_decoder <> nil);
      plzma_code := GetProcAddress(lzmaHandle,'lzma_code');
      Assert(plzma_code <> nil);
      plzma_end := GetProcAddress(lzmaHandle,'lzma_end');
      Assert(plzma_end <> nil);
      plzma_easy_buffer_encode := GetProcAddress(lzmaHandle,'lzma_easy_buffer_encode');
      Assert(plzma_easy_buffer_encode <> nil);
      plzma_stream_buffer_decode := GetProcAddress(lzmaHandle,'lzma_stream_buffer_decode');
      Assert(plzma_stream_buffer_decode <> nil);
    end;
  end else result:=true;
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
  if not LoadLzmaDLL then
    raise Exception.CreateFmt('%s not found.',[LZMA_DLL]); //!!
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
  if lzmaHandle>=32 then
  begin
    FreeLibrary(lzmaHandle);
    lzmaHandle:=0;
  end;
  inherited Destroy;
end;


// TXZCompressionStream

constructor TXZCompressionStream.Create(preset:uint32_t; Dest: TStream);
begin
  inherited Create(Dest);
  FXZRec.next_out := FBuffer;
  FXZRec.avail_out := sizeof(FBuffer);
  CCheck(Tf_lzma_easy_encoder(plzma_easy_encoder)(@FXZRec, preset or $80000000, LZMA_CHECK_CRC64));
end;

destructor TXZCompressionStream.Destroy;
begin
  if lzmaHandle>=32 then
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
  DCheck(Tf_lzma_stream_decoder(plzma_stream_decoder)(@FXZRec, high(int64), LZMA_CONCATENATED));
end;

destructor TXZDecompressionStream.Destroy;
begin
  if lzmaHandle>=32 then Tf_lzma_end(plzma_end)(@FXZRec);
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
