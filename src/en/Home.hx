package en;

class Home extends Entity {
	public static var ALL : Array<Home> = [];

	var data : World.Entity_Home;

	public function new(e:World.Entity_Home) {
		data = e;
		super(e.cx, e.cy);
		ALL.push(this);
		carriageWidth = data.f_keepRadius*Const.GRID * 0.75;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function startCarrying(e:Entity) {
		super.startCarrying(e);
		// for(h in ItemGen.ALL)
		// 	h.reset();
	}

	override function update() {
		super.update();

		// Grab items
		for(e in en.Item.ALL) {
			if( e.isAlive() && !isCarrying(e) && distCase(e)<=data.f_grabRadius) {
				if( hero.isCarrying(e) ) {
					hero.stopCarrying(e);
					e.collidesWithWalls = false;
					e.bump(
						e.dirTo(this)*rnd(0.30,0.35),
						-rnd(0.2,0.3)
					);
					e.cd.setS("heroPickLock",2);
					e.cd.setS("homePickLock",rnd(0.1,0.3));
				}
				else if( !e.cd.has("homePickLock") )
					startCarrying(e);
			}
		}

		// Discard old excess items
		if( carriedEnts.length>25 ) {
			var e = carriedEnts[0];
			stopCarrying(e);
			e.destroy();
		}

		// Shake home items constantly
		for(e in carriedEnts)
			e.carriedShaking = 1;
	}
}

