LinkLuaModifier("modifier_weak_creature", "abilities/weak_creature", LUA_MODIFIER_MOTION_NONE )

-- Ability

weak_creature = class ({})

function weak_creature:Spawn()
	self.damage = 1
	self.radius = 1
	self.heal = 1
	self.mana = 1
	self.length = 1
end

function weak_creature:GetIntrinsicModifierName()
  return "modifier_weak_creature"
end

-- MODIFIER

modifier_weak_creature = modifier_weak_creature or class({})

function modifier_weak_creature:GetTexture() return "item_blades_of_attack" end

function modifier_weak_creature:IsPermanent() return true end
function modifier_weak_creature:RemoveOnDeath() return true end
function modifier_weak_creature:IsDebuff() return true end
function modifier_weak_creature:IsPurgable() return false end
function modifier_weak_creature:IsHidden() return true end

function modifier_weak_creature:CheckState()
	state = {
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		-- [MODIFIER_STATE_OUT_OF_GAME] = true, --units with this property can't cast swashbuckle, and a couple of other abilities
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
		[MODIFIER_STATE_IGNORING_STOP_ORDERS] = true
	}
	return state
end

function modifier_weak_creature:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_MP_RESTORE_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE
	}
	return funcs
end

function modifier_weak_creature:OnCreated()
	self:StartIntervalThink(8)
end

function modifier_weak_creature:GetModifierDamageOutgoing_Percentage()
	return -100 + (self:GetAbility().damage * 100)
end

function modifier_weak_creature:GetModifierHealAmplify_PercentageSource()
	return -100 + (self:GetAbility().heal * 100)
end

function modifier_weak_creature:GetModifierMPRestoreAmplify_Percentage()
	return -100 + (self:GetAbility().mana * 100)
end

function modifier_weak_creature:GetModifierOverrideAbilitySpecial( params )
    local szSpecialValueName = params.ability_special_value

	if string.match(szSpecialValueName, "radius") then
		return 1
	elseif string.match(szSpecialValueName, "length") then
		return 1
	end
	
	return 0
end

function modifier_weak_creature:GetModifierOverrideAbilitySpecialValue( params )

	if params.ability:IsItem() then return end

	local szAbilityName = params.ability:GetAbilityName()
	local szSpecialValueName = params.ability_special_value
	local nSpecialLevel = params.ability_special_level
	local base_value = params.ability:GetLevelSpecialValueNoOverride( szSpecialValueName, nSpecialLevel )
	local ability = self:GetAbility()
	local amped = base_value

	if string.match( szSpecialValueName, "radius" ) then -- if this ability has an AbilityValue or AbilitySpecial with 'radius' in it's name, alter the value
		base_value = base_value * (ability.radius)
	end

	if string.match( szSpecialValueName, "length" ) then
		base_value = base_value * (ability.length)
	end

	return base_value
end

function modifier_weak_creature:GetModifierPercentageCooldown()
	return 100
end