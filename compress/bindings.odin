#+build darwin
package main

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:strings"

// macOS FSEvents bindings
foreign import FSEvents "system:CoreServices.framework"

FSEventStreamRef :: distinct rawptr
FSEventStreamEventId :: u64
FSEventStreamCreateFlags :: u32
CFStringRef :: distinct rawptr
CFArrayRef :: distinct rawptr
CFAllocatorRef :: distinct rawptr
CFRunLoopRef :: distinct rawptr
CFTimeInterval :: f64

// FSEvents flags
kFSEventStreamCreateFlagNone :: 0x00000000
kFSEventStreamCreateFlagUseCFTypes :: 0x00000001
kFSEventStreamCreateFlagNoDefer :: 0x00000002
kFSEventStreamCreateFlagWatchRoot :: 0x00000004
kFSEventStreamCreateFlagFileEvents :: 0x00000010

// FSEvents event flags
kFSEventStreamEventFlagItemCreated :: 0x00000100
kFSEventStreamEventFlagItemRemoved :: 0x00000200
kFSEventStreamEventFlagItemRenamed :: 0x00000800

kFSEventStreamEventIdSinceNow :: FSEventStreamEventId(max(u64))

// FSEventStreamContex structure
FSEventStreamContext :: struct {
	version:         c.long,
	info:            rawptr,
	retain:          rawptr,
	release:         rawptr,
	copyDescription: rawptr,
}

@(default_calling_convention = "c")
foreign FSEvents {
	FSEventStreamCreate :: proc(allocator: CFAllocatorRef, callcack: proc "c" (stream: FSEventStreamRef, clientCallBackInfo: rawptr, numEvents: c.size_t, eventPaths: rawptr, eventFlags: [^]u32, eventIds: [^]FSEventStreamEventId), ctx: ^FSEventStreamContext, pathsToWatch: CFArrayRef, sinceWhen: FSEventStreamEventId, latency: CFTimeInterval, flags: FSEventStreamCreateFlags) -> FSEventStreamRef ---

	FSEventStreamStart :: proc(stream: FSEventStreamRef) -> c.bool ---
	FSEventStreamStop :: proc(stream: FSEventStreamRef) ---
	FSEventStreamInvalidate :: proc(stream: FSEventStreamRef) ---
	FSEventStreamRelease :: proc(stream: FSEventStreamRef) ---
	FSEventStreamScheduleWithRunLoop :: proc(stream: FSEventStreamRef, runLoop: CFRunLoopRef, runLoopMode: CFStringRef) ---
}

// CoreFoundation bindings
foreign import CoreFoundation "system:CoreFoundation.framework"

@(default_calling_convention = "c")
foreign CoreFoundation {
	CFStringCreateWithCString :: proc(allocator: CFAllocatorRef, cStr: cstring, encoding: u32) -> CFStringRef ---
	CFArrayCreate :: proc(allocator: CFAllocatorRef, values: [^]rawptr, numValues: c.long, callbacks: rawptr) -> CFArrayRef ---
	CFRunLoopGetCurrent :: proc() -> CFRunLoopRef ---
	CFRunLoopRun :: proc() ---
	CFRunLoopStop :: proc(rl: CFRunLoopRef) ---
}

kCFStringEncodingUTF8 :: 0x08000100

// Helper to get default allocator
@(private)
cf_allocator_default :: proc() -> CFAllocatorRef {
	return CFAllocatorRef(nil)
}

// Create kCFRunLoopDefaultMode string
@(private)
get_default_run_loop_mode :: proc() -> CFStringRef {
	return CFStringCreateWithCString(
		cf_allocator_default(),
		"kCFRunLoopDefaultMode",
		kCFStringEncodingUTF8,
	)
}

WatcherContext :: struct {
	callback: proc(folder: string),
	folder:   string,
}

global_run_loop: CFRunLoopRef

//FSEvents callback
fs_event_callback :: proc "c" (
	stream: FSEventStreamRef,
	clientCallBackInfo: rawptr,
	numEvents: c.size_t,
	eventPaths: rawptr,
	eventFlags: [^]u32,
	eventIds: [^]FSEventStreamEventId,
) {
	ctx := cast(^WatcherContext)clientCallBackInfo
	if ctx == nil do return

	// paths:=([^][^]c.char)(eventPaths)
	for i in 0 ..< numEvents {
		flags := eventFlags[i]

		// Only trigger on file creation and ignore other like removal, rename, metadata changes..
		if flags & (kFSEventStreamEventFlagItemCreated) != 0 {
			context = runtime.default_context()
			ctx.callback(ctx.folder)
			break
		}
	}
}

// Start watching a folder for file additions
start_watching :: proc(folder: string, callback: proc(folder: string)) -> FSEventStreamRef {
	// Create watcher context
	watcher_ctx := new(WatcherContext)
	watcher_ctx.callback = callback
	watcher_ctx.folder = folder

	// CreateFSEventStreamContext on the heap so it persists
	stream_ctx := new(FSEventStreamContext)
	stream_ctx.version = 0
	stream_ctx.info = rawptr(watcher_ctx)
	stream_ctx.retain = nil
	stream_ctx.release = nil
	stream_ctx.copyDescription = nil

	// Convert folder path to CFString
	folder_cstr := strings.clone_to_cstring(folder, context.temp_allocator)
	cf_path := CFStringCreateWithCString(
		cf_allocator_default(),
		folder_cstr,
		kCFStringEncodingUTF8,
	)

	// Create new array with single path
	paths := [1]rawptr{rawptr(cf_path)}
	paths_array := CFArrayCreate(cf_allocator_default(), raw_data(paths[:]), 1, nil)

	// Create event stream with file-level events
	stream := FSEventStreamCreate(
		cf_allocator_default(),
		fs_event_callback,
		stream_ctx,
		paths_array,
		kFSEventStreamEventIdSinceNow,
		0.3, // latency in seconds 
		kFSEventStreamCreateFlagFileEvents,
	)

	// Schedule with run loop
	global_run_loop = CFRunLoopGetCurrent()
	run_loop_mode := get_default_run_loop_mode()
	FSEventStreamScheduleWithRunLoop(stream, global_run_loop, run_loop_mode)

	// Start the stream
	if !FSEventStreamStart(stream) {
		fmt.eprintln("Failed to start FSeventStream")
	}

	return stream
}

// Stop watching
stop_watching :: proc(stream: FSEventStreamRef) {
	FSEventStreamStop(stream)
	FSEventStreamInvalidate(stream)
	FSEventStreamRelease(stream)
	if global_run_loop != nil {
		CFRunLoopStop(global_run_loop)
	}
}
