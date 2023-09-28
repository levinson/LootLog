local NAME, S = ...
local LL = LootLog

local options = S.options

function LL:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LootLogDB", S.defaults, true)
	
	self.db.RegisterCallback(self, "OnProfileChanged", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileCopied", "RefreshDB")
	self.db.RegisterCallback(self, "OnProfileReset", "RefreshDB")
	self:RefreshDB()
	
	self.db.global.version = S.VERSION
	self.db.global.build = S.BUILD
	
	options.args.libsink = self:GetSinkAce3OptionsDataTable()
	options.args.libsink.order = 2
end

function LL:RefreshDB()
	self:SetSinkStorage(self.db.profile) -- LibSink-2.0
end
