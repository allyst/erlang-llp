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

-define(LLP_PROTO_MAGIC, 2#110).
-define(LLP_PROTO_V1, 1).
-define(LLP_PROTO_MAXFRAMESIZE, (1 bsl 10) * 48).

-define(LLP_CHANNEL_CONTROL, 0).
-define(LLP_CHANNEL_PEERING, 1).
-define(LLP_CHANNEL_FEDERATION, 2).
-define(LLP_CHANNEL_DATA, 7).

-define(LLP_PACKET_REQ, 0).
-define(LLP_PACKET_RESP, 1).
-define(LLP_PACKET_RESP_REQ, 2).

-define(LLP_PACKET_REJ, 28).
-define(LLP_PACKET_REJ_REQ, 29).
-define(LLP_PACKET_ERR, 30).
-define(LLP_PACKET_ERR_REQ, 31).

-define(LLP_FRAME_PART, 0).
-define(LLP_FRAME_START, 2).
-define(LLP_FRAME_STOP, 1).
-define(LLP_FRAME_ENTIRE, 3).

-define(LLP_RESERVED, 0).

% Proto error codes
-define (LLP_ERR_SYNC, 196).

%%
%% Control channel Spec header
%%
%% Announce
-define(LLP_ANNOUNCE_CONTROL_COMMAND,         0).
-define(LLP_ANNOUNCE_INIT_CONTROL_COMMAND,    0).
-define(LLP_ANNOUNCE_RESTORE_CONTROL_COMMAND, 1).
-define(LLP_ANNOUNCE_UPDATE_CONTROL_COMMAND,  2).
-define(LLP_ANNOUNCE_REMOVE_CONTROL_COMMAND,  3).
%% Start
-define(LLP_START_CONTROL_COMMAND,        1).
-define(LLP_START_STRICT_CONTROL_COMMAND, 0).
-define(LLP_START_NORMAL_CONTROL_COMMAND, 1).
%% Stop
-define(LLP_STOP_CONTROL_COMMAND,      2).
-define(LLP_STOP_SOFT_CONTROL_COMMAND, 0).
-define(LLP_STOP_HARD_CONTROL_COMMAND, 1).
%% Pause
-define(LLP_PAUSE_CONTROL_COMMAND, 3).
%% Block
-define(LLP_BLOCK_CONTROL_COMMAND, 4).
%% Status
-define(LLP_STATUS_CONTROL_COMMAND, 5).
%% Sysinfo
-define(LLP_SYSINFO_CONTROL_COMMAND, 6).
%% Set
-define(LLP_SET_CONTROL_COMMAND, 7).
%% Get
-define(LLP_GET_CONTROL_COMMAND, 8).
%% Redirect
-define(LLP_REDIRECT_CONTROL_COMMAND, 9).
%% Restart
-define(LLP_RESTART_CONTROL_COMMAND, 10).
%% Reset
-define(LLP_RESET_CONTROL_COMMAND, 11).
%% Redirect2
-define(LLP_REDIRECT2_CONTROL_COMMAND, 12).
%% Debug
-define(LLP_DEBUG_CONTROL_COMMAND, 13).

%%
%% Data channel Spec header
%%
%% Announce
-define(LLP_ANNOUNCE_DATA_COMMAND, 0).
-define(LLP_ANNOUNCE_INIT_DATA_COMMAND, 0).
-define(LLP_ANNOUNCE_RESTORE_DATA_COMMAND, 1).
%% Request
-define(LLP_REQUEST_DATA_COMMAND, 1).
%% Response
-define(LLP_RESPONSE_DATA_COMMAND, 2).
-define(LLP_DEFAULT_DATA_SUBCOMMAND, 0).

%%
%% Error codes and status codes
%%
-define(LLP_ERROR_REQUEST_WITHOUT_SERVER, 199).
-define(LLP_ERROR_DESTINATION_HOST_UNREACHABLE, 200).

-define(LLP_STATUS_REQUEST_SUCCESS, 0).

-define(LLSP_MAGIC_NUMBER, 1634495609).
-define(LLSP_VSN_1, 1).


-record(base_header_v1, {
            channel_type     :: non_neg_integer(),
            packet_type      :: non_neg_integer(),
            flags            :: binary(),
            frame_number     :: non_neg_integer(),
            sequence         :: non_neg_integer(),
            from_platform_id :: non_neg_integer(),
            from_node_id     :: non_neg_integer(),
            from_scheme_id   :: non_neg_integer(),
            spec_header_size :: non_neg_integer(),
            payload_size     :: non_neg_integer()
        }).

-record(data_request_spec_header_v1, {
            command          :: non_neg_integer(),
            subcomand        :: non_neg_integer(),
            platform_id      :: non_neg_integer(),
            node_id          :: non_neg_integer(),
            scheme_id        :: non_neg_integer(),
            interface_id     :: non_neg_integer()
        }).

-record(data_response_spec_header_v1, {
            code             :: non_neg_integer(),
            platform_id      :: non_neg_integer(),
            node_id          :: non_neg_integer(),
            scheme_id        :: non_neg_integer(),
            request_sequence :: non_neg_integer()
        }).


-record(control_request_spec_header_v1, {
            command          :: non_neg_integer(),
            subcomand        :: non_neg_integer()
        }).

-record(control_response_spec_header_v1, {
            code             :: non_neg_integer(),
            request_sequence :: non_neg_integer()
        }).

-record(flags_v1, {
        is_start             :: non_neg_integer(),
        is_last              :: non_neg_integer(),
        ttl                  :: non_neg_integer()
    }).
