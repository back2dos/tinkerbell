package tink.core.types;

enum Outcome<Data, Failure> {
	Success(data:Data);
	Failure(failure:Failure);
}
interface ThrowableFailure {
	function throwSelf():Dynamic;
}
class OutcomeTools {
	static public function sure < D, F > (outcome:Outcome < D, F > ):D {
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
						throw failure;
			}
	}
	static public function toOption < D, F > (outcome:Outcome < D, F > ) {
		return 
			switch (outcome) {
				case Success(data): Option.Some(data);
				case Failure(_): Option.None;
			}
	}
	static public function toOutcome<D>(option:Option<D>, ?pos:haxe.PosInfos) {
		return
			switch (option) {
				case Some(value): 
					Success(value);
				case None: 
					Failure('Some value expected but none found in ' + pos.fileName + '@line ' + pos.lineNumber);
			}
	}
	static public inline function orUse < D, F > (outcome: Outcome < D, F > , fallback: D ) {
		return
			switch (outcome) {
				case Success(data): data;
				case Failure(_): fallback;
			}		
	}
	static public inline function orTry < D, F > (outcome: Outcome < D, F > , fallback: Outcome < D, F > ) {
		return
			switch (outcome) {
				case Success(_): outcome;
				case Failure(_): fallback;
			}
	}
	static public inline function equals < D, F > (outcome:Outcome < D, F > , to: D):Bool {
		return 
			switch (outcome) {
				case Success(data): data == to;
				case Failure(_): false;
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