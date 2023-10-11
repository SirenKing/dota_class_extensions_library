local ALL_ABILITY_EXCEPTIONS = LoadKeyValues('scripts/vscripts/ability_exceptions.txt')

function CDOTABaseAbility:BeginCastStormRadial( ability_name, origin, cast_qty, delay, min_dist, max_dist, min_radius, max_radius, b_randomize_origin )

  if IsClient() then return end

  self.last_casters = {}

  local hero = self:GetCaster()
  local subcasters = hero:GetIdleSubcasters()

  self.pos = {}

  for i=1,cast_qty do

    self.pos[i] = self:GetRandomPointInRadius( origin, min_dist, max_dist )
    local unit = subcasters[i]

    if unit~=nil then
      local weak_abil = unit:FindAbilityByName( "weak_creature" )
      if weak_abil == nil then
        weak_abil = unit:AddAbility( "weak_creature" )
      end
      weak_abil.radius = RandomInt( 10*min_radius, 10*max_radius ) / 10
      local ability = unit:FindAbilityByName( ability_name )
      if ability == nil then
        ability = unit:AddAbility(ability_name)
      end

      local original_ability = hero:FindAbilityByName(ability_name)
      if original_ability then
        ability:SetLevel( original_ability:GetLevel() )
      else
        ability:SetLevel( self:GetLevel() )
      end
      ability:EndCooldown()

      local abilityBehavior = ability:GetCastTypeString()
      local cast_type = nil
      
      if string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_POINT") then
        cast_type = DOTA_UNIT_ORDER_CAST_POSITION
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_NO_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_NO_TARGET
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_TARGET
      end

      ability:SetLevel( self:GetLevel() )
      if cast_type ~= DOTA_UNIT_ORDER_CAST_NO_TARGET then
        local caster_new_pos = self:GetCaster():GetAbsOrigin()
        unit:SetAbsOrigin(caster_new_pos)
      end
      local secondary_position = self:GetRandomPointInRadius( self.pos[i], 1, 200 )

      if b_randomize_origin then
        unit:SetAbsOrigin( self:GetRandomPointInRadius( self.pos[i], 50, 300 ) )
        secondary_position = self:GetCaster():GetAbsOrigin()
      end
      
      if string.match( abilityBehavior, "DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING") then

        local order_params = {
          UnitIndex = unit:GetEntityIndex(),
          OrderType = DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION,
          AbilityIndex = ability:GetEntityIndex(),
          TargetIndex = unit:GetEntityIndex(),
          Position = secondary_position,
          Queue = false
        }
        unit:DelayCastWithOrders( order_params, 0 )

        cast_type = DOTA_UNIT_ORDER_CAST_POSITION
      end

      local order_params = {
        UnitIndex = unit:GetEntityIndex(),
        OrderType = cast_type,
        AbilityIndex = ability:GetEntityIndex(),
        TargetIndex = ability:GetEntityIndex(),
        Position = self.pos[i],
        Queue = false
      }

      unit:DelayCastWithOrders( order_params, delay*i )
      self.last_casters = {}
      table.insert( self.last_casters, unit )

      Timers:CreateTimer( delay + 1, function()
        ability:EndCooldown()
        return nil
      end)
    end

  end
end

