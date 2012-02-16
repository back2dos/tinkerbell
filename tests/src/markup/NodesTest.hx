package markup;
import haxe.unit.TestCase;
import markup.MarkupTestBase;
import tink.markup.Build;
import tink.util.Embed;
using DateTools;
/**
 * ...
 * @author back2dos
 */

class NodesTest extends MarkupTestBase {
	override function printTown(town:Town):String {
		function ageGroup(user) 
			return 
				if (user.age > 18) 
					'Grown-Up';
				else if (user.age <= 2) 
					'Baby';
				else 
					'Young';
		var t = Build.xml(
			[$content.foo.bar](
				'The habitants of ${em(town.name)} are:',
				ul < for (user in town.users) 
					li([age, likesChocolate] = user, '${user.name} ${ageGroup(user)}')
			)
		);
		return t.toString();		
	}
	override function printEntries(entries:Array<{title:String, posted:Date, body:String}>):String {
		var t = Build.xml(
			html(xmlns="http://www.w3.org/1999/xhtml", lang="en",  "xml:lang"="en",
				head(
					title('BoBlog'),
					meta("http-equiv"="Content-Type", content="text/html; charset=utf-8"),
					link(rel="stylesheet", "href"="main.css", type="text/css")
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
		return t.toString();
	}
}