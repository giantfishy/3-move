// 3-MOVE, a multi-user networked online text-based programmable virtual environment
// Copyright 1997, 1998, 1999, 2003, 2005, 2008, 2009 Tony Garnock-Jones <tonyg@kcbbs.gen.nz>
//
// 3-MOVE is free software: you can redistribute it and/or modify it
// under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// 3-MOVE is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public
// License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with 3-MOVE.  If not, see <http://www.gnu.org/licenses/>.
//
// thing.move
set-realuid(Wizard);
set-effuid(Wizard);

clone-if-undefined(#Thing, Root);
set-object-flags(Thing, O_NORMAL_FLAGS | O_C_FLAG);

Thing:set-name("Generic Thing");

define (Thing) description = ["A non-descript kind of thing, really. Not much to look at.\n"];
set-slot-flags(Thing, #description, O_OWNER_MASK);

define (Thing) aliases = [];
set-slot-flags(Thing, #aliases, O_OWNER_MASK);

define (Thing) verbs = [];
set-slot-flags(Thing, #verbs, O_OWNER_MASK);

define method (Thing) initialize() {
  as(Root):initialize();
  this.verbs = [];
}
make-method-overridable(Thing:initialize, true);

define method (Thing) aliases() copy-of(this.aliases);

define method (Thing) add-alias(n) {
  if (caller-effuid() != owner(this) && !privileged?(caller-effuid()))
    return false;

  this.aliases = this.aliases + [n];
  return true;
}

define method (Thing) del-alias(n) {
  if (caller-effuid() != owner(this) && !privileged?(caller-effuid()))
    return false;

  define i = 0;
  define v = this.aliases;
  define l = length(v);

  while (i < l) {
    if (equal?(v[i], n)) {
      this.aliases = delete(v, i, 1);
      return true;
    }
    i = i + 1;
  }

  return false;
}

define method (Thing) add-verb(selfvar, methname, pattern) {
  define c = caller-effuid();
  define fl = object-flags(this);

  if ((fl & O_WORLD_W == O_WORLD_W) ||
      ((fl & O_GROUP_W == O_GROUP_W) && in-group-of(c, this)) ||
      ((fl & O_OWNER_W == O_OWNER_W) && c == owner(this)) ||
      privileged?(c)) {
    define vb = first-that(function (v) {
      v[2] == methname && v[1] == selfvar && vector-equal?(v[0], pattern);
    }, this.verbs);
    if (vb == undefined)
      this.verbs = this.verbs + [[pattern, selfvar, methname]];
    else {
      vb[0] = pattern;
    }
    true;
  } else
    false;
}

define method (Thing) match-verb(sent) {
  define v = this.verbs;
  define i = 0;

  while (i < length(v)) {
    define pat = v[i][0];
    define selfvar = v[i][1];
    define methname = v[i][2];
    define patlen = length(pat);
    define bindings = make-hashtable(17);

    define function accumulate-matches(rsent, idx) {
      if (idx >= patlen)
	return length(rsent) == 0;

      define thiselt = pat[idx];

      if (type-of(thiselt) == #symbol) {
	if (idx + 1 == patlen) {
	  bindings[thiselt] = rsent;
	  return true;
	}

	define nextelt = pat[idx + 1];

	if (type-of(nextelt) != #string)
	  return false;

	define nel = length(nextelt);
	define loc = substring-search-ci(rsent, nextelt);

	if (!loc)
	  return false;

	bindings[thiselt] = section(rsent, 0, loc);
	return accumulate-matches(section(rsent, loc + nel, length(rsent) - (loc + nel)), idx + 2);
      } else if (type-of(thiselt) == #string) {
	if (substring-search-ci(rsent, thiselt) != 0)
	  return false;

	define tel = length(thiselt);
	return accumulate-matches(section(rsent, tel, length(rsent) - tel), idx + 1);
      }
    }

    define ccretval = call/cc(function (cc) {
      if (accumulate-matches(sent, 0)) {
	bindings[#this] = [false, this];
	cc([selfvar, methname, bindings, cc]);
      } else
	cc(#continue);
    });

    if (ccretval != #continue)
      return ccretval;

    i = i + 1;
  }

  define function search-vec(vec) {
    define i = 0;

    while (i < length(vec)) {
      define result = vec[i]:match-verb(sent);
      if (result) {
	result[2][#this] = [false, this];
	return result;
      }
      i = i + 1;
    }

    false;
  }

  (this != Thing && search-vec(parents(this)));
}

define method (Thing) match-objects(match) {
  define bindings = match[2];
  define keys = all-keys(bindings);
  define i = 0;

  while (i < length(keys)) {
    define key = keys[i];
    define str = bindings[key];

    if (type-of(str) == #string) {	// else it's already been matched.
      define match-result = this:match-object(str);
      if (match-result)
	bindings[key] = [str, this:match-object(str)];
    }

    i = i + 1;
  }
}

define method (Thing) match-object(name) {
  if (equal?(name, this.name))
    return this;

  define c = first-that(function (x) equal?(x, name), this:aliases());
  if (c != undefined)
    return this;

  c = find-by-name(contents(this), name);
  if (c != undefined)
    return c;

  c = first-that(function (o) {
		   first-that(function (x) equal?(x, name), o:aliases()) != undefined;
		 }, contents(this));
  if (c != undefined)
    return c;

  return false;
}
make-method-overridable(Thing:match-object, true);

define method (Thing) read() "";
make-method-overridable(Thing:read, true);

define method (Thing) mtell(vec) {
  if (type-of(vec) == #vector)
    for-each(this:tell, vec);
  else
    this:tell(vec);
}

define method (Thing) tell(x) undefined;
make-method-overridable(Thing:tell, true);

define method (Thing) announce(x) this:announce-except([realuid()], x);

define method (Thing) announce-all(x)
  for-each(function (o) o:mtell(x), contents(this));
make-method-overridable(Thing:announce-all, true);

define method (Thing) announce-except(who-vec, x)
  for-each(function (o) if (!index-of(who-vec, o)) o:mtell(x), contents(this));
make-method-overridable(Thing:announce-except, true);

define method (Thing) listening?() false;
make-method-overridable(Thing:listening?, true);

define method (Thing) locked-for?(x) false;
make-method-overridable(Thing:locked-for?, true);

define method (Thing) moveto(loc) {
  define caller = caller-effuid();
  define oldloc = location(this);

  if (oldloc != loc) {
    if (valid(oldloc) && isa(oldloc, Thing) && !oldloc:release(this, loc))
      return #exit-rejected;

    if (!this:pre-move(oldloc, loc))
      return #move-rejected;

    if (!loc:pre-accept(this, oldloc))
      return #entry-rejected;

    move-to(this, loc);

    loc:post-accept(this, oldloc) && this:post-move(oldloc, loc);
  } else
    true;
}

define method (Thing) pre-move(oldloc, loc) true;
make-method-overridable(Thing:pre-move, true);

define method (Thing) pre-accept(thing, from) false;
make-method-overridable(Thing:pre-accept, true);

define method (Thing) post-accept(thing, from) true;
make-method-overridable(Thing:post-accept, true);

define method (Thing) post-move(oldloc, loc) true;
make-method-overridable(Thing:post-move, true);

define method (Thing) release(what, newloc) true;
make-method-overridable(Thing:release, true);

define method (Thing) description() copy-of(this.description);
make-method-overridable(Thing:description, true);

define method (Thing) set-description(d) {
  if (caller-effuid() != owner(this))
    return #no-permission;

  this.description = d;
}

define method (Thing) space() {
  if (caller-effuid() != owner(this) && !privileged?(caller-effuid()))
    return false;

  move-to(this, null);
  return true;
}

define method (Thing) set-cloneable(val) {
  if (caller-effuid() != owner(this) && !privileged?(caller-effuid()))
    return false;

  define fl = object-flags(this);
  if (val) {
    fl = fl | O_C_FLAG;
  } else {
    fl = fl & ~O_C_FLAG;
  }
  set-object-flags(this, fl);
  true;
}

////////////////////////////////////////////////////////////////////////////
// VERBS

define method (Thing) setdesc-verb(b) {
  define d = this:description();
  define player = realuid();
  define ptell = player:tell;

  if (effuid() != owner(this))
    ptell("You don't own that object, so you are not allowed to describe it...\n");
  else {
    player:mtell(["Editing description of ", this, ".\n"]);
    define e = editor(d);

    if (e == d)
      ptell("Edit aborted.\n");
    else {
      ptell("Setting description...\n");
      if (this:set-description(e) == #no-permission)
	ptell("Failed to set the description.\n");
      else
	ptell("Description set.\n");
    }
  }
}
set-setuid(Thing:setdesc-verb, false);
Thing:add-verb(#obj, #setdesc-verb, ["@describe ", #obj]);

define method (Thing) @name-verb(b) {
  define player = realuid();
  define name = b[#name][0];
  if (object-named(name))
    player:tell("Warning: there's already an object with that name that you can see.\n");
  player:mtell(["Renaming ", this, " to \"", name, "\"...\n"]);
  if (this:set-name(name))
    player:tell("Successful.\n");
  else
    player:tell("Permission denied.\n");
}
set-setuid(Thing:@name-verb, false);
Thing:add-verb(#obj, #@name-verb, ["@name ", #obj, " as ", #name]);

define method (Thing) @alias-verb(b) {
  define player = realuid();
  define name = b[#name][0];
  player:mtell(["Aliasing ", this, " to \"", name, "\"...\n"]);
  if (this:add-alias(name))
    player:tell("Successful.\n");
  else
    player:tell("Permission denied.\n");
}
set-setuid(Thing:@alias-verb, false);
Thing:add-verb(#obj, #@alias-verb, ["@alias ", #obj, " as ", #name]);

define method (Thing) @unalias-verb(b) {
  define player = realuid();
  define name = b[#name][0];
  player:mtell(["Unaliasing ", this, " as \"", name, "\"...\n"]);
  if (this:del-alias(name))
    player:tell("Successful.\n");
  else
    player:tell("Permission denied.\n");
}
set-setuid(Thing:@unalias-verb, false);
Thing:add-verb(#obj, #@unalias-verb, ["@unalias ", #obj, " as ", #name]);

define method (Thing) look() {
  [
   "\n",
   this.name, "\n",
   make-string(length(this.name), "~") + "\n"
  ] + map(function (x) pronoun-sub(x, this), this:description());
}
make-method-overridable(Thing:look, true);

define method (Thing) look-verb(bindings) {
  realuid():mtell(this:look());
}
Thing:add-verb(#obj, #look-verb, ["look ", #obj]);
Thing:add-verb(#obj, #look-verb, ["look at ", #obj]);

define method (Thing) examine() {
  define s = this:fullname() + " (owned by " + owner(this):fullname() + ")\n";

  s = s + "Location: " + get-print-string(location(this)) + "\n";

  s = s + "Contents: " + string-wrap-string(get-print-string(map(function (x) x:fullname(),
 								 contents(this))), 0) + "\n";

  {
    define al = this:aliases();

    if (length(al) > 0) {
      s = s + "Aliases: " + al[0];
      s = reduce(function (acc, al) acc + ", " + al, s, section(al, 1, length(al) - 1)) + "\n";
    }
  }

  {
    define pa = parents(this);

    if (length(pa) > 0) {
      s = s + "Parent(s): " + pa[0]:fullname();
      s = reduce(function (acc, par) acc + ", " + par:fullname(), s,
		 section(pa, 1, length(pa) - 1)) +
	"\n";
    }
  }

  s = s + "Methods: " + string-wrap-string(get-print-string(methods(this)), 0) + "\n";
  s = s + "Slots: " + string-wrap-string(get-print-string(slots(this)), 0) + "\n";
  s = s + "Verbs: " + string-wrap-string(get-print-string(map(function (v) v[2], this.verbs)),
					 0) + "\n";

  s;
}
make-method-overridable(Thing:examine, true);

define method (Thing) @examine-verb(b) {
  realuid():tell(this:examine());
}
Thing:add-verb(#obj, #@examine-verb, ["@examine ", #obj]);

define method (Thing) @who-verb(b) {
  define p = realuid();
  p:tell("Currently connected players:\n");

  lock(Login);
  define ap = Login.active-players;
  unlock(Login);

  for-each(function (pl) p:tell("\t" + pl:fullname() + " is in " + location(pl):fullname() + ".\n"), ap);
}
Thing:add-verb(#this, #@who-verb, ["@who"]);

define method (Thing) @verbs-verb(b) {
  define vbs = ["Verbs defined on " + this:fullname() + " and it's parents:\n"];

  define function tellverbs(x) {
    vbs = vbs + ["  (" + x:fullname() + ")\n"];
    for-each(function (v) {
      vbs = vbs + [
		   "\t" +				// get-print-string(v[2]) + ": " +
		   reduce(function (acc, e) acc + (if (type-of(e) == #symbol)
						   "<" + get-print-string(e) + ">";
						   else e),
			  "",
			  v[0]) +
		   "\n"];
    }, x.verbs);

    if (x != Thing)
      for-each(tellverbs, parents(x));
  }

  tellverbs(this);
  realuid():mtell(vbs);
}
Thing:add-verb(#obj, #@verbs-verb, ["@verbs ", #obj]);

define method (Thing) @space-verb(b) {
  define oldloc = location(this);
  if (this:space()) {
    oldloc:announce([realuid().name, " spaces ", this, ".\n"]);
    realuid():tell("You have @spaced " + get-print-string(this) + ".\n");
    return true;
  } else {
    realuid():tell("You have no permission to @space that object.\n");
    return false;
  }
}
set-setuid(Thing:@space-verb, false);
Thing:add-verb(#obj, #@space-verb, ["@space ", #obj]);

define method (Thing) @dispose-verb(b) {
  if (this:@space-verb(b))
    Registry:deregister(this);
}
set-setuid(Thing:@dispose-verb, false);
Thing:add-verb(#obj, #@dispose-verb, ["@dispose ", #obj]);

define method (Thing) @setcloneable-verb(b) {
  define val = b[#yes/no/true/false][0];
  define ptell = realuid():tell;

  val = !(equal?(val, "no") || equal?(val, "false"));
  if (this:set-cloneable(val))
    ptell("Your @setcloneable operation for " + this.name + " succeeded.\n");
  else
    ptell("Your @setcloneable operation for " + this.name + " failed.\n");
}
set-setuid(Thing:@setcloneable-verb, false);
Thing:add-verb(#obj, #@setcloneable-verb, ["@setcloneable ", #obj, " to ", #yes/no/true/false]);

checkpoint();
shutdown();
.
