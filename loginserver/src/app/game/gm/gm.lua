local cgm = gg.class.cgm

function cgm:open()
    -- helper
    self:register("buildgmdoc",cgm.buildgmdoc)
    self:register("help",cgm.help)

    -- sys
    self:register("stop",cgm.stop)
    self:register("saveall",cgm.saveall)
    self:register("kick",cgm.kick)
    self:register("kickall",cgm.kickall)
    self:register("exec",cgm.exec)
    self:register("runcmd",cgm.runcmd)
    self:register("dofile",cgm.dofile)
    self:register("hotfix",cgm.hotfix)
    self:register("reload",cgm.reload)
    self:register("loglevel",cgm.loglevel)
    self:register("date",cgm.date)
    self:register("ntpdate",cgm.ntpdate)
end

function __hotfix(module)
    gg.actor.gm:open()
end

return cgm