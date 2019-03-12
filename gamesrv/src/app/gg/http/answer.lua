local Answer = {
	code = {},
	message = {},
}

function Answer.response(code)
	assert(code)
	return {
		code = code,
		message = Answer.message[code],
	}
end

local function _(name,code,message)
	Answer.code[name] = code
	Answer.message[code] = message
end


_("OK",0,"OK")
-- 基本错误[-10000,-20000)
_("APPID_NOEXIST",-10001,"APPID不存在")
_("SIGN_ERR",-10002,"签名错误")
_("TOO_BUSY",-10003,"服务器繁忙")
_("PARAM_ERR",-10004,"参数错误")
_("FAIL",-10005,"执行失败")

-- 账号中心错误[-20000,-30000)
_("PASSWD_NOMATCH",-20001,"密码不匹配")
_("ACCT_FMT_ERR",-20002,"帐号格式错误")
_("NAME_ERR",-20003,"名字非法")
_("ACCT_EXIST",-20004,"帐号已存在")
_("ACCT_NOEXIST",-20005,"帐号不存在")
_("ROLE_EXIST",-20006,"角色已存在")
_("ROLE_NOEXIST",-20007,"角色不存在")
_("NAME_EXIST",-20008,"重名")
_("ROLETYPE_ERR",-20009,"角色类型非法")
_("REPEAT_LOGIN",-20010,"重复登录")
_("ROLE_OVERLIMIT",-20011,"本服角色数量已达上限")
_("PASSWD_FMT_ERR",-20012,"密码格式错误")
_("PLATFORM_UNAUTH",-20013,"平台认证失败")
_("BAN_ACCT",-20014,"帐号黑名单")
_("BAN_IP",-20015,"IP黑名单")
_("SERVER_REDIRECT",-20016,"重定向服务器")
_("CHANNEL_ERR",-20017,"渠道错误")
_("BAN_ROLE",-20018,"角色黑名单")
_("SEX_ERR",-20019,"性别非法")
_("TOKEN_TIMEOUT",-20020,"TOKEN超时")
_("LOW_VERSION",-20021,"版本过低")
_("CLOSE_CREATEROLE",-20022,"服务器禁止注册角色")
_("ROLE_TOO_MUCH",-20023,"角色数已达上限")
_("ROLE_FMT_ERR",-20024,"角色格式错误")
_("TOKEN_UNAUTH",-20025,"TOKEN认证失败")
_("SERVER_FMT_ERR",-20026,"服务器格式错误")
_("SERVER_NOEXIST",-20027,"服务器不存在")
_("PLEASE_LOGIN_FIRST",-20028,"请先登录")
_("REPEAT_ENTERGAME",-20029,"重复进入游戏")
_("REPEAT_NAME",-20030,"名字重复")
_("INVALID_NAME",-20031,"非法名字")
_("CLOSE_ENTERGAME",-20032,"服务器尚未开放")
_("SDK_NOEXIST",-20033,"SDK不存在")
_("PLATFORM_NOEXIST",-20034,"平台不存在")
_("UNSUPPORT_PLATFORM",-20035,"不支持的平台")
_("TIMEOUT",-20036,"超时")
_("UNSUPPORT_SDK",-20037,"不支持的SDK")

-- 图片服务器错误[-30000,-40000)
_("IMAGE_NOEXIST",-30000,"图片不存在")
_("IMAGE_UPLOAD_SIZE_TOO_BIG",-30001,"上传图片尺寸过大")

_("IMAGE_UPLOAD_ERR",-30002,"图片上传错误")
_("PHOTO_NOEXIST",-30003,"头像不存在")

return Answer
