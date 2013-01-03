// Code for Wizard to compile!
// Not for regular mortals.

define (Player) wielded-weapon = null;
set-slot-flags(Player, #wielded-weapon, O_ALL_R | O_OWNER_MASK);

define method (Player) wield(weapon) {
	this.wielded-weapon = weapon;
	this:mtell(["You are now wielding ", this.wielded-weapon.name, ".\n"]);
	location(this):announce([this.name, " wields ", this.wielded-weapon.name, ".\n"]);
}

define method (Player) attack(target) {
	if (this.wielded-weapon) {
		this.wielded-weapon:damage(this, target);
	} else {
		this:tell("You're not wielding a weapon!");
	}
}

define method (Thing) be-attacked-verb(b) {
	define p = realuid();
	p:attack(this);
}
Thing:add-verb(#target, #be-attacked-verb, ["attack ", #target]);
