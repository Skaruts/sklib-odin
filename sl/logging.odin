package sl

import "core:fmt"
import "core:strings"
import "core:slice"
import "core:path/filepath"



@private LogType :: enum uint {
	Print,  // regular print statements, but through the logger, with location info
	Printf,
	Info,
	Task,
	Reminder,
	Deprecated,
	Warning,
	Error,
}


@private Logger :: struct {
	prefix         : string,
	send_to_file   : bool, // N/A yet
	send_to_stdout : bool,
	include_locations : bool,
	brackets:[2]string,

	// TODO make this a bitfield
	log_prints      : bool,
	log_infos       : bool,
	log_tasks       : bool,
	log_reminders   : bool,
	log_deprecateds : bool,
	log_warnings    : bool,
	log_errors      : bool,

	prints         : [dynamic]string,
	infos          : [dynamic]string,
	tasks          : [dynamic]string,
	reminders      : [dynamic]string,
	deprecateds    : [dynamic]string,
	warnings       : [dynamic]string,
	errors      : [dynamic]string,
}


@private _loggers : [dynamic]^Logger
@private _user_logger : ^Logger


/*******************************************************************************
		logging start / end
*/
@private _init_logging :: proc() {
	_user_logger = _logger_new()
	_internal.logger = _logger_new("SL_", {"{", "}"})
}

@private _destroy_logging :: proc() {
	for len(_loggers) > 0 {
		_logger_destroy(_loggers[0])
	}
	delete(_loggers)
}



/*******************************************************************************
		logger init / detroy
*/
@private _logger_new :: proc (prefix:="", brackets:[2]string={"[", "]"}) -> ^Logger {
	logger := new(Logger)

	logger.prefix            = prefix
	logger.send_to_stdout    = true
	logger.send_to_file      = false // N/A yet
	logger.include_locations = false
	logger.brackets          = brackets

	logger.log_prints        = true
	logger.log_infos         = true
	logger.log_tasks         = true
	logger.log_reminders     = true
	logger.log_deprecateds   = true
	logger.log_warnings      = true
	logger.log_errors     = true

	append(&_loggers, logger)
	return logger
}

@private _logger_destroy :: proc(logger:^Logger) {
	delete(logger.prints)
	delete(logger.infos)
	delete(logger.tasks)
	delete(logger.reminders)
	delete(logger.deprecateds)
	delete(logger.warnings)
	delete(logger.errors)

	idx, _ := slice.linear_search(_loggers[:], logger)
	unordered_remove(&_loggers, idx)

	free(logger)
}



/*******************************************************************************
		prefix
*/
@private _logger_set_prefix_impl :: proc(logger: ^Logger, prefix: string) {
	logger.prefix = prefix
}

@private _logger_set_prefix_nl :: proc(prefix: string) {
	_logger_set_prefix_impl(_user_logger, prefix)
}

@private _logger_set_prefix :: proc { _logger_set_prefix_impl, _logger_set_prefix_nl }



/*******************************************************************************
		message printing
*/
@private _build_prefix :: proc(logger:^Logger, type:LogType, loc := #caller_location) -> string {
	loc_str := ""
	if logger.include_locations || type == LogType.Print || type == LogType.Printf {
		loc_str = fmt.tprintf("%s(%d)", filepath.base(loc.file_path), loc.line)
	}
	b1 := logger.brackets[0]
	b2 := logger.brackets[1]
	p := logger.prefix
	switch type {
		case LogType.Print:      return strings.concatenate({loc_str, ": "}, context.temp_allocator)
		case LogType.Printf:     return strings.concatenate({loc_str, ": "}, context.temp_allocator)
		case LogType.Info:       return strings.concatenate({"    ", b1, p, "INFO",       b2, " ", loc_str}, context.temp_allocator)
		case LogType.Task:       return strings.concatenate({"  > ", b1, p, "TASK",       b2, " ", loc_str}, context.temp_allocator)
		case LogType.Reminder:   return strings.concatenate({"  * ", b1, p, "REMINDER",   b2, " ", loc_str}, context.temp_allocator)
		case LogType.Deprecated: return strings.concatenate({"    ", b1, p, "DEPRECATED", b2, " ", loc_str}, context.temp_allocator)
		case LogType.Warning:    return strings.concatenate({" ** ", b1, p, "WARNING",    b2, " ", loc_str}, context.temp_allocator)
		case LogType.Error:      return strings.concatenate({" ## ", b1, p, "ERROR",      b2, " ", loc_str}, context.temp_allocator)
	}
	return ""
}

