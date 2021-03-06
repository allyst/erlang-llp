%% Erlang support for LLP - Allyst's data interchange protocol.
%% LLP specification http://allyst.org/opensource/llp/
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 3 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU Library General Public License for more details.
%%
%% Full license: https://github.com/allyst/erlang-llp/blob/master/LICENSE
%%
%% copyright (C) 2014 Allyst Inc. http://allyst.com
%% author Taras Halturin <halturin@allyst.com>

-module(llp).

-export ([decode/2]).

-export([base_header/1, data_channel_req_spec_header/1, data_channel_resp_spec_header/1,
         control_request_spec_header/1, control_response_spec_header/1, flags/1,
         control_pack_request/4, control_pack_response/4, data_pack_request/4, data_pack_response/4]).

-include_lib("llp/include/llp.hrl").
-include_lib("llsn/include/llsn.hrl").
-include_lib("common/include/log.hrl").

% PROTO VERSION 1
decode( <<?LLP_PROTO_MAGIC:3/big-unsigned-integer,
          ?LLP_PROTO_V1:5/big-unsigned-integer,
          Packet/binary>>, Link ) ->
    ?DBG("============= >>> LLPv1 received chunk: ~p bytes",  [byte_size(Packet)]),
    case decode_frame(?LLP_PROTO_V1, Packet, Link) of
        {rest, Rest} -> decode(Rest, Link);
        Result       -> Result
    end.

decode_frame(?LLP_PROTO_V1 = ProtoVsn,
             <<
                ChannelType:3/big-unsigned-integer,
                PacketType:5/big-unsigned-integer,
                FrameLength:16/big-unsigned-integer,
                IsStartFrame:1/big-unsigned-integer,
                IsLastFrame:1/big-unsigned-integer,
                Ttl:5/big-unsigned-integer,
                _Reserved:1/big-unsigned-integer,
                PacketA/binary
             >>, Link) ->

    {FrameNumber,     PacketB} = llsn:decode_UNUMBER(PacketA),
    {Seq,             PacketC} = llsn:decode_UNUMBER(PacketB),
    {FromPlatformId,  PacketD} = llsn:decode_UNUMBER(PacketC),
    {FromLocalNodeId, PacketE} = llsn:decode_UNUMBER(PacketD),
    {FromSchemeId,    Packet}  = llsn:decode_UNUMBER(PacketE),

    ?DBG("ChannelType: ~p~n",    [ChannelType]),
    ?DBG("PacketType: ~p~n",     [PacketType]),
    ?DBG("FrameNumber: ~p~n",    [FrameNumber]),
    ?DBG("FrameLength: ~p~n",    [FrameLength]),
    ?DBG("Seq: ~p~n",            [Seq]),
    ?DBG("FromPlatformId: ~p~n", [FromPlatformId]),
    ?DBG("FromLocalNodeId: ~p~n",[FromLocalNodeId]),
    ?DBG("FromSchemeId: ~p~n",   [FromSchemeId]),

    TailBytes = FrameLength - byte_size(Packet),

    case TailBytes > 0 of
        true ->
            {tail, TailBytes};
        false ->
            case TailBytes < 0 of
                true ->
                    <<Frame:FrameLength/binary-unit:8, Rest/binary>> = Packet,
                    Result = {rest, Rest};
                false ->
                    Frame = Packet,
                    Result = ok
            end,
            gen_server:call(Link#link.channel_handler_pid,
                            #llp_raw_request{
                                vsn              = ProtoVsn,
                                channeltype      = ChannelType,
                                packettype       = PacketType,
                                flags            = {IsStartFrame, IsLastFrame, Ttl},
                                frame_number     = FrameNumber,
                                seq              = Seq,
                                from_platform_id = FromPlatformId,
                                from_node_id     = FromLocalNodeId,
                                from_scheme_id   = FromSchemeId,
                                frame            = Frame,
                                link             = Link
                            }),

            Result
    end;

decode_frame(?LLP_PROTO_V1 = ProtoVsn, Packet, Link) ->
    {header, <<?LLP_PROTO_MAGIC:3/big-unsigned-integer,
               ?LLP_PROTO_V1:5/big-unsigned-integer,
               Packet/binary>>}.


control_pack_request(#base_header_v1{} = BaseHeaderDeclaration,
                     #control_request_spec_header_v1{} = SpecHeaderDeclaration,
                     Payload,
                     IsFirstFrame) ->
    pack(BaseHeaderDeclaration, {control_request_spec_header, SpecHeaderDeclaration}, Payload, IsFirstFrame).

control_pack_response(#base_header_v1{} = BaseHeaderDeclaration,
                      #control_response_spec_header_v1{} = SpecHeaderDeclaration,
                      Payload,
                      IsFirstFrame) ->
    pack(BaseHeaderDeclaration, {control_response_spec_header, SpecHeaderDeclaration}, Payload, IsFirstFrame).

data_pack_request(#base_header_v1{} = BaseHeaderDeclaration,
                  #data_request_spec_header_v1{} = SpecHeaderDeclaration,
                  Payload,
                  IsFirstFrame) ->
    pack(BaseHeaderDeclaration, {data_channel_req_spec_header, SpecHeaderDeclaration}, Payload, IsFirstFrame).

