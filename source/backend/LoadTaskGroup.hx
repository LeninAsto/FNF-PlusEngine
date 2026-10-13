package backend;

import sys.thread.FixedThreadPool;
import sys.thread.Mutex;

/** Tracks queued AND running tasks; shutting down a pool alone does not join it. */
class LoadTaskGroup
{
	final pool:FixedThreadPool;
	final lock:Mutex = new Mutex();
	var pending:Int = 0;
	var cancelled:Bool = false;
	var closed:Bool = false;

	public function new(threads:Int)
	{
		pool = new FixedThreadPool(threads);
	}

	public function isIdle():Bool
	{
		lock.acquire();
		var idle = pending == 0;
		lock.release();
		return idle;
	}

	public function isCancelled():Bool
	{
		lock.acquire();
		var result = cancelled;
		lock.release();
		return result;
	}

	public function run(task:Void->Void):Bool
	{
		lock.acquire();
		if (closed)
		{
			lock.release();
			return false;
		}
		pending++;
		try
		{
			pool.run(() ->
			{
				try
				{
					if (!isCancelled())
						task();
				}
				catch (error:Dynamic)
				{
					trace('Loading task failed: $error');
				}
				// Last shared-state operation: idle means task bodies can no longer publish.
				lock.acquire();
				pending--;
				lock.release();
			});
		}
		catch (error:Dynamic)
		{
			pending--;
			lock.release();
			throw error;
		}
		lock.release();
		return true;
	}

	/** Running native work finishes cooperatively; queued task bodies are skipped. */
	public function cancel():Void
	{
		lock.acquire();
		cancelled = true;
		closeLocked();
		lock.release();
	}

	public function shutdown():Void
	{
		lock.acquire();
		closeLocked();
		lock.release();
	}

	function closeLocked():Void
	{
		if (!closed)
		{
			closed = true;
			pool.shutdown();
		}
	}
}