@private _log_message :: proc(logger:^Logger, type:LogType, msg:string, args: ..any, loc := #caller_location) {
	// fmt.println("len(args): ", len(args))
	usr_str  := len(args) > 0 ? fmt.tprintf(msg, ..args) : msg
	prefix   := _build_prefix(logger, type, loc)
	full_str := strings.concatenate({prefix, usr_str}, context.temp_allocator)

	array: ^[dynamic]string

	switch type {
		case LogType.Print:      array = &logger.prints
		case LogType.Printf:     array = &logger.prints
		case LogType.Info:       array = &logger.infos
		case LogType.Task:       array = &logger.tasks
		case LogType.Reminder:   array = &logger.reminders
		case LogType.Deprecated: array = &logger.deprecateds
		case LogType.Warning:    array = &logger.warnings
		case LogType.Error:      array = &logger.errors
	}
	append(array, full_str)
	if logger.send_to_stdout do fmt.println(full_str)
}



/*******************************************************************************
		log_print

	Like println, but with filename and line number prefixed
*/
@private _logger_print_impl :: proc(logger:^Logger, args: ..any, loc := #caller_location) {
	if !logger.log_prints do return
	msg := fmt.tprint(..args)
	_log_message(logger=logger, type=LogType.Print, msg=msg, args={}, loc=loc)
}

@private _logger_print_nl :: proc(args: ..any, loc := #caller_location) {
	_logger_print_impl(logger=_user_logger, args=args, loc=loc)
}

@private _logger_print :: proc {_logger_print_impl, _logger_print_nl}



/*******************************************************************************
		log_printf
*/
@private _logger_printf_impl :: proc(logger:^Logger, msg:string, args: ..any, loc := #caller_location) {
	if !logger.log_prints do return
	_log_message(logger=logger, type=LogType.Printf, msg=msg, args=args, loc=loc)
}

@private _logger_printf_nl :: proc(msg:string, args: ..any, loc := #caller_location) {
	_logger_printf_impl(logger=_user_logger, msg=msg, args=args, loc=loc)
}

@private _logger_printf :: proc { _logger_printf_impl, _logger_printf_nl }



/*******************************************************************************
		log_info
*/
@private _logger_info_impl :: proc(logger:^Logger, msg:string, args: ..any, loc := #caller_location) {
	if !logger.log_infos do return
	_log_message(logger=logger, type=LogType.Info, msg=msg, args=args, loc=loc)
}

@private _logger_info_nl :: proc(msg:string, args: ..any, loc := #caller_location) {
	_logger_info_impl(logger=_user_logger, msg=msg, args=args, loc=loc)
}

@private _logger_info :: proc { _logger_info_impl, _logger_info_nl }



/*******************************************************************************
		log_task
*/
@private _logger_task_impl :: proc(logger:^Logger, msg:string, args: ..any, loc := #caller_location) {
	if !logger.log_tasks do return
	_log_message(logger=logger, type=LogType.Task, msg=msg, args=args, loc=loc)
}

@private _logger_task_nl :: proc(msg:string, args: ..any, loc := #caller_location) {
	_logger_task_impl(logger=_user_logger, msg=msg, args=args, loc=loc)
}

@private _logger_task :: proc { _logger_task_impl, _logger_task_nl }



