class Entity {
    public static var ALL : Array<Entity> = [];
    public static var GC : Array<Entity> = [];

	// Various getters to access all important stuff easily
	public var game(get,never) : Game; inline function get_game() return Game.ME;
	public var fx(get,never) : Fx; inline function get_fx() return Game.ME.fx;
	public var level(get,never) : Level; inline function get_level() return Game.ME.level;
	public var destroyed(default,null) = false;
	public var ftime(get,never) : Float; inline function get_ftime() return game.ftime;
	var tmod(get,never) : Float; inline function get_tmod() return Game.ME.tmod;
	var utmod(get,never) : Float; inline function get_utmod() return Game.ME.utmod;
	public var hud(get,never) : ui.Hud; inline function get_hud() return Game.ME.hud;
	public var hero(get,never) : en.Hero; inline function get_hero() return Game.ME.hero;

	public var onGround(get,never) : Bool;
		inline function get_onGround() return !isAlive() ? true : yr==1 && level.hasCollision(cx,cy+1) && dyTotal==0;

	public var onGroundRecently(get,never) : Bool;
		inline function get_onGroundRecently() return onGround || isAlive() && cd.has("wasOnGround");

	/** Cooldowns **/
	public var cd : dn.Cooldown;

	/** Cooldowns, unaffected by slowmo (ie. always in realtime) **/
	public var ucd : dn.Cooldown;

	/** Temporary gameplay affects **/
	var affects : Map<Affect,Float> = new Map();

	/** Unique identifier **/
	public var uid : Int;
	public var randVal = rnd(0,1);

	// Position in the game world
    public var cx = 0;
    public var cy = 0;
    public var xr = 0.5;
    public var yr = 1.0;

	// Velocities
    public var dx = 0.;
	public var dy = 0.;
	public var gravityMul = 1.0;

	// Uncontrollable bump velocities, usually applied by external
	// factors (think of a bumper in Sonic for example)
    public var bdx = 0.;
	public var bdy = 0.;

	// Velocities + bump velocities
	public var dxTotal(get,never) : Float; inline function get_dxTotal() return dx+bdx;
	public var dyTotal(get,never) : Float; inline function get_dyTotal() return dy+bdy;

	// Multipliers applied on each frame to normal velocities
	public var frictX = 0.82;
	public var frictY = 0.82;

	// Multiplier applied on each frame to bump velocities
	public var bumpFrict = 0.93;

	public var hei(default,set) : Float = Const.GRID;
	inline function set_hei(v) { invalidateDebugBounds=true;  return hei=v; }

	public var radius(default,set) = Const.GRID*0.5;
	inline function set_radius(v) { invalidateDebugBounds=true;  return radius=v; }

	/** Horizontal direction, can only be -1 or 1 **/
	public var dir(default,set) = 1;

	// Sprite transformations
	public var sprScaleX = 1.0;
	public var sprScaleY = 1.0;
	public var sprSquashX = 1.0;
	public var sprSquashY = 1.0;
	public var sprRotation = 0.;
	public var entityVisible = true;

	// Hit points
	public var life(default,null) : Int;
	public var maxLife(default,null) : Int;
	public var lastDmgSource(default,null) : Null<Entity>;

	public var lastHitDirFromSource(get,never) : Int;
	inline function get_lastHitDirFromSource() return lastDmgSource==null ? -dir : -dirTo(lastDmgSource);

	public var lastHitDirToSource(get,never) : Int;
	inline function get_lastHitDirToSource() return lastDmgSource==null ? dir : dirTo(lastDmgSource);

	// Visual components
    public var spr : HSprite;
	public var baseColor : h3d.Vector;
	public var blinkColor : h3d.Vector;
	public var colorMatrix : h3d.Matrix;

	// Debug stuff
	var debugLabel : Null<h2d.Text>;
	var debugBounds : Null<h2d.Graphics>;
	var invalidateDebugBounds = false;

	// Coordinates getters, for easier gameplay coding
	public var footX(get,never) : Float; inline function get_footX() return (cx+xr)*Const.GRID;
	public var footY(get,never) : Float; inline function get_footY() return (cy+yr)*Const.GRID;
	public var headX(get,never) : Float; inline function get_headX() return footX;
	public var headY(get,never) : Float; inline function get_headY() return footY-hei;
	public var centerX(get,never) : Float; inline function get_centerX() return footX;
	public var centerY(get,never) : Float; inline function get_centerY() return footY-hei*0.5;
	public var prevFrameFootX : Float = -Const.INFINITE;
	public var prevFrameFootY : Float = -Const.INFINITE;

