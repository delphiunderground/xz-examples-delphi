(*
 * liblzma Data Compression Interface Unit
 * Copyright (C) 2016-2021 Vincent Hardy <vincent.hardy@linuxunderground.be>
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

unit LibLZMA;

interface

type
  uint8_t = Byte;
  uint32_t = Cardinal;
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
  lzma_mode = integer;
  lzma_match_finder = integer;
  lzma_vli = uint64_t;

{*
 * Options specific to the LZMA1 and LZMA2 filters
 *
 * see also :
 * lzma/lzma12.h (src/liblzma/api/lzma/lzma12.h in the source package
 * or e.g. c:\xz\include\lzma\lzma12.h depending on the install prefix).
 *
 * Since LZMA1 and LZMA2 share most of the code, it's simplest to share
 * the options structure too. For encoding, all but the reserved variables
 * need to be initialized unless specifically mentioned otherwise.
 * lzma_lzma_preset() can be used to get a good starting point.
 *
 * For raw decoding, both LZMA1 and LZMA2 need dict_size, preset_dict, and
 * preset_dict_size (if preset_dict != NULL). LZMA1 needs also lc, lp, and pb.
 *}
  lzma_options_lzma = record
    dict_size: uint32_t;
    preset_dict: pointer;
    preset_dict_size: uint32_t;
    lc: uint32_t;
    lp: uint32_t;
    pb: uint32_t;
    mode: lzma_mode;
    nice_len: uint32_t;
    mf: lzma_match_finder;
    depth: uint32_t;
    reserved_int1: uint32_t;
    reserved_int2: uint32_t;
    reserved_int3: uint32_t;
    reserved_int4: uint32_t;
    reserved_int5: uint32_t;
    reserved_int6: uint32_t;
    reserved_int7: uint32_t;
    reserved_int8: uint32_t;
    reserved_enum1: lzma_reserved_enum;
    reserved_enum2: lzma_reserved_enum;
    reserved_enum3: lzma_reserved_enum;
    reserved_enum4: lzma_reserved_enum;
    reserved_ptr1: pointer;
    reserved_ptr2: pointer;
  end;

{*
 * Filter options
 *
 * see also :
 * lzma/filter.h (src/liblzma/api/lzma/filter.h in the source package
 * or e.g. c:\xz\include\lzma\filter.h depending on the install prefix).
 *}
  lzma_filter = record
    id : lzma_vli;
    options : pointer;
  end;

{*
 * Multithreading options
 *
 * see also :
 * lzma/container.h (src/liblzma/api/lzma/container.h in the source package
 * or e.g. c:\xz\include\lzma\container.h depending on the install prefix).
 *}
  lzma_mt =  record
    flags : uint32_t;
    threads : uint32_t;
    block_size : uint64_t;
    timeout : uint32_t;
    preset : uint32_t;
    filters : ^lzma_filter;
    check : lzma_check;
    reserved_enum1 : lzma_reserved_enum;
    reserved_enum2 : lzma_reserved_enum;
    reserved_enum3 : lzma_reserved_enum;
    reserved_int1 : uint32_t;
    reserved_int2 : uint32_t;
    reserved_int3 : uint32_t;
    reserved_int4 : uint32_t;
    reserved_int5 : uint64_t;
    reserved_int6 : uint64_t;
    reserved_int7 : uint64_t;
    reserved_int8 : uint64_t;
    reserved_ptr1 : pointer;
    reserved_ptr2 : pointer;
    reserved_ptr3 : pointer;
    reserved_ptr4 : pointer;
  end;

{*
 * Custom functions for memory handling.
 * See also :
 * lzma/base.h (src/liblzma/api/lzma/base.h in the source package
 * or e.g. c:\xz\include\lzma\base.h depending on the install prefix).
 *}
  TAlloc = function(opaque: Pointer; Items, Size: size_t): Pointer; cdecl;
  TFree = procedure(opaque, Block: Pointer); cdecl;

  lzma_allocator = record
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
  lzma_stream = record
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
 * Initialize .xz easy and stream encoder using a preset number.
 * See also :
 * lzma/container.h (src/liblzma/api/lzma/container.h in the source package
 * or e.g. c:\xz\include\lzma\container.h depending on the install prefix).
 *}
  Tf_lzma_easy_encoder = function(
    strm: p_lzma_stream;
    preset: uint32_t;    //Compression preset to use.
    check: lzma_check    //Type of the integrity check to calculate from uncompressed data.
    ): lzma_ret; cdecl;

  Tf_lzma_stream_encoder = function(
    strm: p_lzma_stream;
    filters: pointer;    //^lzma_filter;
    check: lzma_check
    ): lzma_ret; cdecl;

  TF_lzma_stream_encoder_mt = function(
    strm: p_lzma_stream;
    options: pointer    //^lzma_mt
    ): lzma_ret; cdecl;

