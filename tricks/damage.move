// Code for Wizard to compile!
// Not for regular mortals.

define (Player) wielded-weapon = false;
set-slot-flags(Player, #wielded-weapon, O_ALL_R | O_OWNER_MASK);

define (Player) hp = 100;
set-slot-flags(Player, #hp, O_ALL_R | O_OWNER_MASK);

define method (Player) damage(amount) {
	this.hp = this.hp - amount;
	if(this.hp < 1) {
		location(this):announce(["\e[31m", this.name, " has died!\e[0m\n"]);
		this:tell("You died! Returning home.\n");
		//TODO: drop items on death?
		move-to(this, this.home);
	}
	if(this.hp > 100) { //for instance, if damaged a negative amount (healed)
		this.hp = 100; //cap at 100
	}
}

define method (Player) wield(weapon) {
	define is-in-inventory = false;
	
	define i = 0;
	while (i < length(contents(this))) {
		if(contents(this)[i] == weapon) {
			is-in-inventory = true;
		}
		i = i + 1;
	}
	
	if(is-in-inventory) {
		this.wielded-weapon = weapon;
		this:mtell(["You are now wielding ", this.wielded-weapon.name, ".\n"]);
		location(this):announce([this.name, " wields ", this.wielded-weapon.name, ".\n"]);
	} else {
		this:tell("You have to be holding a weapon to wield it!\n");
	}
}

define method (Player) unwield(weapon) {
	if(weapon == this.wielded-weapon) {
		this:mtell(["You unwield ", weapon.name, ".\n"]);
		location(this):announce([this.name, " unwields ", weapon.name, ".\n"]);
		this.wielded-weapon = false;
	} else {
		if(this.wielded-weapon) {
			this:mtell([weapon.name, " is not your current wielded weapon, ", this.wielded-weapon, " is.\n"]);
		} else {
			this:tell("You are not currently wielding a weapon.");
		}
	}
}

define method (Thing) name-for-invent(p) {
  return this.name;
}

define method (Player) color-from-hp() {
	if(this.hp > 65) {
		return "\e[32m";
	} else if(this.hp > 32) {
		return "\e[33m";
	} else {
		return "\e[31m";
	}
}

define method (Player) invent-verb(b) {
  define s = ["HP: ", this:color-from-hp(), this.hp, "/100\e[0m\n\nYou are holding:\n"];

  if (length(contents(this)) == 0)
    s = s + ["    nothing.\n"];
  else
    
    for-each(function (x) s = s + ["    " + x:name-for-invent(this) + "\n"], contents(this));

  this:mtell(s);
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
	if(p == this) {
		p:tell("You shouldn't attack yourself.");
	} else {
		p:attack(this);
	}
}
Thing:add-verb(#target, #be-attacked-verb, ["attack ", #target]);
