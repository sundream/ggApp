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

    -- admin
    self:register("rebindserver",cgm.rebindserver)
    self:register("rebindaccount",cgm.rebindaccount)
    self:register("delrole",cgm.delrole)
    self:register("recover_role",cgm.recover_role)
    self:register("clone",cgm.clone)
    self:register("serialize",cgm.serialize)
    self:register("unserialize",cgm.unserialize)
end

function __hotfix(module)
    gg.actor.gm:open()
end

return cgm