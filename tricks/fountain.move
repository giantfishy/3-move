define method (TARGET) drink-from-verb(b) {
	define p = realuid();
	p:damage(-100);
	p:tell("You have been healed to full health.\n");
}
TARGET:add-verb(#target, #drink-from-verb, ["drink from ", #target]);