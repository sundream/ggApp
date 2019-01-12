

common.proto"g
MessageHeader
type (Rtype
session (Rsession
ud (Rud
request (Rrequestbproto3
î

login.proto"o
C2GS_CheckToken
token (	Rtoken
acct (	Racct
version (	Rversion
forward (	Rforward"è
C2GS_CreateRole
roleid (Rroleid
acct (	Racct
name (	Rname
job (Rjob
sex (Rsex
shapeid (Rshapeid"(
C2GS_EnterGame
roleid (Rroleid"
C2GS_ExitGame"
	C2GS_Ping
str (	Rstr"
RoleType
roleid (Rroleid
name (	Rname
job (Rjob
sex (Rsex
shapeid (Rshapeid
lv (Rlv'
create_serverid (	RcreateServerid!
now_serverid (	RnowServerid

createtime	 (R
createtime"w
GS2C_CheckTokenResult
status (Rstatus
code (Rcode
message (	Rmessage
forward (	Rforward"|
GS2C_CreateRoleResult
status (Rstatus
code (Rcode
message (	Rmessage
role (2	.RoleTypeRrole"v
GS2C_EnterGameResult
status (Rstatus
code (Rcode
message (	Rmessage
account (	Raccount"Œ
GS2C_ReEnterGame
token (	Rtoken
roleid (Rroleid
go_serverid (	R
goServerid
ip (	Rip
tcp_port (RtcpPort
kcp_port (RkcpPort%
websocket_port (RwebsocketPort"#
	GS2C_Kick
reason (	Rreason"1
	GS2C_Pong
str (	Rstr
time (Rtime"
GS2C_EnterGameStartbproto3