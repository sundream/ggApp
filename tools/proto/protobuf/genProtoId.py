import sys
import io
import optparse
import os
import os.path
import re
import string

def gen_message_define(files,patten_str):
    exist_ids = {}
    patten = re.compile(patten_str)
    lst = []
    for filename in iter(files):
        fp = io.open(filename,"rb")
        data = fp.read()
        fp.close()
        result = re.compile("package\s(\w+);").findall(data)
        package = None
        if result:
            package = result[0]
        result = patten.findall(data)
        for elem in iter(result):
            message_id = elem[0]
            message_name = elem[1]
            if package:
                message_name = package + "." + message_name
            assert not exist_ids.has_key(message_id),"repeat message_id=%s message_name=%s" % (message_id,message_name)
            exist_ids[message_id] = message_name
            lst.append([string.atoi(message_id),message_name])
    lst.sort()
    return lst



def main():
    usage = '''usage: python %prog [options]
    e.g: python %prog --output=message_define.lua *.proto
    '''
    parser = optparse.OptionParser(usage=usage,version="%prog 0.0.1")
    parser.add_option("-o","--output",help="[optional] output's filename,default is stdout")
    options,args = parser.parse_args()
    output = options.output
    files = args
    patten = "//\s*@id=(\d+)\s+message\s+(\w+)\s+{"
    lst = gen_message_define(files,patten)
    lst = ['[%d] = "%s",' % (elem[0],elem[1]) for elem in lst]
    gencode = "return {\n\t%s\n}" % string.join(lst,"\n\t")
    if output is None:
        fp = sys.stdout
    else:
        fp = io.open(output,"wb")
    fp.write(gencode)
    if not (output is None):
        fp.close()

if __name__ == "__main__":
    main()
