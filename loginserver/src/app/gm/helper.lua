---功能: 构建GM指令文档.txt
---@usage buildgmdoc
function gm.buildgmdoc()
    if skynet.getenv("area") ~= "dev" then
        -- 外服代码经过编译，无法提取出文档代码,因此直接读备份文档
        local docfilename = "src/app/gm/gmdoc.txt"
        local fd = io.open(docfilename,"rb")
        local doc = {}
        for line in fd:lines("*l") do
            table.insert(doc,line)
        end
        fd:close()
        gm.__doc = doc
        return
    end
    local tmpfilename = ".gmdoc.tmp"
    local gmcode_path = "src/app/gm/"
    local gmcode_path = "src/app/gm/"
    -- all filename in $gmcode_path
    os.execute("ls -l " .. gmcode_path .. " | awk '{print $9}' > " .. tmpfilename)

    local fdin = io.open(tmpfilename,"rb")
    local doc = {}
    for filename in fdin:lines("*l") do
        if not string.match(filename,"^%s*$") then
            if filename:sub(-4) == ".lua" then
                local fd = io.open(gmcode_path .. filename,"rb")
                local tbl = {}
                local open = false
                for line in fd:lines("*l") do
                    line = string.match(line,"^%-%-%-%s*(.+)$")
                    if line then
                        table.insert(tbl,line)
                        open = true
                    else
                        if open then
                            table.insert(tbl,"")
                        end
                        open = false
                    end
                end
                fd:close()
                filename = string.gsub(filename,"%.lua","")
                table.insert(doc,string.format("[%s]",filename))
                for _,line in pairs(tbl) do
                    table.insert(doc,line)
                end
                table.insert(doc,"")
            end
        end
    end
    fdin:close()
    os.execute("rm -rf " .. tmpfilename)
    gm.__doc = doc
    doc = table.concat(doc,"\n")

    local docfilename = "src/app/gm/gmdoc.txt"
    local fdout = io.open(docfilename,"wb")
    fdout:write(doc)
    fdout:close()

    local docpath = skynet.getenv("docpath")
    if not docpath then
        return
    end
    local app_type = skynet.getenv("type") or "gameserver"
    local gm_path = docpath .. "/gm"
    local docfilename = string.format("%s/%s.txt",gm_path,app_type)
    os.execute(string.format("mkdir -p %s",gm_path))
    os.execute(string.format("svn update --accept=theirs-full %s",gm_path))
    local fdout = io.open(docfilename,"wb")
    fdout:write(doc)
    fdout:close()
    os.execute(string.format("svn add --force %s",gm_path))
    os.execute(string.format("svn commit %s -m 'buildgmdoc'",gm_path))
    return
end

---功能: 查找包含关键字的相关指令
---@usage help 关键字
function gm.help(args)
    local isok,args = gg.checkargs(args,"string")
    if not isok then
        local usage = "用法: help 关键字"
        return gm.say(usage)
    end
    local patten = args[1]
    local doc = gm.getdoc()
    local emptyline,startlineno = 1,1
    local maxlineno = #doc
    local findlines = {}
    local lineno = 0
    while lineno < maxlineno do
        lineno = lineno + 1
        local line = doc[lineno]
        if not line then
            break
        end
        if line == "" or line == "\r" or line == "\n" or line == "\r\n" then
            emptyline = lineno
        else
            if string.find(line,patten) or string.find(line:lower(),patten) then
                for i=emptyline+1,maxlineno do
                    local curline = doc[i]
                    if not (curline == "" or curline == "\r" or curline == "\n" or curline == "\r\n") then
                        table.insert(findlines,curline)
                    else
                        table.insert(findlines,string.rep("-",20))
                        emptyline = i
                        if i > lineno then
                            lineno = i
                        end
                        break
                    end
                end
            end
        end
    end
    local help = table.concat(findlines,"\n")
    if help and help ~= "" then
        return gm.say(help)
    else
        return gm.say("很抱歉，没有找到相关指令")
    end
end

function gm.getdoc()
    if not gm.__doc then
        gm.buildgmdoc()
    end
    return gm.__doc
end

function __hotfix(module)
    gm.__doc = nil
end

return gm
