package markup;
import haxe.PosInfos;
import haxe.Template;
import tink.markup.Build;
import tink.devtools.Benchmark;
import tink.util.Embed;
/**
 * ...
 * @author back2dos
 */
class SpeedTest {
	

	static public function run(?count = 10000) {
        var town = new Town("Paris");
		
        town.addUser( new User("Marcel",88) );
        town.addUser( new User("Julie",15) );
        town.addUser( new User("Akambo", 2) );
		
		var r = Benchmark.measure('tink fast', Build.fast(
			$div(
				'The habitants of ${$em < town.name} are:',
				$ul < for (u in town.users) 
					$li('${u.name} ', (u.age > 18) ? 'Grown-Up' : (u.age <= 2) ? 'Baby' : 'Young')
			)
		).toString(), count);
		#if neko
			mtwin.templo.Loader.TMP_DIR = "";
			mtwin.templo.Loader.MACROS = null;
			var s = Embed.stringFromFile('tpl.mtt');
			var t = mtwin.templo.Template.fromString(s);
			var r = Benchmark.measure('templo', {
				t(town);
			}, count);
		#end
		
		var s = Embed.stringFromFile('tpl.hxt');
		var t = new Template(s);
		var r = Benchmark.measure('hx', {
			t.execute(town);
		}, count);
		
		var r = Benchmark.measure('tink xml', Build.xml(
			$div(
				'The habitants of ${$em < town.name} are:',
				$ul < for (u in town.users) 
					$li('${u.name} ', (u.age > 18) ? 'Grown-Up' : (u.age <= 2) ? 'Baby' : 'Young')
			)
		).toString(), count);				
		
		#if erazor
			var s = Embed.stringFromFile('tpl.ezt');
			var t = new erazor.Template(s);
			var r = Benchmark.measure('erazor/10', {
				t.execute(town);
			}, Std.int(count / 10));
		#end
	}	
}
class User {
    public var name:String;
    public var age:Int;
    public function new(name,age) {
        this.name = name;
        this.age = age;    
    }
}

class Town {
    public var name:String;
    public var users:Array<User>;
    public function new( name ) {
        this.name = name;
        users = new Array();
    }
    public function addUser(u) {
        users.push(u);
    }
}