	var actions : Array<{ id:String, cb:Void->Void, t:Float }> = [];

	var carriedEnts : Array<Entity> = [];
	var carrier : Null<Entity>;
	var carriedShaking : Float = 0.;
	var carriageWidth: Float = 1.;
	var carriedRandOffset : Float;
	var carriedScale = 1.0;

	var hasWallCollisions = true;
	var hasCartoonDistorsion = true;
	var layer = -1;


    public function new(x:Int, y:Int) {
        uid = Const.NEXT_UNIQ;
		ALL.push(this);
		carriedRandOffset = rnd(-1,1);

		cd = new dn.Cooldown(Const.FPS);
		ucd = new dn.Cooldown(Const.FPS);
        setPosCase(x,y);

        spr = new HSprite(Assets.tiles);
		addToLayer(Const.DP_MAIN);
		spr.colorAdd = new h3d.Vector();
		baseColor = new h3d.Vector();
		blinkColor = new h3d.Vector();
		spr.colorMatrix = colorMatrix = h3d.Matrix.I();
		spr.setCenterRatio(0.5,1);

		if( ui.Console.ME.hasFlag("bounds") )
			enableBounds();
	}

	function addToLayer(id:Int) {
		if( layer==id ) {
			game.scroller.over(spr);
			return;
		}

		layer = id;
		Game.ME.scroller.add(spr, id);
	}

	@:keep
	public function toString() {
		return Type.getClassName(Type.getClass(this)) + '@$cx,$cy';
	}

	public function initLife(v) {
		life = maxLife = v;
	}

	public function hit(dmg:Int, from:Null<Entity>) {
		if( !isAlive() || dmg<=0 )
			return;

		life = M.iclamp(life-dmg, 0, maxLife);
		lastDmgSource = from;
		onDamage(dmg, from);
		if( life<=0 )
			onDie();
	}

	public function kill(by:Null<Entity>) {
		if( isAlive() )
			hit(life,by);
	}

	function onDamage(dmg:Int, from:Entity) {
	}

	function onDie() {
		destroy();
	}

	inline function set_dir(v) {
		return dir = v>0 ? 1 : v<0 ? -1 : dir;
	}

	public inline function isAlive() {
		return !destroyed;
	}

	public function setPosCase(x:Int, y:Int) {
		cx = x;
		cy = y;
		xr = 0.5;
		yr = 1;
		onPosManuallyChanged();
	}


	public function startCarrying(e:Entity) {
		if( !isCarrying(e) ) {
			if( e.isCarried() )
				e.carrier.stopCarrying(e);
			carriedEnts.push(e);
			e.carrier = this;
			e.onBeingCarried(this);
		}
	}

	public function stopCarrying(e:Entity) {
		if( carriedEnts.remove(e) ) {
			e.setPosCase(cx,cy);
			e.xr = xr;
			e.yr = yr;
			e.carrier = null;
			e.onStopBeingCarried(this);
		}
	}

	public function stopCarryingAnything() {
		if( carriedEnts.length==0 )
			return;

		for(e in carriedEnts.copy() )
			stopCarrying(e);
	}

	public function onBeingCarried(by:Entity) {}
	public function onStopBeingCarried(by:Entity) {}

	public function getCarriageX(offset:Float) return footX + carriageWidth * offset;
	public function getCarriageY(offset:Float) return footY;

	public function getCarrier() : Null<Entity> {
		for(e in ALL)
			if( e.isCarrying(this) )
				return e;
		return null;
	}

	public function isCarrying(e:Entity) {
		for( ce in carriedEnts )
			if( ce==e )
				return true;
		return false;
	}

	public function isCarryingAny() {
		return carriedEnts.length>0;
	}

	public function isCarried() return carrier!=null;


	public function setPosPixel(x:Float, y:Float) {
		cx = Std.int(x/Const.GRID);
		cy = Std.int(y/Const.GRID);
		xr = (x-cx*Const.GRID)/Const.GRID;
		yr = (y-cy*Const.GRID)/Const.GRID;
		onPosManuallyChanged();
	}

	function onPosManuallyChanged() {
		if( M.dist(footX,footY,prevFrameFootX,prevFrameFootY) > Const.GRID*2 ) {
			prevFrameFootX = footX;
			prevFrameFootY = footY;
		}
	}

	public function bump(x:Float,y:Float) {
		bdx+=x;
		bdy+=y;
	}

	public function cancelVelocities() {
		dx = bdx = 0;
		dy = bdy = 0;
	}

