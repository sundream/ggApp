
o
common.proto"W
MessageHeader
type (Rtype
session (Rsession
request (Rrequestbproto3
 

login.proto"u
C2GS_CheckToken
token (	Rtoken
account (	Raccount
version (	Rversion
forward (	Rforward"•
C2GS_CreateRole
roleid (Rroleid
account (	Raccount
name (	Rname
job (Rjob
sex (Rsex
shapeid (Rshapeid"(
C2GS_EnterGame
roleid (Rroleid"
C2GS_ExitGame"
	C2GS_Ping
str (	Rstr"ð
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
account (	Raccount"Î
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