/*******************************************************************************
		log_reminder
*/
@private _logger_reminder_impl :: proc(logger:^Logger, msg:string, args: ..any, loc := #caller_location) {
	if !logger.log_reminders do return
	_log_message(logger=logger, type=LogType.Reminder, msg=msg, args=args, loc=loc)
}

@private _logger_reminder_nl :: proc(msg:string, args: ..any, loc := #caller_location) {
	_logger_reminder_impl(logger=_user_logger, msg=msg, args=args, loc=loc)
}

@private _logger_reminder :: proc { _logger_reminder_impl, _logger_reminder_nl }



/*******************************************************************************
		log_deprecated
*/
@private _logger_deprecated_impl :: proc(logger:^Logger, msg:string, args: ..any, loc := #caller_location) {
	if !logger.log_deprecateds do return
	_log_message(logger=logger, type=LogType.Deprecated, msg=msg, args=args, loc=loc)
}

@private _logger_deprecated_nl :: proc(msg:string, args: ..any, loc := #caller_location) {
	_logger_deprecated_impl(logger=_user_logger, msg=msg, args=args, loc=loc)
}

@private _logger_deprecated :: proc { _logger_deprecated_impl, _logger_deprecated_nl }



/*******************************************************************************
		log_warning
*/
@private _logger_warning_impl :: proc(logger:^Logger, msg:string, args: ..any, loc := #caller_location) {
	if !logger.log_warnings do return
	_log_message(logger=logger, type=LogType.Warning, msg=msg, args=args, loc=loc)
}

@private _logger_warning_nl :: proc(msg:string, args: ..any, loc := #caller_location) {
	_logger_warning_impl(logger=_user_logger, msg=msg, args=args, loc=loc)
}

@private _logger_warning :: proc { _logger_warning_impl, _logger_warning_nl }



/*******************************************************************************
		log_error
*/
@private _logger_error_impl :: proc(logger:^Logger, msg:string, args: ..any, loc := #caller_location) {
	if !logger.log_errors do return
	_log_message(logger=logger, type=LogType.Error, msg=msg, args=args, loc=loc)
}

@private _logger_error_nl :: proc(msg:string, args: ..any, loc := #caller_location) {
	_logger_error_impl(logger=_user_logger, msg=msg, args=args, loc=loc)
}

@private _logger_error :: proc { _logger_error_impl, _logger_error_nl }




/*******************************************************************************
	Procs that automatically use the internal logger, for intenal usage only.
*/
@private __PRINT      :: proc(args: ..any, loc := #caller_location) { _logger_print_impl(logger=_internal.logger, args=args, loc=loc) }
@private __PRINTF     :: proc(msg:string, args: ..any, loc := #caller_location) { _logger_printf_impl(logger=_internal.logger, msg=msg, args=args, loc=loc) }
@private __INFO       :: proc(msg:string, args: ..any, loc := #caller_location) { _logger_info_impl(logger=_internal.logger, msg=msg, args=args, loc=loc) }
@private __TASK       :: proc(msg:string, args: ..any, loc := #caller_location) { _logger_task_impl(logger=_internal.logger, msg=msg, args=args, loc=loc) }
@private __REMINDER   :: proc(msg:string, args: ..any, loc := #caller_location) { _logger_reminder_impl(logger=_internal.logger, msg=msg, args=args, loc=loc) }
@private __DEPRECATED :: proc(msg:string, args: ..any, loc := #caller_location) { _logger_deprecated_impl(logger=_internal.logger, msg=msg, args=args, loc=loc) }
@private __WARNING    :: proc(msg:string, args: ..any, loc := #caller_location) { _logger_warning_impl(logger=_internal.logger, msg=msg, args=args, loc=loc) }
@private __ERROR      :: proc(msg:string, args: ..any, loc := #caller_location) { _logger_error_impl(logger=_internal.logger, msg=msg, args=args, loc=loc) }

