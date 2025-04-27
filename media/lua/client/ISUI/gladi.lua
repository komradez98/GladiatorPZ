GladiatorUI = ISPanel:derive("GladiatorUI")

function GladiatorUI:initialise()
    ISPanel.initialise(self)

    self.title = "Gladiator Mode"
    self.players = {}

    -- Tombol daftar
    self.joinButton = ISButton:new(10, 30, 100, 25, "Join", self, GladiatorUI.onJoin)
    self:addChild(self.joinButton)

    -- Tombol batal
    self.leaveButton = ISButton:new(120, 30, 100, 25, "Leave", self, GladiatorUI.onLeave)
    self:addChild(self.leaveButton)

    -- Tombol tutup
    self.closeButton = ISButton:new(10, 270, 210, 25, "Close", self, GladiatorUI.onClose)
    self:addChild(self.closeButton)

    -- List player (scrollable)
    self.playerListBox = ISScrollingListBox:new(10, 70, 210, 190)
    self.playerListBox:initialise()
    self.playerListBox:instantiate()
    self.playerListBox.itemheight = 20
    self.playerListBox.font = UIFont.Small
    self:addChild(self.playerListBox)
end

function GladiatorUI:onJoin()
    registerGladiator()
end

function GladiatorUI:onLeave()
    unregisterGladiator()
end

function GladiatorUI:onClose()
    self:removeFromUIManager()
    GladiatorUIInstance = nil
end

function GladiatorUI:updateList(players)
    self.playerListBox:clear()
    if players then
        for _, name in ipairs(players) do
            self.playerListBox:addItem(name, name)
        end
    end
end

function showGladiatorUI()
    if GladiatorUIInstance then
        GladiatorUIInstance:removeFromUIManager()
        GladiatorUIInstance = nil
    end

    local x = getCore():getScreenWidth() / 2 - 150
    local y = getCore():getScreenHeight() / 2 - 150
    GladiatorUIInstance = GladiatorUI:new(x, y, 230, 310)
    GladiatorUIInstance:initialise()
    GladiatorUIInstance:addToUIManager()

    -- Minta list terbaru ke server
    requestGladiatorList()
end