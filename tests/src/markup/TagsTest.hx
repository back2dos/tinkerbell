package markup;
import haxe.Resource;
import haxe.Template;
import haxe.unit.TestCase;
import haxe.xml.Fast;
import tink.Debug;
import tink.util.Embed;

import tink.markup.Tags;

using Lambda;
using DateTools;
using StringTools;

/**
 * ...
 * @author back2dos
 */

class TagsTest extends TestCase {
	public function new() {
		super();
	}
	function notWhite(x:Xml) {
		return !(x.nodeType != Xml.Element && x.nodeValue.trim().length == 0);
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
					trace(c1);
					trace(c2);
				}
				assertEquals(c1.length, c2.length);
				for (c in c1)
					compare(c, c2.shift());
			default: assertEquals(x1.nodeValue.trim(), x2.nodeValue.trim());
		}
	}
	function checkXML(result:Xml, against:String) {
		compare(Xml.parse(against).firstElement(), Xml.parse(result.toString()).firstElement());
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
			
			var t = Tags.build(
				html={ xmlns:"http://www.w3.org/1999/xhtml", lang:"en",  "xml:lang":"en"}(
					head(
						title('BoBlog'),
						meta={ "http-equiv":"Content-Type", content:"text/html; charset=utf-8" },
						link = { rel:"stylesheet", "href":"main.css", type:"text/css" }
					),
					body(
						[$header](
							h1('BoBlog'),
							h2('Bob\'s Blog')
						),
						[$content](
							for (entry in entries)
								[entry](
									h3[title](entry.title),
									p[date](entry.posted.format('%m/%d/%y')),
									p[body](entry.body)
								)
						)
					),
					[$footer](p('All content copyright © Bob'))
				)
			);
			checkXML(t, Embed.stringFromFile('haml_example.xml'));
			
		}
	#end
	function testHxExample() {
        var town = new Town("Paris");
		
        town.addUser( new User("Marcel",88) );
        town.addUser( new User("Julie",15) );
        town.addUser( new User("Akambo", 2) );
		var count = 1;
		function ageGroup(user:User) 
			return 
				if (user.age > 18) 
					'Grown-Up';
				else if (user.age <= 2) 
					'Baby';
				else 
					'Young';
		var t = tink.markup.Tags.build(
			[$content.foo.bar](
				'The habitants of ${em(town.name)} are',
				for (user in town.users) 
					li={age:user.age}(user.name,' ', ageGroup(user))
			)
		);
		checkXML(t, Embed.stringFromFile('hx_example.xml'));
	}
}

private class User {
    public var name:String;
    public var age:Int;
    public function new(name,age) {
        this.name = name;
        this.age = age;    
    }
}

private class Town {
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
