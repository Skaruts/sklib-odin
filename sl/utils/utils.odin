package utils

import "core:strings"
import rl "vendor:raylib"


@private __id: uint = 0
next_id :: proc() -> uint {
	__id += 1
	return __id
}


str_to_cstr :: proc(str:string) -> cstring {
	return strings.clone_to_cstring(str, context.temp_allocator)
}


@private _print2d_no_sep :: proc(array:$TA, w, h:int, callback:proc(item:$TB) -> bool) {
	_print2d(array, w, h, " ", callback)
}

@private _print2d :: proc(array:$TA, w, h:int, sep:=", ", callback:proc(item:$TB) -> bool) {
	for j in 0..<h {
		str := ""
		for i in 0..<w {
			v := callback(array[i+j*w]) ? "1" : "0"
			str = strings.concatenate({str, v, sep}, context.temp_allocator)
		}
		print(str)
	}
	print("---------------------------", '\n')
}

print2d :: proc {_print2d, _print2d_no_sep}



get_object_index_in_array_by_id :: proc(array:[]$TA id:uint) -> (value:int, ok:bool) #optional_ok {
	for item, i in array {
		if id == item._id do return i, true
	}
	return 0, false
}