{*
 * Set a compression preset to lzma_options_lzma structure
 *
 * See also :
 * lzma/container.h (src/liblzma/api/lzma/container.h in the source package
 * or e.g. c:\xz\include\lzma\container.h depending on the install prefix).
 *}

  Tf_lzma_lzma_preset = function(
    options: pointer;
    preset: uint32_t
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

  tf_lzma_cputhreads = function: uint32_t; cdecl;


const
{*
 * Limits specific to the LZMA1 and LZMA2 filters
 * See lzma/lzma12.h
 * (src/liblzma/api/lzma/lzma12.h in the source package or e.g.
 *  c:\xz\include\lzma\lzma12.h depending on the install prefix).
 *}
  LZMA_MODE_FAST = 1;
  LZMA_MODE_NORMAL = 2;
  LZMA_DICT_SIZE_MIN = uint32_t(4096);
  LZMA_DICT_SIZE_DEFAULT = uint32_t(1 shl 23);
  LZMA_LCLP_MIN = 0;
  LZMA_LCLP_MAX = 4;
  LZMA_LC_DEFAULT = 3;
  LZMA_LP_DEFAULT = 0;
  LZMA_PB_MIN = 0;
  LZMA_PB_MAX = 4;
  LZMA_PB_DEFAULT = 2;
  LZMA_MF_HC3 = $03;
  LZMA_MF_HC4 = $04;
  LZMA_MF_BT2 = $12;
  LZMA_MF_BT3 = $13;
  LZMA_MF_BT4 = $14;

{*
 * Filter IDs for lzma_filter.id
 * see lzma/bcj.h
 * (src/liblzma/api/lzma/bsj.h in the source package or e.g.
 *  c:\xz\include\lzma\bcj.h depending on the install prefix).
 *}
  LZMA_FILTER_X86 = $04;
  LZMA_FILTER_POWERPC = $05;
  LZMA_FILTER_IA64 = $06;
  LZMA_FILTER_ARM = $07;
  LZMA_FILTER_ARMTHUMB = $08;
  LZMA_FILTER_SPARC = $09;
{*
 * see lzma/lzma12.h
 *}
  LZMA_FILTER_LZMA1 = lzma_vli($4000000000000001);
  LZMA_FILTER_LZMA2 = lzma_vli($21);

{*
 * See lzma/container.h
 * (src/liblzma/api/lzma/container.h in the source package or e.g.
 *  c:\xz\include\lzma\container.h depending on the install prefix).
 *
 * Default compression preset
 *}
  LZMA_PRESET_DEFAULT = uint32_t(6);

{*
 * Preset flags
 *
 * These values are documented in lzma/container.h
 * (src/liblzma/api/lzma/container.h in the source package or e.g.
 *  c:\xz\include\lzma\container.h depending on the install prefix).
 *}

{*
 * Extreme compression preset
 *
 * This flag modifies the preset to make the encoding significantly slower
 * while improving the compression ratio only marginally. This is useful
 * when you don't mind wasting time to get as small result as possible.
 *
 * This flag doesn't affect the memory usage requirements of the decoder (at
 * least not significantly). The memory usage of the encoder may be increased
 * a little but only at the lowest preset levels (0-3).
 *}
  LZMA_PRESET_EXTREME = uint32_t(1 shl 31);

{*
 * Return values used by several functions in liblzma
 * These values are documented in lzma/base.h
 * (src/liblzma/api/lzma/base.h in the source package or e.g.
 * c:\xz\include\lzma\base.h depending on the install prefix).
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

  // VLI value to denote that the value is unknown
  LZMA_VLI_UNKNOWN = Int64(-1);      // = high(uint64_t);

{*
 * Decoding
 *}
  LZMA_CONCATENATED = $08;


  LZMA_DLL = 'liblzma.dll';  //-> https://tukaani.org/xz/xz-5.2.5-windows.zip

var
  plzma_easy_encoder:pointer;          //-> Tf_lzma_easy_encoder
  plzma_stream_encoder:pointer;        //-> Tf_lzma_stream_encoder
  plzma_stream_encoder_mt:pointer;     //-> Tf_lzma_stream_encoder_mt
  plzma_lzma_preset:pointer;           //-> Tf_lzma_lzma_preset
  plzma_stream_decoder:pointer;        //-> Tf_lzma_stream_decoder
  plzma_code:pointer;                  //-> Tf_lzma_code
  plzma_end:pointer;                   //-> Tf_lzma_end

  plzma_easy_buffer_encode:pointer;    //-> Tf_lzma_easy_buffer_encode
  plzma_stream_buffer_decode:pointer;  //-> Tf_lzma_stream_buffer_decode

  plzma_cputhreads:pointer;            //-> Tf_lzma_cputhreads

function LoadLZMADLL:boolean;
procedure UnloadLZMADLL;

implementation

uses
  Windows;

var
  lzmaHandle:THandle=0;

function LoadLZMADLL:boolean;
begin
  if lzmaHandle=0 then  //Dll pas encore chargée
  begin
    lzmaHandle := LoadLibrary(LZMA_DLL);
    Result:=lzmaHandle>=32;
    if Result then
    begin
      plzma_lzma_preset := GetProcAddress(lzmaHandle,'lzma_lzma_preset');
      Assert(plzma_lzma_preset <> nil);
      plzma_easy_encoder := GetProcAddress(lzmaHandle,'lzma_easy_encoder');
      Assert(plzma_easy_encoder <> nil);
      plzma_stream_encoder := GetProcAddress(lzmaHandle,'lzma_stream_encoder');
      assert(plzma_stream_encoder <> nil);
      plzma_stream_encoder_mt := GetProcAddress(lzmaHandle,'lzma_stream_encoder_mt');
      assert(plzma_stream_encoder_mt <> nil);
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
      plzma_cputhreads := GetProcAddress(lzmaHandle,'lzma_cputhreads');
      Assert(plzma_cputhreads <> nil);
    end;
  end else result:=true;
end;

procedure UnLoadLZMADLL;
begin
  if lzmaHandle>=32 then
  begin
    FreeLibrary(lzmaHandle);
    lzmaHandle:=0;
  end;
end;

end.
