package backend;

#if (target.threaded && sys)
import sys.thread.Thread;
import sys.thread.Mutex;
import sys.thread.Deque;
#end

/**
 * Thread pool utility for efficient async operations
 * Limits the number of concurrent threads and reuses them
 * 
 * Based on Codename Engine's approach but optimized for mobile/low-end devices
 */
class ThreadUtil
{
    #if (target.threaded && sys)
    /**
     * Maximum number of threads in the pool
     * Lower on mobile to save resources
     */
    public static var maxThreads:Int = #if android 2 #else 4 #end;
    
    /**
     * Active threads in the pool
     */
    private static var __threads:Array<Thread> = [];
    
    /**
     * Queue of pending functions to execute
     */
    private static var __pendingExecs:Deque<Void->Void> = new Deque();
    
    /**
     * Mutex for thread-safe operations
     */
    private static var __threadMutex:Mutex = new Mutex();
    
    /**
     * Number of threads currently executing tasks
     */
    private static var __threadUsed:Int = 0;
    
    /**
     * Whether the thread pool is initialized
     */
    private static var __initialized:Bool = false;
    
    /**
     * Initialize the thread pool
     * Called automatically on first use
     */
    public static function init():Void
    {
        if (__initialized) return;
        
        __threads = [];
        __pendingExecs = new Deque();
        __threadMutex = new Mutex();
        __threadUsed = 0;
        __initialized = true;
    }
    
    /**
     * Execute a function asynchronously using the thread pool
     * Automatically manages thread creation and reuse
     * 
     * @param func The function to execute
     */
    public static function execAsync(func:Void->Void):Void
    {
        if (func == null) return;
        
        if (!__initialized) init();
        
        __pendingExecs.add(func);
        
        if (__threadUsed >= __threads.length)
        {
            // Need to create a new thread
            if (__threads.length >= maxThreads)
            {
                // Pool is full, task will wait in queue
                return;
            }
            
            __threadMutex.acquire();
            try
            {
                var thread = Thread.create(__threadWorker);
                __threads.push(thread);
                trace('[ThreadUtil] Created new thread (${__threads.length}/$maxThreads)');
            }
            catch (e)
            {
                trace('[ThreadUtil] ERROR creating thread: ${e}');
            }
            __threadMutex.release();
        }
    }
    
    /**
     * Worker function that processes tasks from the queue
     * Runs in a separate thread
     */
    private static function __threadWorker():Void
    {
        var callback:Void->Void;
        
        while ((callback = __pendingExecs.pop(true)) != null)
        {
            __threadMutex.acquire();
            __threadUsed++;
            __threadMutex.release();
            
            try
            {
                callback();
            }
            catch (e)
            {
                trace('[ThreadUtil] ERROR executing task: ${e}');
            }
            
            __threadMutex.acquire();
            __threadUsed--;
            __threadMutex.release();
        }
        
        // Thread finished all tasks, remove from pool
        __threadMutex.acquire();
        __threads.remove(Thread.current());
        trace('[ThreadUtil] Thread terminated (${__threads.length}/$maxThreads remaining)');
        __threadMutex.release();
    }
    
    /**
     * Get the number of active threads
     */
    public static function getActiveThreads():Int
    {
        return __threadUsed;
    }
    
    /**
     * Get the number of threads in the pool
     */
    public static function getPoolSize():Int
    {
        return __threads.length;
    }
    
    /**
     * Get the number of pending tasks
     */
    public static function getPendingTasks():Int
    {
        var count = 0;
        var temp = __pendingExecs.pop(false);
        while (temp != null)
        {
            count++;
            __pendingExecs.add(temp);
            temp = __pendingExecs.pop(false);
        }
        return count;
    }
    
    /**
     * Adjust max threads based on device tier
     * Call this after detecting device capabilities
     */
    public static function setMaxThreads(count:Int):Void
    {
        if (count < 1) count = 1;
        if (count > 8) count = 8; // Reasonable limit
        
        maxThreads = count;
        trace('[ThreadUtil] Max threads set to: $maxThreads');
    }
    
    /**
     * Shutdown the thread pool gracefully
     * Call this before app exit
     */
    public static function shutdown():Void
    {
        if (!__initialized) return;
        
        trace('[ThreadUtil] Shutting down thread pool...');
        
        // Add poison pills to stop all threads
        for (i in 0...__threads.length)
        {
            __pendingExecs.add(null);
        }
        
        __initialized = false;
        trace('[ThreadUtil] Thread pool shut down');
    }
    
    #else
    
    // Fallback for non-threaded targets - just execute immediately
    public static function init():Void {}
    
    public static function execAsync(func:Void->Void):Void
    {
        if (func != null) func();
    }
    
    public static function getActiveThreads():Int return 0;
    public static function getPoolSize():Int return 0;
    public static function getPendingTasks():Int return 0;
    public static function setMaxThreads(count:Int):Void {}
    public static function shutdown():Void {}
    
    #end
}
