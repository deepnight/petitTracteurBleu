package en;

class Item extends Entity {
	public static var ALL : Array<Item> = [];

	var type : World.Enum_Item;
	var neverPicked = true;

	public function new(t:World.Enum_Item, x,y) {
		type = t;
		super(x, y);
		xr = rnd(0.1, 0.9);
		yr = rnd(0.1, 0.9);
		ALL.push(this);

		if( spr.lib.exists("item"+type.getName()) )
			spr.set("item"+type.getName());
		else
			spr.set("itemApple");

		switch type {
			case Wood:
				spr.filter = new dn.heaps.filter.PixelOutline();
				carriedScale = 0.5;

			case Diamond:
				spr.filter = new dn.heaps.filter.PixelOutline(0xffffff);
				carriedScale = 1;

			case Apple:
				hasCartoonDistorsion = false;
				carriedScale = 0.5;

			case Cow:
				hasCartoonDistorsion = false;
		}
	}

	public static function hasAnyLeft() {
		for(e in ALL)
			if( e.isAlive() && ( !e.isCarried() || e.carrier==Game.ME.hero ) )
				return true;
		return false;
	}

	override function dispose() {
		super.dispose();
		ALL.remove(this);
	}

	override function onStopBeingCarried(by:Entity) {
		super.onStopBeingCarried(by);
		cd.setS("heroPickLock",0.5);
	}

	override function onBeingCarried(by:Entity) {
		super.onBeingCarried(by);
		if( by.is(en.Home) ) {
			colorMatrix.load( C.getColorizeMatrixH2d(Const.BG_COLOR, 0.4) );
			spr.alpha = 0.5;
		}


		if( neverPicked ) {
			switch type {
				case Wood:
					fx.pick(footX, footY-8);
					fx.grass(footX, footY, -dirTo(by));

				case Cow:
					fx.pick(footX, footY-8);
					fx.grass(footX, footY, -dirTo(by));

				case Diamond:
					fx.pick(footX, footY-8);

				case Apple:
					fx.pick(footX, footY+4);
					fx.leaves(footX, footY+4);
			}
		}

		neverPicked = false;
	}

	override function postUpdate() {
		super.postUpdate();
		if( gravityMul==0 && !isCarried() ) {
			spr.setCenterRatio(0.5,0.2);
			spr.rotation = Math.cos(ftime*0.1 + randVal*M.PI2) * (0.2 + 0.1*randVal);
		}
		else
			spr.setCenterRatio(0.5,1);

		if( isCarried() )
			addToLayer(Const.DP_BG);
		else
			addToLayer(Const.DP_MAIN);

		if( type==Diamond && !isCarried() && !cd.hasSetS("shineFx",0.1) )
			fx.shine(centerX, centerY, 0x2aadff);
	}

	override function onLand() {
		super.onLand();
		if( type==Cow )
			setSquashY(0.5);
	}

	override function update() {
		super.update();
		var freq = type==Cow ? 0.6 : 0.4;
		if( onGround && !isCarried() && !cd.hasSetS("jump",freq) )
			dy = -0.2;
	}
}

