TARGET:set-description([
	"A nondescript weapon.\n",
	"How one would fight with such a nondescript thing is unknown.\n"
]);

define (TARGET) damage = 6;
set-slot-flags(TARGET, #damage, O_ALL_R | O_OWNER_MASK);

define (TARGET) minxp = 1;
set-slot-flags(TARGET, #damage, O_ALL_R | O_OWNER_MASK);

define method (TARGET) initialize() {
  as(Thing):initialize();
  this.damage = 6;
}
make-method-overridable(TARGET:initialize, true);

define method (TARGET) set-damage(val) {
  if (caller-effuid() != owner(this) && !privileged?(caller-effuid()))
    return false;

  this.damage = val;
  true;
}

define method (TARGET) set-damage-verb(b) {
  define p = realuid();
  define levelstr = b[#level][0];
  define level = as-num(levelstr);
  if (level) {
    this:set-damage(level);
    p:mtell(["You change the weapon's damage to ", levelstr, ".\n"]);
  } else {
    p:mtell(["That's not a valid damage level number.\n"]);
  }
}
TARGET:add-verb(#weapon, #set-damage-verb, ["@setdamage ", #weapon, " to ", #level]);

define method (TARGET) wield-verb(b) {
  define p = realuid();
  p:wield(this);
}
TARGET:add-verb(#weapon, #wield-verb, ["wield ", #weapon]);

define method (TARGET) damage(player, target) {
	// TODO: actual damage
	player:mtell(["You damage ", target.name, ".\n"]);
	target:mtell(["\e[31m", player.name, " damages you!\e[0m"]);
	location(player):announce([player.name, " damages ", target.name, ".\n"]);
}