function CDOTABaseAbility:SplitSubcast( ability_name, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, vector_cast_rotation )

  if IsClient() then return end

  local hero = self:GetCaster()
  local subcasters = hero:GetIdleSubcasters( hero )
  
  --------------
  -- Start logic for secondary abilities
  --------------

  local original_ability = hero:FindAbilityByName(ability_name)
  local has_secondary = false
  local is_secondary = false

  if origin==nil or origin==Vector(0,0,0) then
    origin = hero:GetAbsOrigin()
  end

  if original_ability~=nil then
    has_secondary = original_ability:GetReturnReleaseOrEndAbilityName()~=nil
    is_secondary = original_ability:IsReturnReleaseOrEndAbilityName()
  end

  if original_ability~=nil and has_secondary then
    local secondary_ability_name = original_ability:GetReturnReleaseOrEndAbilityName()
    local secondary_ability = hero:FindAbilityByName( secondary_ability_name )

    local current_prepped = secondary_ability.prepped_casters
    
    if secondary_ability.prepped_casters==nil then
      secondary_ability.prepped_casters = subcasters
    else
      for i=1,cast_qty do
        local num_in_prepped = #current_prepped
        secondary_ability.prepped_casters[ num_in_prepped + i ] = subcasters[i]
      end
    end
  end

  if is_secondary and original_ability~=nil and original_ability.prepped_casters~=nil then -- if the original ability is a secondary ability and has prepared casters, then use those casters

    local previous_casters = original_ability.prepped_casters

    for i=1,#previous_casters do
      subcasters[i] = original_ability.prepped_casters[i]
    end

    cast_qty = #previous_casters
    origin = hero:GetAbsOrigin()
    -- original_ability.prepped_casters = {}
  end

  --------------
  -- End Secondary Ability Logic
  --------------

  for i=1,cast_qty do
    local unit = subcasters[i]

    -- if unit==nil then return end
    if unit ~= nil then
      unit:SetAbsOrigin( origin )
      -- unit.busy = true
      local angle_mult = i - 1 -- times to increment the angle, starting at 0 for the first iteration
      
      local y_degrees = offset_angle_degrees + ( angle_increment_degrees * angle_mult )
      local rotation = QAngle( 0, y_degrees, 0 )

      local random_degrees = vector_cast_rotation + ( angle_increment_degrees * angle_mult )
      local random_vector_rotation = QAngle( 0, random_degrees, 0 )
      -- local rand_rot_pos = unitGetAbsOrigin() + ( unitGetForwardVector()  ( dist_from_origin + dist_increment  i ) )

      local cast_type = DOTA_UNIT_ORDER_CAST_POSITION

      local new_forward = RotateOrientation( rotation, original_angles )
      local rand_vector_forward = RotateOrientation( random_vector_rotation, original_angles )

      local weak_abil = unit:FindAbilityByName( "weak_creature" )
      if weak_abil == nil then
        weak_abil = unit:AddAbility( "weak_creature" )
      end
      weak_abil.damage = damage_fl
      weak_abil.radius = radius_fl

      -- print(unit)
      local ability = unit:FindAbilityByName( ability_name )
      if ability == nil then
        ability = unit:AddAbility(ability_name)
      else
        ability:EndCooldown()
      end

      if original_ability then
        ability:SetLevel( original_ability:GetLevel() )
      else
        print( "Did not find original of named ability. Setting level to equal to 'self' level instead (usually 1).")
        ability:SetLevel( self:GetLevel() )
      end

      ability:SetHidden(false)
      local abilityBehavior = ability:GetCastTypeString()
      -- abilityEndCooldown()

      unit:SetAbsAngles( 0, new_forward.y, 0 )
      local pos_1 = origin + ( unit:GetForwardVector() * ( dist_from_origin + ( dist_increment * i ) ) ) -- get incremented distance from origin at designated angle
      local pos_1_cast = pos_1 + ( unit:GetForwardVector() * dist_from_subcaster ) -- get point at dist_from_subcaster ahead of pos_1, to cast at

      unit:SetAbsAngles( 0, rand_vector_forward.y, 0 )
      local pos_2 = pos_1_cast
      local pos_2_cast = pos_1 + ( unit:GetForwardVector() * dist_from_subcaster ) -- get point at dist_from_subcaster ahead of pos_1, to cast at
      -- local radius = abilityGetSpecialValueFor(radius)
      
      if string.match( abilityBehavior, "DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING") then

        local order_params = {
          UnitIndex = unit:GetEntityIndex(),
          OrderType = DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION,
          AbilityIndex = ability:GetEntityIndex(),
          TargetIndex = unit:GetEntityIndex(),
          Position = pos_1_cast,
          Queue = false
        }
        unit:DelayCastWithOrders( order_params, 0 )

        cast_type = DOTA_UNIT_ORDER_CAST_POSITION

      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_POINT") then
        cast_type = DOTA_UNIT_ORDER_CAST_POSITION
        unit:SetAbsOrigin( origin )
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_NO_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_NO_TARGET
      elseif string.match(abilityBehavior, "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET") then
        cast_type = DOTA_UNIT_ORDER_CAST_TARGET
      end

      -- local subcaster_origin_spun = unitGetAbsOrigin() + ( unitGetForwardVector()  ( dist_from_origin + dist_increment  i ) )

      unit:SetAbsAngles( 0, new_forward.y, 0 )
      -- local subcaster_origin = unitGetAbsOrigin() + ( unitGetForwardVector()  ( dist_from_origin + dist_increment  i ) )
      -- local cast_pos = unitGetAbsOrigin() + ( unitGetForwardVector()  dist_from_subcaster )

      local cast_pos = nil
      -- if isVTarget_b then
      if vector_cast_rotation~=nil and vector_cast_rotation~=0 then -- should cast from pos_2, targeting pos_2_cast
        unit:SetAbsOrigin( pos_2 )
        cast_pos = pos_2_cast
      else
        unit:SetAbsOrigin( pos_1 )
        cast_pos = pos_1_cast
      end
      -- end

      local order_params = {
        UnitIndex = unit:GetEntityIndex(),
        OrderType = cast_type,
        AbilityIndex = ability:GetEntityIndex(),
        TargetIndex = unit:GetEntityIndex(),
        Position = cast_pos,
        Queue = false
      }

      unit:DelayCastWithOrders( order_params, delay*i )
      unit.busy = true

      Timers:CreateTimer( delay+4, function()
        ability:EndCooldown()
        unit.busy = false
        return nil
      end)
    end
  end
