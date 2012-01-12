package tink.core.types;

/**
 * ...
 * @author back2dos
 */

enum Outcome<Data, Failure> {
	Success(data:Data);
	Failure(?failure:Failure);
}
interface ThrowableFailure {
	function throwSelf():Dynamic;
}
class OutcomeTools {
	static public function data < D, F > (outcome:Outcome < D, F > ):D {
		return
			switch (outcome) {
				case Success(data): 
					data;
				case Failure(failure): 
					if (Std.is(failure, ThrowableFailure)) {
						var failure:ThrowableFailure = cast failure;//TODO: simplify this once haXe cast work correctly again
						failure.throwSelf();
					}
					else
						throw Failure;
			}
	}
	static public inline function equals < D, F > (outcome:Outcome < D, F > , to: D):Bool {
		return 
			switch (outcome) {
				case Success(data): data == to;
				case Failure(failure): false;
			}
	}
	static public inline function map < A, B, F > (outcome: Outcome < A, F > , transform: A->B) {
		return 
			switch (outcome) {
				case Success(a): 
					asSuccess(transform(a));
				case Failure(f): 
					asFailure(f);
			}
	}
	static public inline function asSuccess < D, F > (data:D):Outcome < D, F > {
		return Outcome.Success(data);
	}
	static public inline function asFailure < D, F > (reason:F):Outcome < D, F > {
		return Outcome.Failure(reason);
	}
	static public inline function isSuccess< D, F > (outcome:Outcome < D, F > ):Bool {
		return Type.enumIndex(outcome) == 0;
	}
}