	public function is<T:Entity>(c:Class<T>) return Std.isOfType(this, c);
	public function as<T:Entity>(c:Class<T>) : T return Std.downcast(this, c);

	public inline function rnd(min,max,?sign) return Lib.rnd(min,max,sign);
	public inline function irnd(min,max,?sign) return Lib.irnd(min,max,sign);
	public inline function pretty(v,?p=1) return M.pretty(v,p);

	public inline function dirTo(e:Entity) return e.centerX<centerX ? -1 : 1;
	public inline function dirToAng() return dir==1 ? 0. : M.PI;
	public inline function angToFeet(e:Entity) return Math.atan2(e.footY-footY, e.footX-footX);
	public inline function getMoveAng() return Math.atan2(dyTotal,dxTotal);

	public inline function distCase(e:Entity) return M.dist(cx+xr, cy+yr, e.cx+e.xr, e.cy+e.yr);
	public inline function distCaseFree(tcx:Int, tcy:Int, ?txr=0.5, ?tyr=0.5) return M.dist(cx+xr, cy+yr, tcx+txr, tcy+tyr);

	public inline function distPx(e:Entity) return M.dist(footX, footY, e.footX, e.footY);
	public inline function distPxFree(x:Float, y:Float) return M.dist(footX, footY, x, y);

	inline function canSeeThrough(x,y) {
		return x==cx && y==cy ? true : !level.hasCollision(x,y);
	}

	public inline function sightCheckCase(x,y) {
		return dn.Bresenham.checkThinLine(cx,cy, x,y, canSeeThrough);
	}

	public inline function sightCheck(e:Entity) {
		return sightCheckCase(e.cx,e.cy);
	}

	public function makePoint() return new CPoint(cx,cy, xr,yr);

    public inline function destroy() {
        if( !destroyed ) {
            destroyed = true;
            GC.push(this);
        }
    }

    public function dispose() {
		ALL.remove(this);

		// Drop carrieds
		for(e in carriedEnts)
			if( e.isAlive() )
				e.onStopBeingCarried(this);
		carriedEnts = null;

		baseColor = null;
		blinkColor = null;
		colorMatrix = null;

		spr.remove();
		spr = null;

		if( debugLabel!=null ) {
			debugLabel.remove();
			debugLabel = null;
		}

		if( debugBounds!=null ) {
			debugBounds.remove();
			debugBounds = null;
		}

		cd.dispose();
		cd = null;
    }

	public inline function debugFloat(v:Float, ?c=0xffffff) {
		debug( pretty(v), c );
	}
	public inline function debug(?v:Dynamic, ?c=0xffffff) {
		#if debug
		if( v==null && debugLabel!=null ) {
			debugLabel.remove();
			debugLabel = null;
		}
		if( v!=null ) {
			if( debugLabel==null )
				debugLabel = new h2d.Text(Assets.fontTiny, Game.ME.scroller);
			debugLabel.text = Std.string(v);
			debugLabel.textColor = c;
		}
		#end
	}

	public function disableBounds() {
		if( debugBounds!=null ) {
			debugBounds.remove();
			debugBounds = null;
		}
	}


	public function enableBounds() {
		if( debugBounds==null ) {
			debugBounds = new h2d.Graphics();
			game.scroller.add(debugBounds, Const.DP_TOP);
		}
		invalidateDebugBounds = true;
	}

	function renderBounds() {
		var c = Col.fromHsl((uid%20)/20, 1, 1);
		debugBounds.clear();

		// Radius
		debugBounds.lineStyle(1, c, 0.8);
		debugBounds.drawCircle(0,-radius,radius);

		// Hei
		debugBounds.lineStyle(1, c, 0.5);
		debugBounds.drawRect(-radius,-hei,radius*2,hei);

		// Feet
		debugBounds.lineStyle(1, 0xffffff, 1);
		var d = Const.GRID*0.2;
		debugBounds.moveTo(-d,0);
		debugBounds.lineTo(d,0);
		debugBounds.moveTo(0,-d);
		debugBounds.lineTo(0,0);

		// Center
		debugBounds.lineStyle(1, c, 0.3);
		debugBounds.drawCircle(0, -hei*0.5, 3);

		// Head
		debugBounds.lineStyle(1, c, 0.3);
		debugBounds.drawCircle(0, headY-footY, 3);
	}

	function chargeAction(id:String, sec:Float, cb:Void->Void) {
		if( isChargingAction(id) )
			cancelAction(id);
		if( sec<=0 )
			cb();
		else
			actions.push({ id:id, cb:cb, t:sec});
	}

