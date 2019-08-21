## [0.3.0] - 2019/08/21 ~ ?
* author=sundream,date=2019/08/21,app=client,desc=增加loginserver的appkey
* author=sundream,date=2019/08/21,app=gg,desc=gate握手后通知watchdog
* author=sundream,date=2019/08/21,app=gameserver|loginserver,desc=0.3.0版本重构,封装actor,提供client/cluster/internal/gm组件,分别处理客户端/集群/actor之间通信/gm消息
* author=sundream,date=2019/08/21,app=gameserver|loginserver,desc=之前的单例对象，如playermgr/timectrl等改成class实现,并将单例挂在gg对象上
* author=sundream,date=2019/08/21,app=gameserver,desc=增加复制角色、删除角色、恢复角色、角色换绑服务器、角色换绑账号等支持
