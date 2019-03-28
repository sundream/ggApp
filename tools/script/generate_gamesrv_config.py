#coding=utf-8
import io
import json
import optparse
import time
import json
import os
import os.path
import string

template = u'''\
include "common.config"
ip = "%(ip)s"
cluster_ip = "%(cluster_ip)s"
cluster_port = %(cluster_port)s
tcp_port = %(tcp_port)s
kcp_port = %(kcp_port)s
websocket_port = %(websocket_port)s
http_port = %(http_port)s
debug_port = %(debug_port)s
appid = "%(appid)s"         -- 项目名
zoneid = "%(zoneid)s"       -- 小区ID
area = "%(area)s"           -- 大区ID
env = "%(env)s"             -- 集群环境,如dev--内网,test--外网测试等等
id = "%(id)s"               -- 服务器ID
name = "%(name)s"           -- 服务器名
index = %(index)s           -- 服务器编号
type = "%(type)s"           -- 服务器类型
opentime = "%(opentime)s"   -- 开服时间
zonename = "%(zonename)s"   -- 小区名
areaname = "%(areaname)s"   -- 大区名
envname = "%(envname)s"     -- 环境名
cluster = src_dir .. "/app/config/nodes.config"
accountcenter = "%(accountcenter)s" \
'''

def writeto(filename,startline,endline,line):
    lines = []
    if os.path.isfile(filename):
        fp = io.open(filename,"rb")
        lines = fp.read().splitlines()
        fp.close()
    startline_pos = -1
    endline_pos = -1
    if startline in lines:
        startline_pos = lines.index(startline)
        if endline in lines[startline_pos+1:]:
            endline_pos = lines.index(endline,startline_pos+1)
    status = ""
    if startline_pos != -1 and endline_pos != -1:
        lines = lines[:startline_pos] + [startline,line,endline] + lines[endline_pos+1:]
        status = "updated"
    else:
        lines = [startline,line,endline]
        status = "new"
    data = string.join(lines,"\n")
    fp = io.open(filename,"wb")
    fp.write(data)
    fp.close()
    return status



def generate_gamesrv_config(out,accountcenter,appid,servers_config):
    fp = io.open(servers_config,"rb")
    servers = json.load(fp,encoding="utf-8")
    fp.close()
    out = os.path.expanduser(out)
    if not os.path.exists(out):
        os.makedirs(out)
    new = {}
    updated = {}
    nodes = []
    startline = "-- auto generate DO NOT EDIT!!!"
    endline = "-- auto generate DO NOT EDIT!!!"
    for serverid,server in servers.iteritems():
        server["id"] = serverid
        server["accountcenter"] = accountcenter
        server["appid"] = appid
        nodes.append('%s = "%s:%s"' % (serverid,server["cluster_ip"],server["cluster_port"]))
        line = template % (server)
        line = line.encode("utf-8")

        filename = os.path.join(out,serverid) + ".config"
        status = writeto(filename,startline,endline,line)
        if status == "updated":
            updated[serverid] = True
        else:
            new[serverid] = True
    filename = "%s/nodes.config" % (out)
    line = string.join(nodes,"\n")
    writeto(filename,startline,endline,line)
    return new,updated

def main():
    usage = "usage: python %prog [options]\n\te.g: python %prog --appid=appid --config=servers.dev.config --out=config"
    parser = optparse.OptionParser(usage=usage,version="%prog 0.0.1")
    parser.add_option("-a","--appid",help="[required] game's appid")
    parser.add_option("-c","--config",help="[required] servers config file")
    parser.add_option("-o","--out",help="[optional] output dirname",default="config")
    parser.add_option("-H","--accountcenter",help="[optional] accountcenter's ip:port",default="127.0.0.1:8887")
    parser.add_option("-q","--quite",help="[optional] quite mode",action="store_true",default=False)
    options,args = parser.parse_args()
    required = ["appid","config"]
    for r in required:
        if options.__dict__.get(r) is None:
            parser.error("option '%s' required" % r)
    out = options.out
    accountcenter = options.accountcenter
    appid = options.appid
    servers_config = options.config
    quite = options.quite
    new,updated = generate_gamesrv_config(out,accountcenter,appid,servers_config)
    if not quite:
        print("op=generate_gamesrv_config,out=%s,appid=%s,accountcenter=%s" % (out,appid,accountcenter))
        for serverid in iter(new):
            print("[new] %s" % serverid)
        for serverid in iter(updated):
            print("[updated] %s" % serverid)

if __name__ == "__main__":
    main()
