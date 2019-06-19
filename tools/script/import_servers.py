#encoding=utf-8
import io
import json
import optparse
import urllib
import httplib
import time
import string
import base64
import hmac
from hashlib import sha1

def signature(args,secret):
    # ksort
    arr = []
    for k,v in args.iteritems():
        if str(v) != "":
            arr.append([str(k),str(v)])
    def cmp_by_key(elem1,elem2):
        key1,key2 = elem1[0],elem2[0]
        if key1 == key2:
            return 0
        elif key1 < key2:
            return -1
        else:
            return 1
    arr.sort(cmp_by_key)
    strs = []
    for elem in arr:
        strs.append("%s=%s" % (elem[0],elem[1]))
    raw = string.join(strs,"&")
    hmac_code = hmac.new(secret.encode(),raw.encode(),sha1).digest()
    return base64.b64encode(hmac_code).decode()

def import_servers(loginserver,appid,secret,servers_config):
    fp = io.open(servers_config,"rb")
    servers = json.load(fp,encoding="utf-8")
    fp.close()
    url = "http://%s/api/account/server/add" % (loginserver)
    ok_serverlist = []
    fail_serverlist = []
    for serverid,server in servers.iteritems():
        if type(server["opentime"]) == unicode:
            # convert string to stamptime
            server["opentime"] = time.strptime(server["opentime"],"%Y-%m-%d %H:%M:%S")
            server["opentime"] = int(time.mktime(server["opentime"]))
        assert(type(server["opentime"])==int)
        conn = httplib.HTTPConnection(loginserver)
        server_json = json.dumps(server)
        args = {
            "appid" : appid,
            "serverid" : serverid,
            "server" : server_json,
        }
        args["sign"] = signature(args,secret)
        query = json.dumps(args,encoding="utf-8")
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
    usage = "usage: python %prog [options]\n\te.g: python %prog --appid=appid --config=servers.dev.config [--loginserver=ip:port]"
    parser = optparse.OptionParser(usage=usage,version="%prog 0.0.1")
    parser.add_option("-a","--appid",help="[required] game's appid")
    parser.add_option("-c","--config",help="[required] servers config file")
    parser.add_option("-H","--loginserver",help="loginserver's ip:port",default="127.0.0.1:8885")
    parser.add_option("-s","--secret",help="signature secret",default="secret")
    parser.add_option("-q","--quite",help="quite mode",action="store_true",default=False)
    options,args = parser.parse_args()
    required = ["appid","config"]
    for r in required:
        if options.__dict__.get(r) is None:
            parser.error("option '%s' required" % r)
    servers_config = options.config
    loginserver = options.loginserver
    appid = options.appid
    secret = options.secret
    quite = options.quite
    ok_serverlist,fail_serverlist = import_servers(loginserver,appid,secret,servers_config)
    if not quite:
        print("op=import_servers,appid=%s,loginserver=%s" % (appid,loginserver))
        for serverid in iter(ok_serverlist):
            print("[ok] serverid=%s" % serverid)
        for v in iter(fail_serverlist):
            print("[fail] serverid=%s,status=%s,error=%s" % (v.get("serverid"),v.get("status"),v.get("err")))

if __name__ == "__main__":
    main()
