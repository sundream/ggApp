#encoding=utf-8
import io
import json
import optparse
import urllib
import httplib
import time
import json

def import_servers(accountcenter,appid,servers_config):
    fp = io.open(servers_config,"rb")
    servers = json.load(fp,encoding="utf-8")
    fp.close()
    url = "http://%s/api/account/server/add" % (accountcenter)
    ok_serverlist = []
    fail_serverlist = []
    for serverid,server in servers.iteritems():
        if type(server["opentime"]) == unicode:
            # convert string to stamptime
            server["opentime"] = time.strptime(server["opentime"],"%Y-%m-%d %H:%M:%S")
            server["opentime"] = int(time.mktime(server["opentime"]))
        assert(type(server["opentime"])==int)
        conn = httplib.HTTPConnection(accountcenter)
        server_json = json.dumps(server)
        query = json.dumps({
            "appid" : appid,
            "sign" : "debug",
            "serverid" : serverid,
            "server" : server_json,
        },encoding="utf-8")
        #request = "%s?%s" % (url,query)
        #conn.request("GET",request)
        conn.request("POST",url,query)
        resp = conn.getresponse()
        if resp.status == 200:
            response = resp.read()
            response = json.loads(response)
            if response.get("code") == 0:
                ok_serverlist.append(serverid)
            else:
                fail_serverlist.append({
                    "serverid" : serverid,
                    "err" : response.get("message"),
                    })
        else:
            fail_serverlist.append({
                "serverid" : serverid,
                "status" : resp.status,
                "err" : resp.read(),
            })

        conn.close()
    return ok_serverlist,fail_serverlist



def main():
    usage = "usage: python %prog [options]\n\te.g: python %prog --appid=appid --config=servers.dev.config"
    parser = optparse.OptionParser(usage=usage,version="%prog 0.0.1")
    parser.add_option("-a","--appid",help="[required] game's appid")
    parser.add_option("-c","--config",help="[required] servers config file")
    parser.add_option("-H","--accountcenter",help="accountcenter's ip:port",default="127.0.0.1:8887")
    parser.add_option("-q","--quite",help="quite mode",action="store_true",default=False)
    options,args = parser.parse_args()
    required = ["appid","config"]
    for r in required:
        if options.__dict__.get(r) is None:
            parser.error("option '%s' required" % r)
    servers_config = options.config
    accountcenter = options.accountcenter
    appid = options.appid
    quite = options.quite
    ok_serverlist,fail_serverlist = import_servers(accountcenter,appid,servers_config)
    if not quite:
        print("op=import_servers,appid=%s,accountcenter=%s" % (appid,accountcenter))
        for serverid in iter(ok_serverlist):
            print("[ok] serverid=%s" % serverid)
        for v in iter(fail_serverlist):
            print("[fail] serverid=%s,status=%s,error=%s" % (v.get("serverid"),v.get("status"),v.get("err")))

if __name__ == "__main__":
    main()
