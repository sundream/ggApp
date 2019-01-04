import io
import json
import optparse
import urllib
import httplib
import time

def import_servers(host,appid,servers_config):
    fp = io.open(servers_config,"rb")
    servers = json.load(fp)
    fp.close()
    url = "http://%s/api/account/server/add" % (host)
    ok_serverlist = []
    fail_serverlist = []
    for serverid,server in servers.iteritems():
        if type(server["opentime"]) == unicode:
            # convert string to stamptime
            server["opentime"] = time.strptime(server["opentime"],"%Y-%m-%d %H:%M:%S")
            server["opentime"] = int(time.mktime(server["opentime"]))
        assert(type(server["opentime"])==int)
        server_json = json.dumps(server)
        conn = httplib.HTTPConnection(host)
        query = urllib.urlencode({
            "appid" : appid,
            "sign" : "debug",
            "serverid" : serverid,
            "server" : server_json,
        })
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
    usage = "usage: python %prog [options]\n\te.g: python %prog --appid=appid --config=servers.config"
    parser = optparse.OptionParser(usage=usage,version="%prog 0.0.1")
    parser.add_option("-a","--appid",help="[required] game's appid")
    parser.add_option("-c","--config",help="[required] servers config file")
    parser.add_option("-H","--host",help="server's host:port",default="127.0.0.1:8887")
    parser.add_option("-q","--quite",help="quite mode",action="store_true",default=False)
    options,args = parser.parse_args()
    required = ["appid","config"]
    for r in required:
        if options.__dict__.get(r) is None:
            parser.error("option '%s' required" % r)
    servers_config = options.config
    host = options.host
    appid = options.appid
    quite = options.quite
    ok_serverlist,fail_serverlist = import_servers(host,appid,servers_config)
    if not quite:
        print("import_servers to %s:" % appid)
        for serverid in iter(ok_serverlist):
            print("[ok] %s" % serverid)
        for v in iter(fail_serverlist):
            print("[fail] %s,error: %s" % (v.get("serverid"),v.get("err")))

if __name__ == "__main__":
    main()
