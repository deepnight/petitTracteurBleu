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
			// Take out of hero hands
			if( e.isAlive() && !isCarrying(e) && distCase(e)<=data.f_grabRadius && hero.isCarrying(e) ) {
				hero.stopCarrying(e);
				e.cd.setS("homePicked",Const.INFINITE);
				e.hasWallCollisions = false;
				e.cancelVelocities();
				e.setPosPixel(game.cart.footX, game.cart.footY-7);
				e.bump(0, -rnd(0.2,0.3) );
				e.cd.setS("heroPickLock",2);
				e.cd.setS("homePickLock",rnd(0.1,0.3));
			}

			// Add to carriage
			if( !e.cd.has("homePickLock") && e.cd.has("homePicked") ) {
				e.cd.unset("homePicked");
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

