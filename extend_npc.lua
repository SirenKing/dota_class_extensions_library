LinkLuaModifier( "modifier_animation_override", "extend_npc", LUA_MODIFIER_MOTION_NONE )

-- Force a specific animation to play on a given npc.
-- act_enum: GameActivity_t such as ACT_IDLE, not a string, so don't put it in quotes. seq_str options can be found by searching for the unit's model in the Asset Browser and looking at the sequences dropdown. If dur is nil, plays seq one time.
function CDOTA_BaseNPC:PlaySequenceWithRateModifier( act_enum, seq_str, rate, dur )

  local mod = nil

  if self:HasModifier("modifier_animation_override") then
    self:RemoveModifierByName("modifier_animation_override")
  end

  mod = self:AddNewModifier( nil, nil, "modifier_animation_override", { duration = dur } )

  mod.rate = rate
  mod.act = act_enum
  mod.sequence_string = seq_str
  mod.dur = dur
  mod:ForceRefresh()

  return mod
end

-- This creates a set number of invisible/invulnerable 'subcasters' that this unit will remember and re-use.
function CDOTA_BaseNPC:CreateSubcasters( num )
  self.subcasters = {}
  for i=1,num do
    local unit = CreateUnitByName( "npc_dota_subcaster", self:GetOrigin(), false, self, nil, self:GetTeam() )
    unit.hero_parent = self

    self.subcasters[i] = unit
    self.subcasters[i].busy = false
    unit.busy = false
  end
  
  SUBCASTERS = self.subcasters
  print( "Hero " .. self:GetName() .. " has " .. #SUBCASTERS .. " subcasters ")

  return self.subcasters
end

-- This gets the subcasters created for this npc. Returns nil if these are currently no subcasters for this unit
-- NOTE: do not use 'SetOwner()' to give this npc ownership of the subcasters, since that causes bot-heroes to try to control these subcasters, causing huge lag
function CDOTA_BaseNPC:GetSubcasters()
  return self.subcasters
end

-- Gets the subcasters for this npc, but only returns the subcasters for which subcaster.busy == false
function CDOTA_BaseNPC:GetIdleSubcasters()
  local subcs = self.subcasters
  local idle = {}
  local add_shard = self:HasModifier( "modifier_item_aghanims_shard" )
  local add_scepter = self:HasModifier( "modifier_item_ultimate_scepter" ) or self:HasModifier( "modifier_item_ultimate_scepter_consumed" )

  if subcs==nil then
    subcs = self:CreateSubcasters( 21 )
  end

  for i=1,#subcs do
    local has_scepter = subcs[i]:HasModifier( "modifier_item_ultimate_scepter_consumed" ) or subcs[i]:HasModifier( "modifier_item_ultimate_scepter" )

    if add_shard and not subcs[i]:HasModifier("modifier_item_aghanims_shard") then
      subcs[i]:AddNewModifier( self, nil, "modifier_item_aghanims_shard", { duration = nil } )
    end

    if add_scepter and not has_scepter then
      subcs[i]:AddNewModifier( self, nil, "modifier_item_ultimate_scepter_consumed", { duration = 0 } )
    end

    if not subcs[i]:IsChanneling() and not subcs[i].busy then
      -- subcs[i]:Stop()
      subcs[i]:SetMana(600)
      table.insert( idle, subcs[i] )
      -- return subcs[i]
    end
  end

  return idle
end

-- This will eventually force this unit to face a random direction
function CDOTA_BaseNPC:SetRandomForward()
  -- self:SetAbsAngles( 0, RandomVector(100).y, 0 ) -- needs to be tested
end

-- get the dist (in a straight line, ignoring terrain) from this unit to the given position. 'Pos' is a vector, such as Vector( 0, 0, 0 ) or the value returned by unit:GetOrigin()
function CDOTA_BaseNPC:GetDistToPos( pos )
  local pos2 = self:GetAbsOrigin()
  local dx = pos.x - pos2.x
  local dy = pos.y - pos2.y
  local distanceToEnt = math.sqrt ( dx * dx + dy * dy )
  return distanceToEnt
end

-- This returns a list of ability names as strings, excluding abilities for map interaction, talents, and 'generic_hidden.'
function CDOTA_BaseNPC:GetHerosMainAbilities()

  local return_table = {}

  for i=0,30 do
    local ability = self:GetAbilityByIndex(i)
    if ability and ability:IsAMainAbility() then -- returns false if this ability is for map interaction, a talent, or 'generic_hidden.'
      table.insert( return_table, ability )
    end
  end

  return return_table
end

-- Force this npc to perform the given order from the order_params you provde, but only after a given delay. This is used by the subcasters, by default.
function CDOTA_BaseNPC:DelayCastWithOrders( order_params, delay )
  order_params.UnitIndex = self:GetEntityIndex()

  Timers:CreateTimer( delay, function()

    ExecuteOrderFromTable( order_params )

    return nil
  end)

end




------------------------
-- ANIMATION MODIFIER --
------------------------

modifier_animation_override = modifier_animation_override or class({})

function modifier_animation_override:IsPermanent() return true end
function modifier_animation_override:RemoveOnDeath() return true end
function modifier_animation_override:IsDebuff() return true end
function modifier_animation_override:IsPurgable() return false end
function modifier_animation_override:IsHidden() return false end

function modifier_animation_override:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE
	}
	return funcs
end

function modifier_animation_override:CheckState()
	local state = {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
	return state
end

function modifier_animation_override:OnCreated()
  print("Got the modifier")
end

function modifier_animation_override:OnRemoved()
  print("Removing animation modifier")
  self:GetParent():RemoveGesture( self.act )
  self:StartIntervalThink(-1)
end

function modifier_animation_override:OnRefresh()

    local parent = self:GetParent()
    parent:StartGestureWithPlaybackRate( self.act, self.rate )
    parent:SetSequence( self.sequence_string )
    local true_duration = self:GetParent():ActiveSequenceDuration() / self.rate

    self:StartIntervalThink( true_duration )

    print(self:GetDuration())

    if self.dur==nil then
      self:SetDuration( true_duration - FrameTime(), true )
    end
end

function modifier_animation_override:OnIntervalThink()
  self:OnRefresh()
end

function modifier_animation_override:GetOverrideAnimationRate()
  return self.rate
end