end

function CDOTABaseAbility:GetAllAbilitySpecials() -- Gets the USEFUL ability special values ONLY
  local specialsArray = {}

  local abilityKeys = self:GetAbilityKeyValues()
  local abilitySpecials = abilityKeys["AbilitySpecial"]

  if abilitySpecials==nil then
    abilitySpecials = abilityKeys["AbilityValues"]
    local isTalent = string.match( self:GetName(), "special_bonus")
    if abilitySpecials and not isTalent then

      -- DeepPrint( abilitySpecials )

      for k,v in pairs( abilitySpecials ) do

        local isVarType = string.match( k, "var_type")
        local isScepterCheck = string.match( k, "scepter")
        local isTooltipCal = string.match( k, "Calculate")
        local isTalentStuff = string.match( k, "LinkedSpecialBonus")
        -- local vIsTable = type(k)=="table"

        if isVarType or isScepterCheck or isTooltipCal or isTalentStuff then
          -- print( "key is not useful" )
        -- elseif vIsTable then
          
        else
          table.insert( specialsArray, k )
        end

      end
    end

  else
    local isTalent = string.match( self:GetName(), "special_bonus")
    if abilitySpecials and not isTalent then

      -- DeepPrint( abilitySpecials )

      for k,v in pairs( abilitySpecials ) do
        for x,y in pairs(v) do

          local isVarType = string.match( x, "var_type")
          local isScepterCheck = string.match( x, "scepter")
          local isTooltipCal = string.match( x, "Calculate")
          local isTalentStuff = string.match( x, "LinkedSpecialBonus")

          if isVarType or isScepterCheck or isTooltipCal or isTalentStuff then
            -- print(key is not useful)
          else
            table.insert(specialsArray,x)
          end

        end
      end
    end

  end

  if abilitySpecials==nil then
    -- print( "Error ocurred. No ability specials found for ", self:GetName() )
    return {}
  end

  return specialsArray
end

function CDOTABaseAbility:GetHasAbilitySpecialWith( name_str ) -- checks whether an ability has a special value containing this string in the name
  local specialsArray = self:GetAllAbilitySpecials()

  for i=1,#specialsArray do
    if string.match( specialsArray[i], name_str ) then
      return true
    end
  end

  return false
end

function CDOTABaseAbility:GetFirstAbilitySpecialNameContaining( name_str ) -- checks whether an ability has a special value containing this string in the name
  local specialsArray = self:GetAllAbilitySpecials()

  for i=1,#specialsArray do
    if string.match( specialsArray[i], name_str ) then
      return specialsArray[i]
    end
  end

  return false
end

function CDOTABaseAbility:GetCastTypeString()
  local abilityKeys = self:GetAbilityKeyValues()
  local abilityBehavior = abilityKeys["AbilityBehavior"]
  return abilityBehavior
end


function CDOTABaseAbility:ChaosCastPointSpell( ability, pos, pattern ) -- pos is an optional parameter that chooses an origin other than the caster's location

  local origin = self:GetCaster():GetOrigin()

  if pos~=nil and pos~=Vector(0,0,0) then
    pos = origin
  end

  local original_angles = self:GetCaster():GetLocalAngles()
  local spellName = ability:GetName()

  if not pattern then
    pattern = ""
  end
  
  local posNegTable = { 1, -1 }
  local posNeg = posNegTable[ RandomInt(1,2) ]
  local posNeg2 = posNegTable[ RandomInt(1,2) ]
  local vector_rotation = RandomInt( -180, 180 )
  local caster = self:GetCaster()

  local subs = caster:GetSubcasters()
  if subs==nil then
    caster:CreateSubcasters( 21 )
  end

  if pattern~=nil then
    print( "Pattern # is " .. pattern )
  end

