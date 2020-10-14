package en;

class ItemGen extends Entity {
	public static var ALL : Array<ItemGen> = [];

	var data : World.Entity_ItemGenerator;
	var children : Array<Item> = [];

	public function new(e:World.Entity_ItemGenerator) {
		data = e;
		super(e.cx, e.cy);

		ALL.push(this);

		xr = 0.5;
		yr = 0.5;
		gravityMul = 0;
		collidesWithWalls = false;
	}

	function spawn() {
		var i = new Item(data.f_type, cx,cy);

		// Pick spawn point
		var dh = new dn.DecisionHelper( dn.Bresenham.getDisc(cx,cy,data.f_radius) );
		switch data.f_spawnMode {
			case FloatInAir:
				dh.keepOnly( (pt)->!level.hasCollision(pt.x,pt.y) );
				dh.keepOnly( (pt)->sightCheckCase(pt.x,pt.y) );

			case OnGround:
				dh.keepOnly( (pt)->!level.hasCollision(pt.x,pt.y) && level.hasCollision(pt.x,pt.y+1) );
		}
		dh.score( pt->{
			for( e in children )
				if( e.cx==pt.x && e.cy==pt.y )
					return -10;
				else if( e.distCaseFree(pt.x,pt.y)<=1 )
					return -1;
			return 0;
		} );
		dh.score( pt->rnd(0,0.5) );
		dh.useBest( (pt)-> i.setPosCase(pt.x,pt.y) );

		// Adjust
		switch data.f_spawnMode {
			case FloatInAir:
				i.gravityMul = 0;

			case OnGround:
				i.dx = rnd(0, 0.1, true);
				i.dy = -rnd(0.2,0.4);
		}

		children.push(i);
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function update() {
		super.update();

		var i = 0;
		while( i<children.length ) {
			var e = children[i];
			if( !e.isAlive() || e.isCarried() ) {
				e.gravityMul = 1;
				children.splice(i,1);
			}
			else
				i++;
		}

		// if( children.length==data.f_maxChildren || distCase(hero)<=6 )
		if( children.length==data.f_maxChildren )
			cd.setS("spawnLock", rnd(8,10), false);
		else if( distCase(hero)<=6 )
			cd.setS("spawnLock", rnd(2,4), false);
		else if( !cd.has("spawnLock") && !cd.has("spawnTick") ) {
			cd.setS("spawnTick", rnd(1,5));
			spawn();
		}

		fx.markerEntity(this, cd.has("spawnLock") ? 0xff0000 : 0x00ff00, true);
	}
}

