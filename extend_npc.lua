-- LinkLuaModifier( "modifier_bonus_drop_chance", "modifiers/modifier_bonus_drop_chance.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_animation_override", "extend_npc", LUA_MODIFIER_MOTION_NONE )

-- Force a specific animation to play on a given npc.
-- 'act' is the GameActivity_t enum, so DO NOT put quotes around this value, as it is NOT a string.
-- 'seq_str' is the string name of the specific animation you want to play. You can find these animation names by searching for the model in the Asset Browser, single-clicking on the model, and looking in the 'Sequence' dropdown menu. You find easily find the unit you want by searching 'tiny .vmdl' for instance.
-- 'rate' is the speed at which to play the animation. '1' is normal speed, '2' is double speed, '0.5' is half speed, etc.
-- "dur' is the duration (in speconds) you want the animation to play for. If 'nil' then the animation will play indefinitely. If you want the animation to play only once, use `SequenceDuration()` to get the animation's default duration, and divide that by 'rate'
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

-- This created a set number of invisible/invulnerable 'subcasters' that this unit will remember and re-use.
function CDOTA_BaseNPC:CreateSubcasters( num )
  self.subcasters = {}
  for i=1,num do
    local unit = CreateUnitByName( "npc_dota_subcaster", self:GetOrigin(), false, self, nil, self:GetTeam() )
    -- if unit:HasAbility("hidden_underfoot") then
    --   unit:FindAbilityByName("hidden_underfoot"):SetLevel(1)
    -- end
    -- unit:SetOwner( self )
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

-- get the dist (in a straight line, ignoring terrain) from this unit to the given position
-- Position is a vector, such as Vector( 0, 0, 0 ) or the value returned by unit:GetOrigin()
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