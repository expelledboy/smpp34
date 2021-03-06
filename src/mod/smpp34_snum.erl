-module(smpp34_snum).
-include("../util.hrl").
-behaviour(gen_server).

-export([start_link/2,start_link/3,stop/1]).
-export([next/1, ping/1]).

-export([init/1,
        handle_call/3,
        handle_cast/2,
        handle_info/2,
        terminate/2,
        code_change/3]).

-record(st_snum, {owner, count, monitref, log}).

start_link(Owner, Logger) ->
	start_link(Owner, 0, Logger).

start_link(Owner, Start, Logger) ->
    gen_server:start_link(?MODULE, [Owner, Start, Logger], []).

stop(Pid) ->
    gen_server:cast(Pid, stop).

next(Pid) ->
    gen_server:call(Pid, next).

ping(Pid) ->
	gen_server:call(Pid, ping).


init([Owner, Start, Logger]) ->
	process_flag(trap_exit, true),
	MonitorRef = erlang:monitor(process, Owner),
    {ok, #st_snum{owner=Owner, count=Start, monitref=MonitorRef, log=Logger}}.

handle_call(ping, _From, #st_snum{owner=Owner, count=Count}=St) ->
	{reply, {pong, [{owner=Owner}, {count,Count}]}, St};
handle_call(next, _From, #st_snum{count=?SNUM_MAX}=St) ->
    N1 = 1,
    {reply, {ok, N1}, St#st_snum{count=N1}};
handle_call(next, _From, #st_snum{count=N}=St) ->
    N1 = N+1,
    {reply, {ok, N1}, St#st_snum{count=N1}};
handle_call(Req, _From, St) ->
    {reply, {error, Req}, St}.

handle_cast(stop, St) ->
    {stop, normal, St};
handle_cast(_Req, St) ->
    {noreply, St}.

handle_info(#'DOWN'{ref=MonitorRef}, #st_snum{monitref=MonitorRef}=St) ->
	{stop, normal, St};
handle_info(_Req, St) ->
    {noreply, St}.

terminate(_, _) ->
    ok.

code_change(_OldVsn, St, _Extra) ->
    {noreply, St}.