	public function isChargingAction(?id:String) {
		if( id==null )
			return actions.length>0;

		for(a in actions)
			if( a.id==id )
				return true;

		return false;
	}

	public function cancelAction(?id:String) {
		if( id==null )
			actions = [];
		else {
			var i = 0;
			while( i<actions.length ) {
				if( actions[i].id==id )
					actions.splice(i,1);
				else
					i++;
			}
		}
	}

	function updateActions() {
		var i = 0;
		while( i<actions.length ) {
			var a = actions[i];
			a.t -= tmod/Const.FPS;
			if( a.t<=0 ) {
				actions.splice(i,1);
				if( isAlive() )
					a.cb();
			}
			else
				i++;
		}
	}


	public inline function hasAffect(k:Affect) {
		return affects.exists(k) && affects.get(k)>0;
	}

	public inline function getAffectDurationS(k:Affect) {
		return hasAffect(k) ? affects.get(k) : 0.;
	}

	public function setAffectS(k:Affect, t:Float, ?allowLower=false) {
		if( affects.exists(k) && affects.get(k)>t && !allowLower )
			return;

		if( t<=0 )
			clearAffect(k);
		else {
			var isNew = !hasAffect(k);
			affects.set(k,t);
			if( isNew )
				onAffectStart(k);
		}
	}

	public function mulAffectS(k:Affect, f:Float) {
		if( hasAffect(k) )
			setAffectS(k, getAffectDurationS(k)*f, true);
	}

	public function clearAffect(k:Affect) {
		if( hasAffect(k) ) {
			affects.remove(k);
			onAffectEnd(k);
		}
	}

	function updateAffects() {
		for(k in affects.keys()) {
			var t = affects.get(k);
			t-=1/Const.FPS * tmod;
			if( t<=0 )
				clearAffect(k);
			else
				affects.set(k,t);
		}
	}

	function onAffectStart(k:Affect) {}
	function onAffectEnd(k:Affect) {}

	public function isConscious() {
		return !hasAffect(Stun) && isAlive();
	}

	public function blink(c:UInt) {
		blinkColor.setColor(c);
		cd.setS("keepBlink",0.06);
	}


	public function setSquashX(v:Float) {
		sprSquashX = v;
		sprSquashY = 2-v;
	}
	public function setSquashY(v:Float) {
		sprSquashX = 2-v;
		sprSquashY = v;
	}

    public function preUpdate() {
		ucd.update(utmod);
		cd.update(tmod);
		updateAffects();
		updateActions();
    }

    public function postUpdate() {
        spr.x = Std.int( footX );
        spr.y = Std.int( footY );
        spr.scaleX = dir*sprScaleX * sprSquashX * (isCarried()?carriedScale:1);
        spr.scaleY = sprScaleY * sprSquashY * (isCarried()?carriedScale:1);
		spr.visible = entityVisible;
		spr.rotation = sprRotation;

		// Cartoon distortion
		if( hasCartoonDistorsion ) {
			var t = ftime*0.1 + uid;
			spr.scaleX *= 1 + Math.cos(t)*0.15;
			spr.scaleY *= 1 + Math.sin(t)*0.15;
		}

		sprSquashX += (1-sprSquashX) * M.fclamp(0.12*tmod, 0, 1);
		sprSquashY += (1-sprSquashY) * M.fclamp(0.12*tmod, 0, 1);

		if( isCarried() ) {
			spr.x += 6*carriedRandOffset;
			spr.x += Math.cos(ftime*0.07 + uid*1.1) * (5+(uid%3))*carriageWidth * carriedShaking;
			spr.y += -M.fabs( Math.sin(ftime*0.13 + uid*0.9) * (5+(uid%5)) ) * carriedShaking;
		}
		carriedShaking *= Math.pow(0.98,tmod);

		// Blink
		if( !cd.has("keepBlink") ) {
			blinkColor.r*=Math.pow(0.60, tmod);
			blinkColor.g*=Math.pow(0.55, tmod);
			blinkColor.b*=Math.pow(0.50, tmod);
		}

		// Color adds
		spr.colorAdd.load(baseColor);
		spr.colorAdd.r += blinkColor.r;
		spr.colorAdd.g += blinkColor.g;
		spr.colorAdd.b += blinkColor.b;

		// Debug label
		if( debugLabel!=null ) {
			debugLabel.x = Std.int(footX - debugLabel.textWidth*0.5);
			debugLabel.y = Std.int(footY+1);
		}

		// Debug bounds
		if( debugBounds!=null ) {
			if( invalidateDebugBounds ) {
				invalidateDebugBounds = false;
				renderBounds();
			}
			debugBounds.x = footX;
			debugBounds.y = footY;
		}
	}

