import h2d.Sprite;
import dn.heaps.HParticle;
import dn.Tweenie;


class Fx extends dn.Process {
	var game(get,never) : Game; inline function get_game() return Game.ME;
	var level(get,never) : Level; inline function get_level() return Game.ME.level;

	public var pool : ParticlePool;

	public var bgAddSb    : h2d.SpriteBatch;
	public var bgNormalSb    : h2d.SpriteBatch;
	public var topAddSb       : h2d.SpriteBatch;
	public var topNormalSb    : h2d.SpriteBatch;

	public function new() {
		super(Game.ME);

		pool = new ParticlePool(Assets.tiles.tile, 2048, Const.FPS);

		bgAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bgAddSb, Const.DP_FX_BG);
		bgAddSb.blendMode = Add;
		bgAddSb.hasRotationScale = true;

		bgNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(bgNormalSb, Const.DP_FX_BG);
		bgNormalSb.hasRotationScale = true;

		topNormalSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(topNormalSb, Const.DP_FX_FRONT);
		topNormalSb.hasRotationScale = true;

		topAddSb = new h2d.SpriteBatch(Assets.tiles.tile);
		game.scroller.add(topAddSb, Const.DP_FX_FRONT);
		topAddSb.blendMode = Add;
		topAddSb.hasRotationScale = true;
	}

	override public function onDispose() {
		super.onDispose();

		pool.dispose();
		bgAddSb.remove();
		bgNormalSb.remove();
		topAddSb.remove();
		topNormalSb.remove();
	}

	public function clear() {
		pool.killAll();
	}

	public inline function allocTopAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topAddSb, t, x, y);
	}

	public inline function allocTopNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(topNormalSb, t,x,y);
	}

	public inline function allocBgAdd(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgAddSb, t,x,y);
	}

	public inline function allocBgNormal(t:h2d.Tile, x:Float, y:Float) : HParticle {
		return pool.alloc(bgNormalSb, t,x,y);
	}

	public inline function getTile(id:String) : h2d.Tile {
		return Assets.tiles.getTileRandom(id);
	}

	public function killAll() {
		pool.killAll();
	}

	public function markerEntity(e:Entity, ?c=0xFF00FF, ?short=false) {
		#if debug
		if( e==null )
			return;

		markerCase(e.cx, e.cy, short?0.03:3, c);
		#end
	}

	public function markerCase(cx:Int, cy:Int, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile("fxCircle"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.lifeS = sec;

		var p = allocTopAdd(getTile("pixel"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(2);
		p.lifeS = sec;
		#end
	}

	public function markerFree(x:Float, y:Float, ?sec=3.0, ?c=0xFF00FF) {
		#if debug
		var p = allocTopAdd(getTile("fxDot"), x,y);
		p.setCenterRatio(0.5,0.5);
		p.setFadeS(1, 0, 0.06);
		p.colorize(c);
		p.setScale(3);
		p.lifeS = sec;
		#end
	}

	public function markerText(cx:Int, cy:Int, txt:String, col:UInt, ?t=1.0) {
		#if debug
		var tf = new h2d.Text(Assets.fontTiny, topNormalSb);
		tf.text = txt;
		tf.textColor = 0xffffff;

		var p = allocTopAdd(getTile("fxCircle"), (cx+0.5)*Const.GRID, (cy+0.5)*Const.GRID);
		p.colorize(col);
		p.alpha = 0.4;
		p.lifeS = t;
		p.fadeOutSpeed = 0.4;
		p.onKill = tf.remove;

		tf.setPosition(p.x-tf.textWidth*0.5, p.y-tf.textHeight*0.5);
		#end
	}

	inline function collides(p:HParticle, offX=0., offY=0.) {
		return level.hasCollision( Std.int((p.x+offX)/Const.GRID), Std.int((p.y+offY)/Const.GRID) );
	}

	function _dustPhysics(p:HParticle) {
		if( collides(p,0,1) ) {
			p.dx = 0;
			p.dy = 0;
			p.dx*= Math.pow(0.5,tmod);
			p.dr = 0;
			p.gy *= Math.pow(0.96,tmod);
		}
	}

	public function tractorSmoke(x:Float, y:Float, dir:Int) {
		for(i in 0...10) {
			var p = allocBgNormal( getTile("fxSmoke"), x+rnd(0,5,true), y+rnd(0,5,true) );
			p.colorize(0xd7b988);
			p.setFadeS( rnd(0.05,0.10), 0.5, rnd(0.5,1) );
			p.rotation = rnd(0,M.PI2);
			p.dr = rnd(0,0.05,true);
			p.scale = rnd(0.1,0.2);
			p.scaleMul = rnd(1.01,1.02);
			p.dy = -2;
			p.gx = rnd(0.003,0.004);
			p.gy = -rnd(0.010,0.012);
			p.frict = rnd(0.93,0.94);
			p.lifeS = rnd(0.2,0.7);
		}
	}

	public function grass(x:Float, y:Float, dir:Int) {
		for(i in 0...3) {
			var p = allocTopNormal(getTile("fxDust"), x+rnd(0,10,true), y-rnd(0,2));
			p.setFadeS(rnd(0.4,1), 0, rnd(0.2,0.3));
			p.colorize(0x8aab52);
			p.dx = dir*rnd(1,2);
			p.dy = -rnd(1,2);
			// p.gx = rnd(0,0.03);
			p.gy = rnd(0.05,0.10);
			p.frict = rnd(0.94,0.96);

			p.scaleX = rnd(0.3,1,true);
			p.scaleY = rnd(0.3,1,true);
			p.rotation = rnd(0,M.PI2);
			p.dr = rnd(0,0.03,true);

			p.lifeS = rnd(1,2);
			p.onUpdate = _dustPhysics;
		}
	}

	public function pick(x:Float, y:Float) {
		var p = allocTopAdd(getTile("halo"), x,y);
		p.setFadeS(0.3, 0, 1);
		p.colorize(0x348bff);
		p.rotation = rnd(0,M.PI2);
		p.lifeS = 0;


		var n = 8;
		for(i in 0...n) {
			var a = M.PI2*i/n;
			var p = allocTopAdd(getTile("fxImpact"), x,y);
			p.setFadeS(rnd(0.5,0.7), 0, 0.1);
			p.setCenterRatio(1,0.5);
			p.rotation = a;
			p.colorize(0x44c9ff);
			p.scaleX = 0.2;
			p.scaleY = rnd(0.5,1,true) * p.scaleX;
			p.ds = 0.2;
			p.dsFrict = 0.9;
			p.scaleMul = rnd(0.9,0.93);
			p.lifeS = 0.5;
			p.dr = 0.1;
		}
	}

	public function homeDrop(x:Float, y:Float) {
		var c = 0xff5654;
		var p = allocTopAdd(getTile("halo"), x,y);
		p.setFadeS(0.3, 0, 1);
		p.colorize(c);
		p.rotation = rnd(0,M.PI2);
		p.lifeS = 0;

		var n = 50;
		for(i in 0...n) {
			var a = M.PI2*i/n + rnd(0,0.1,true);
			var p = allocTopAdd(getTile("fxLineDir"), x,y);
			p.setFadeS(rnd(0.5,0.7), 0, 0.1);
			p.setCenterRatio(0.8,0.5);
			p.rotation = a;
			p.colorize(c);
			p.scaleX = rnd(0.2,0.5);
			p.scaleY = 2;
			p.ds = 0.2;
			p.dsFrict = 0.9;
			p.scaleMul = rnd(0.9,0.93);
			p.lifeS = 0.5;
			p.dr = rnd(0.02, 0.03, true);
		}
	}

	public function leaves(x:Float, y:Float) {
		for(i in 0...20) {
			var p = allocTopNormal(getTile("fxLeaf"), x+rnd(0,10,true), y+rnd(0,8,true));
			p.setFadeS(rnd(0.4,0.8), rnd(0,0.2), rnd(1,2));
			p.colorize(0xb5e16c);
			p.dx = rnd(0,1,true);
			p.dy = -rnd(0.2,1);
			p.gx = rnd(0,0.01);
			p.gy = rnd(0.01,0.03);
			p.frict = rnd(0.96,0.98);

			p.scaleX = rnd(0.3,1,true);
			p.scaleY = rnd(0.3,1,true);
			p.rotation = rnd(0,M.PI2);
			p.dr = rnd(0,0.03,true);

			p.lifeS = rnd(1,2);
			p.onUpdate = _dustPhysics;
		}
	}

	public function flashBangS(c:UInt, a:Float, ?t=0.1) {
		var e = new h2d.Bitmap(h2d.Tile.fromColor(c,1,1,a));
		game.root.add(e, Const.DP_FX_FRONT);
		e.scaleX = game.w();
		e.scaleY = game.h();
		e.blendMode = Add;
		game.tw.createS(e.alpha, 0, t).end( function() {
			e.remove();
		});
	}

	override function update() {
		super.update();

		pool.update(game.tmod);
	}
}