--   if ALL_ABILITY_EXCEPTIONS[spellName] and ALL_ABILITY_EXCEPTIONS[spellName].should_nerf==true then
-- -- SplitSubcast( ability_name, origin, original_angles, cast_qty, delay, angle_increment_degrees, offset_angle_degrees, dist_from_origin, dist_from_subcaster, dist_increment, radius_fl, damage_fl, vector_cast_rotation )
--     local rand_qty = RandomInt(4,5) -- cast op spells ins a ring
--     self:SplitSubcast(
--       spellName, -- spell for the subcaster to cast
--       origin, -- position at which to place the subcasters
--       original_angles, -- orientation of the hero when the spell was originally cast
--       rand_qty, -- # of times to cast / number of subcasters
--       0, -- Time/Seconds between each cast
--       360*rand_qty, -- rotate next subcaster by x degrees around the chosen origin, 1x per cast_qty
--       0, -- give all subcasters a base rotation of x degrees around the chosen 'origin' position
--       1, -- place subcasters this distance ahead of the origin, in the direction the caster was facing
--       300+(rand_qty*50), -- subcasters cast spell x distance ahead of themselves ()
--       0, -- move the subcasters forward by x distance, incrementally
--       2*rand_qty, -- multiply the radius of the ability being cast
--       2*rand_qty, -- multiply the damage of the ability being cast
--       vector_rotation ) -- rotate vector-cast abilities by x degrees

  if pattern=="flower" then -- casts your spell in 3-5 rows, 3-4 casts long. Usually curved 
    local dist_increment = 110 -- distance between each cast on each row
    local angle_increment_degrees = 30*posNeg -- curve of the four rows on your spell
    local rows = 5
    local instances = 4
    for i=1,instances do
      Timers:CreateTimer( 0.4*i, function()
        self:SplitSubcast( spellName, origin, original_angles, rows, 0, 360/rows, 0, 1, dist_increment*i, 0, 0.6*i, 1, vector_rotation + (angle_increment_degrees*i) ) -- cast on four sides
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern=="echo" then -- casts your spell 4 times in the same location with growing size  
    for i=1,4 do
      Timers:CreateTimer( 1.4*(i-1), function()
        self:SplitSubcast( spellName, pos, original_angles, 1, 1, 1, 1, 1, 1, 0, 0.7*i, 1, 0 )
      end)
    end

  elseif pattern=="wave" then -- cast your ability in a wave in front of you
    local spread = 45
    for i=1,4 do
      Timers:CreateTimer( 0.4*i, function()
        self:SplitSubcast( spellName, origin, original_angles, 1+i, 0, spread/i, -spread/2, 200*i, 100*i, 0, 1+(0.5*i), 1, 0 )
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern=="nova" then -- instantly cast your ability in a single ring around you
    local magnitude = 8
          
    if string.match( ability:GetCastTypeString(), "DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING") then -- if this is a vector-target ability, instead cast at the point where the cast vector begins 
      origin = pos
    end

    self:SplitSubcast( spellName, origin, original_angles, magnitude, 0, 360/magnitude, 0, 100, 400, 0, 0.7, 0.7, 90*posNeg )
    
  elseif pattern=="spiral" then -- spiral
    for i=1,20 do
      Timers:CreateTimer( 0.1*i, function()
        local progression = 180 + (600/(10+i/2)*i)*posNeg
        self:SplitSubcast( spellName, pos, original_angles, 1, 0, 0, progression, 45*i, 100, 0, 0.2 + 0.2*i, 0.5, progression+90 ) -- progressive spiral
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern=="storm" then -- cast a totally random 'storm' of your spell in an area around you
    self:BeginCastStormRadial( spellName, pos, 10, 0.25, 100, 600, 0.7, 0.8, true )

  elseif pattern=="spread" then -- cast a totally random 'storm' of your spell in an area around you
    local spread = 30
    local qty = 5

    self:SplitSubcast( spellName, pos, original_angles, qty, 0, 30, -spread*((qty-1)/2), 1, 400, 1, 1, 1, 0 )
    
  elseif pattern=="worm" then -- Cast multiple times, crawling forward each cast, with growing radius and damage
    local rand = 4
    for i=1,rand do
      Timers:CreateTimer( 0.4*(i-1), function()
        self:SplitSubcast( spellName, origin, original_angles, 1, 0, 0, 0, 0, 1, 200*i*(i/3), i/2, 0.7, 0 ) -- progressively casts further and further ahead, with growing radius
        self.RemoveSelf = true
        return nil
      end)
    end

  elseif pattern=="epicenter" then -- repeatedly cast your ability in a growing ring around you

    self:SplitSubcast( spellName, origin, original_angles, 7, 0, 360/7, 0, 200, 0, 0, 1, 0.25, vector_rotation*posNeg )

      Timers:CreateTimer( 0.4, function()
        self:SplitSubcast( spellName, origin, original_angles, 5, 0, 360/7, 25.7, 350, 0, 0, 1.7, 0.25, vector_rotation*posNeg2 )

        Timers:CreateTimer( 0.4, function()
          self:SplitSubcast( spellName, origin, original_angles, 7, 0, 360/7, 0, 500, 0, 0, 2.4, 0.25, vector_rotation*posNeg )

          Timers:CreateTimer( 0.4, function()
            self:SplitSubcast( spellName, origin, original_angles, 9, 0, 360/7, 0, 500, 0, 0, 2.8, 0.25, vector_rotation*posNeg )
          end)
        end)

        self.RemoveSelf = true
        return nil
      end)
    
  elseif pattern=="pentagram" then -- instantly cast your ability in a single ring around you, angled into a pentagram
    local star_points = RandomInt( 5, 8 )
    self:SplitSubcast( spellName, origin, original_angles, star_points, 0, 360/star_points, 0, 250, 250, 0, 1, 1, 180 + 180/star_points )

    if spellName=="lion_impale" and star_points==5 and origin~=caster:GetAbsOrigin() then -- if lion made a pentagram away from himself (~157 chance), summon a chaos golem, lol
      self:SplitSubcast( "warlock_rain_of_chaos", origin, original_angles, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0 ) -- doesn't give control of golem, but still funny
    end

  else
    print("no pattern recognized")
  end

end

function CDOTABaseAbility:GetReturnReleaseOrEndAbilityName( name )
  
  local secondary_name = nil

  if ALL_ABILITY_EXCEPTIONS[name] then
    secondary_name = ALL_ABILITY_EXCEPTIONS[name].has_secondary
  end

  if secondary_name~=nil then
    return secondary_name
  end

  return nil
end

function CDOTABaseAbility:IsReturnReleaseOrEndAbilityName( name )
  
  local primary_name = nil

  if ALL_ABILITY_EXCEPTIONS[name] then
    primary_name = ALL_ABILITY_EXCEPTIONS[name].has_primary
  end

  if primary_name~=nil then
    return primary_name
  else
    return false
  end
end

function CDOTABaseAbility:GetRandomPointInRadius( v_location, min_dist, max_dist )
  local random_length = RandomInt( min_dist, max_dist )
  local random_point = v_location + RandomVector( random_length )
  return random_point
end

function CDOTABaseAbility:GetRandomPointInSquare( v_location, min_dist, max_dist )
  local x_range = RandomInt( min_dist, max_dist )
  local y_range = RandomInt( min_dist, max_dist )
  local chance_x_positive = RandomInt(1,2)
  local chance_Y_positive = RandomInt(1,2)

  if chance_x_positive==1 then x_range = -x_range end
  if chance_Y_positive==1 then y_range = -y_range end
  v_location.x = v_location.x + x_range
  v_location.y = v_location.y + y_range

  return v_new_location
end

function CDOTABaseAbility:IsAMapAbility() -- checks whether this ability is an ability unique to map interactions
  local name = self:GetName()
  if name=="ability_lamp_use" or name=="ability_capture" or name=="ability_pluck_famango" or name== "twin_gate_portal_warp" or name=="abyssal_underlord_portal_warp" then
    return true
  end
  return false
end

function CDOTABaseAbility:IsMainHeroAbility()
  local name = self:GetName()
  if not self:IsAMapAbility() and name~="generic_hidden" and not string.match( name, "talent" ) and not string.match( name, "bonus" ) then
    return true
  else
    return false
  end
end