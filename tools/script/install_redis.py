#coding: utf8

import sys
import io
import optparse
import os
import json
import string

def has_install_version(version):
   cmd = "redis-server -v"
   fd = os.popen(cmd)
   line = fd.read()
   fd.close()
   if line.find("v="+version) >= 0:
       return True
   else:
       return False

def install(download_url,install_path):
    install_path = os.path.abspath(install_path)
    program = os.path.basename(download_url)
    # a-b-c.tar.gz
    ext = ".tar.gz"
    program = program.replace(ext,"")
    filename = "%s/%s%s" % (install_path,program,ext)
    if sys.platform.startswith("linux"):
        platform = "linux"
    elif sys.platform.startswith("darwin"):
        platform = "macosx"
    else:
        raise Exception("invalid platform %s" % (sys.platform))
    cmds = []
    if not os.path.isfile(filename):
        cmds = [
            "mkdir -p %s" % (install_path),
            "cd %s && curl -R -O %s" % (install_path,download_url),
            "cd %s && tar -zxvf %s%s" % (install_path,program,ext),
        ]
    cmds.append("cd %s/%s && make && sudo make install" % (install_path,program))
    result = 0
    for cmd in cmds:
        print(cmd)
        result = os.system(cmd)
        if result != 0:
            break
    return result == 0

def main():
    usage = u'''usage: python %prog [options]
    e.g: python %prog --soft_version=版本 --install_path=安装路径
    '''
    parser = optparse.OptionParser(usage=usage,version="%prog 0.0.1")
    parser.add_option("-s","--soft_version",help=u"[optional,default=%default] 版本",default="5.0.2")
    parser.add_option("-i","--install_path",help=u"[optional,default=%default] 安装路径",default="./install")
    options,args = parser.parse_args()
    soft_version = options.soft_version
    install_path = options.install_path
    download_url = "http://download.redis.io/releases/redis-%s.tar.gz" % (soft_version)
    if has_install_version(soft_version):
        print("already install %s" % soft_version)
        return
    succ = install(download_url,install_path)
    if not succ:
        print("install fail")
    else:
        print("install success")

if __name__ == "__main__":
    main()
