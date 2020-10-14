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

	override function update() {
		super.update();

		// Grab items
		for(e in en.Item.ALL) {
			if( !isCarrying(e) && distCase(e)<=data.f_grabRadius) {
				if( hero.isCarrying(e) ) {
					hero.stopCarrying(e);
					e.collidesWithWalls = false;
					e.bump(
						e.dirTo(this)*rnd(0.20,0.25),
						-rnd(0.2,0.3)
					);
					e.cd.setS("heroPickLock",2);
					e.cd.setS("homePickLock",rnd(0.2,0.5));
				}
				else if( !e.cd.has("homePickLock") )
					startCarrying(e);
			}
		}

		for(e in carriedEnts)
			e.carriedShaking = 1;

		debug(carriedEnts.length);
	}
}