	public function finalUpdate() {
		prevFrameFootX = footX;
		prevFrameFootY = footY;
	}

	function onLand() {
	}


	inline function hasCollisionsWithWalls() {
		return !isCarried() && hasWallCollisions;
	}

	public function fixedUpdate() {} // runs at a "guaranteed" 30 fps

	public function update() { // runs at an unknown fps
		// Lost carrier
		if( carrier!=null && !carrier.isAlive() ) {
			var e = carrier;
			onStopBeingCarried(e);
			carrier = null;
		}

		// Lost carried(s)
		var i = 0;
		while( i<carriedEnts.length ) {
			if( !carriedEnts[i].isAlive() )
				carriedEnts.splice(i,1);
			else
				i++;
		}

		// Follow carrier
		if( isCarried() && !cd.has("carriedFollowLock")) {
			bdx = bdy = 0;
			var tx = carrier.getCarriageX(carriedRandOffset);
			var ty = carrier.getCarriageY(carriedRandOffset);
			if( M.dist(footX, footY, tx, ty) > 0.2*Const.GRID ) {
				var a = Math.atan2(ty-footY, tx-footX);
				dx+=Math.cos(a)*0.08 * tmod;
				dy+=Math.sin(a)*0.11 * tmod;
			}
			if( M.dist(footX, footY, tx, ty) <= 0.2*Const.GRID*tmod ) {
				// Brake on approach to avoid shaking on slow devices
				dx *= Math.pow(0.8,tmod);
				dy *= Math.pow(0.8,tmod);
			}

			dx *= Math.pow(0.92,tmod);
			dy *= Math.pow(0.92,tmod);
		}

		// Shake carriage
		if( M.fabs(dxTotal)>0.03/tmod || M.fabs(dyTotal)>0.03/tmod ) {
			for(e in carriedEnts)
				e.carriedShaking = M.fclamp( e.carriedShaking + 0.05*tmod, 0, 1 );
		}

		// X
		var steps = M.ceil( M.fabs(dxTotal*tmod) );
		var step = dxTotal*tmod / steps;
		while( steps>0 ) {
			xr+=step;

			if( hasCollisionsWithWalls() && level.hasCollision(cx+1,cy) && xr>0.65 ) {
				dx *= Math.pow(0.9,tmod);
				xr = 0.65;
			}

			if( hasCollisionsWithWalls() && level.hasCollision(cx-1,cy) && xr<0.35 ) {
				dx *= Math.pow(0.9,tmod);
				xr = 0.35;
			}

			while( xr>1 ) { xr--; cx++; }
			while( xr<0 ) { xr++; cx--; }
			steps--;
		}
		dx*=Math.pow(frictX,tmod);
		bdx*=Math.pow(bumpFrict,tmod);
		if( M.fabs(dx)<=0.0005*tmod ) dx = 0;
		if( M.fabs(bdx)<=0.0005*tmod ) bdx = 0;

		// Y
		if( onGround || isCarried() )
			cd.setS("wasOnGround",0.25);
		else
			dy += gravityMul * Const.GRAVITY * tmod;

		var steps = M.ceil( M.fabs(dyTotal*tmod) );
		var step = dyTotal*tmod / steps;
		while( steps>0 ) {
			yr+=step;

			if( hasCollisionsWithWalls() && yr>1 && level.hasCollision(cx,cy+1) ) {
				yr = 1;
				dy = 0;
				bdx *= 0.66;
				bdy = 0;
				onLand();
			}

			while( yr>1 ) { yr--; cy++; }
			while( yr<0 ) { yr++; cy--; }
			steps--;
		}
		dy*=Math.pow(frictY,tmod);
		bdy*=Math.pow(bumpFrict,tmod);
		if( M.fabs(dy)<=0.0005*tmod ) dy = 0;
		if( M.fabs(bdy)<=0.0005*tmod ) bdy = 0;


		#if debug
		if( ui.Console.ME.hasFlag("affect") ) {
			var all = [];
			for(k in affects.keys())
				all.push( k+"=>"+M.pretty( getAffectDurationS(k) , 1) );
			debug(all);
		}

		if( ui.Console.ME.hasFlag("bounds") && debugBounds==null )
			enableBounds();

		if( !ui.Console.ME.hasFlag("bounds") && debugBounds!=null )
			disableBounds();
		#end
    }
}