data_pack_response(#base_header_v1{} = BaseHeaderDeclaration,
                   #data_response_spec_header_v1{} = SpecHeaderDeclaration,
                   Payload,
                   IsFirstFrame) ->
    pack(BaseHeaderDeclaration, {data_channel_resp_spec_header, SpecHeaderDeclaration}, Payload, IsFirstFrame).

pack(BaseHeaderDeclaration, {SpecFun, SpecHeaderDeclaration}, Payload, IsFirstFrame) ->
    SpecHeader = case IsFirstFrame of
                    _ when true =:= IsFirstFrame; 1 =:= IsFirstFrame ->
                      ?MODULE:SpecFun(SpecHeaderDeclaration);
                    _ ->
                      <<>>
                 end,
    BaseHeader = base_header(BaseHeaderDeclaration#base_header_v1{
                                  spec_header_size = byte_size(SpecHeader),
                                  payload_size     = byte_size(Payload)
                             }),
    <<BaseHeader/binary, SpecHeader/binary, Payload/binary>>.


base_header(#base_header_v1{channel_type     = ChannelType,
                            packet_type      = PackType,
                            flags            = Flags,
                            frame_number     = FrameNumber,
                            sequence         = Sequence,
                            from_platform_id = FromPlatformId,
                            from_node_id     = FromNodeId,
                            from_scheme_id   = FromSchemeId,
                            spec_header_size = SpecHeaderByteSize,
                            payload_size     = PayloadByteSize}) ->

    {FrameNumberBin, _}    = llsn:encode_UNUMBER(FrameNumber),
    {SeqBin, _}            = llsn:encode_UNUMBER(Sequence),
    {FromPlatformIdBin, _} = llsn:encode_UNUMBER(FromPlatformId),
    {FromNodeIdBin, _}     = llsn:encode_UNUMBER(FromNodeId),
    {FromSchemeIdBin, _}   = llsn:encode_UNUMBER(FromSchemeId),

    FrameLength = <<(PayloadByteSize + SpecHeaderByteSize):16/big-unsigned-integer>>,
    ProtoMagic  = ?LLP_PROTO_MAGIC,
    ProtoVsn    = ?LLP_PROTO_V1,

    <<ProtoMagic:3/big-unsigned-integer,
      ProtoVsn:5/big-unsigned-integer,
      ChannelType:3/big-unsigned-integer,
      PackType:5/big-unsigned-integer,
      FrameLength/binary,
      Flags/binary,
      FrameNumberBin/binary,
      SeqBin/binary,
      FromPlatformIdBin/binary,
      FromNodeIdBin/binary,
      FromSchemeIdBin/binary>>.


flags(#flags_v1{is_start = IsStartFrame,
                is_last  = IsLastFrame,
                ttl      = Ttl}) ->
    <<IsStartFrame:1/big-unsigned-integer,
      IsLastFrame:1/big-unsigned-integer,
      (Ttl-1):5/big-unsigned-integer,
      0:1/big-unsigned-integer>>.


data_channel_req_spec_header(#data_request_spec_header_v1{command      = Command,
                                                          subcomand    = SubCommand,
                                                          platform_id  = PlatformId,
                                                          node_id      = NodeId,
                                                          scheme_id    = SchemeId,
                                                          interface_id = InterfaceId}) ->

    {PlatformIdBin, _}  = llsn:encode_UNUMBER(PlatformId),
    {NodeIdBin, _}      = llsn:encode_UNUMBER(NodeId),
    {SchemeIdBin, _}    = llsn:encode_UNUMBER(SchemeId),
    {InterfaceIdBin, _} = llsn:encode_UNUMBER(InterfaceId),

    <<Command:5/big-unsigned-integer,
      SubCommand:3/big-unsigned-integer,
      PlatformIdBin/binary,
      NodeIdBin/binary,
      SchemeIdBin/binary,
      InterfaceIdBin/binary>>.


data_channel_resp_spec_header(#data_response_spec_header_v1{code             = Code,
                                                            platform_id      = PlatformId,
                                                            node_id          = NodeId,
                                                            scheme_id        = SchemeId,
                                                            request_sequence = ReqSeq}) ->

    {PlatformIdBin, _} = llsn:encode_UNUMBER(PlatformId),
    {NodeIdBin, _}     = llsn:encode_UNUMBER(NodeId),
    {SchemeIdBin, _}   = llsn:encode_UNUMBER(SchemeId),
    {ReqSeqBin, _}     = llsn:encode_UNUMBER(ReqSeq),

    <<Code:8/big-unsigned-integer,
      PlatformIdBin/binary,
      NodeIdBin/binary,
      SchemeIdBin/binary,
      ReqSeqBin/binary>>.

control_request_spec_header(#control_request_spec_header_v1{command   = Command,
                                                            subcomand = SubCommand}) ->
    <<Command:5/big-unsigned-integer,
      SubCommand:3/big-unsigned-integer>>.


control_response_spec_header(#control_response_spec_header_v1{code             = Code,
                                                              request_sequence = ReqSeq}) ->
    {ReqSeqBin, _}     = llsn:encode_UNUMBER(ReqSeq),
    <<Code:8/big-unsigned-integer,
      ReqSeqBin/binary>>.
