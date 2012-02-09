package markup;
import haxe.unit.TestCase;
import tink.util.Embed;
using StringTools;
using Lambda;
/**
 * ...
 * @author back2dos
 */

class MarkupTestBase extends TestCase {
	function notWhite(x:Xml) {
		return !(x.nodeType != Xml.Element && x.nodeValue.trim().length == 0);
	}
	function testHxExample() {
        var town = new Town("Paris");
		
        town.addUser( new User("Marcel",88) );
        town.addUser( new User("Julie",15) );
        town.addUser( new User("Akambo", 2) );
		
		checkXML(printTown(town), Embed.stringFromFile('hx_example.xml'));
	}
	function printEntries(entries):String {
		return throw 'abstract';
	}
	#if !flash9 //cannot run this test on flash9, because the platform won't allow to set the default namespace
		function testHamlExample() {
			var entries = [{
				title: 'Halloween',
				posted: new Date(2006, 9, 31, 0, 0, 0),
				body: "Happy Halloween, glorious readers! I'm going to a party this evening... I'm very excited.",
			}, {
				title: 'New Rails Templating Engine',
				posted: new Date(2006, 7, 11, 0, 0, 0),
				body: "There's a very cool new Templating Engine out for Ruby on Rails. It's called Haml.",
			}];
			
			checkXML(printEntries(entries), Embed.stringFromFile('haml_example.xml'));			
		}
	#end	
	function printTown(town:Town):String {
		return throw 'abstract';
	}
	function compare(x1:Xml, x2:Xml) {
		assertEquals(x1.nodeType, x2.nodeType);
		switch (x1.nodeType) {
			case Xml.Element:
				assertEquals(x1.nodeName, x2.nodeName);
				for (a in x1.attributes())
					assertEquals(x1.get(a), x2.get(a));
				for (a in x2.attributes())
					assertEquals(x1.get(a), x2.get(a));
				var c1 = x1.filter(notWhite).array(),
					c2 = x2.filter(notWhite).array();
				if (c1.length != c2.length) {
					trace('expected children:\n'+c1.join('\n'));
					trace('found children:\n'+c2.join('\n'));
				}
				assertEquals(c1.length, c2.length);
				for (c in c1)
					compare(c, c2.shift());
			default: assertEquals(x1.nodeValue.trim(), x2.nodeValue.trim());
		}
	}
	function checkXML(result:String, against:String) {
		compare(
			Xml.parse(against).firstElement(), 
			Xml.parse(result).firstElement()
		);
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